component output=false {
    public any function init(required any source, numeric ttlSeconds=300, numeric retrySeconds=60, struct initialPayload={}) {
        variables.source=arguments.source;
        variables.ttl=max(1,arguments.ttlSeconds);
        variables.retry=max(1,arguments.retrySeconds);
        variables.lockName='RunnerAppsMenu-' & createUUID();
        variables.snapshot=duplicate(arguments.initialPayload);
        variables.expiresAt=now();
        variables.retryAt=now();
        variables.refreshing=false;
        variables.referenceKey='__runnerAppsRefresh' & replace(createUUID(),'-','','all');
        return this;
    }

    // This lock protects only memory. Network I/O always runs outside the request.
    public struct function get() {
        var result={};
        var launch=false;
        lock name=variables.lockName type='exclusive' timeout=1 {
            result=duplicate(variables.snapshot);
            if (!variables.refreshing && now() GTE variables.expiresAt && now() GTE variables.retryAt) {
                variables.refreshing=true;
                launch=true;
            }
        }
        if (launch) {
            try {
                // Passing a CFC as a thread attribute copies it. Resolve the original
                // instance from APPLICATION so the completed refresh is visible.
                APPLICATION[variables.referenceKey]=this;
                thread name=('RunnerAppsRefresh' & replace(createUUID(),'-','','all')) cacheKey=variables.referenceKey {
                    try { APPLICATION[attributes.cacheKey].refresh(); }
                    finally { structDelete(APPLICATION,attributes.cacheKey); }
                }
            } catch (any launchError) {
                structDelete(APPLICATION,variables.referenceKey);
                failed();
            }
        }
        return result;
    }

    // Called by the refresh thread; the loader never depends on REQUEST or URL.
    public void function refresh() {
        try {
            var payload=variables.source.fetch();
            if (!validPayload(payload)) throw(type='RunnerApps.InvalidPayload',message='Invalid runner apps catalog');
            lock name=variables.lockName type='exclusive' timeout=1 {
                variables.snapshot=duplicate(payload);
                variables.expiresAt=dateAdd('s',variables.ttl,now());
                variables.retryAt=variables.expiresAt;
                variables.refreshing=false;
            }
        } catch (any refreshError) {
            failed();
        }
    }

    private void function failed() {
        lock name=variables.lockName type='exclusive' timeout=1 {
            variables.retryAt=dateAdd('s',variables.retry,now());
            variables.refreshing=false;
        }
    }

    private boolean function validPayload(required any payload) {
        if (!isStruct(arguments.payload) || !structKeyExists(arguments.payload,'success')
            || !isBoolean(arguments.payload.success) || !arguments.payload.success
            || !structKeyExists(arguments.payload,'groups') || !isArray(arguments.payload.groups)
            || !structKeyExists(arguments.payload,'items') || !isArray(arguments.payload.items)) return false;
        for (var item in arguments.payload.items) {
            if (!validItem(item)) return false;
        }
        for (var group in arguments.payload.groups) {
            if (!isStruct(group) || !structKeyExists(group,'items') || !isArray(group.items)) return false;
            for (var item in group.items) {
                if (!validItem(item)) return false;
            }
        }
        return true;
    }

    private boolean function validItem(required any item) {
        if (!isStruct(arguments.item)) return false;
        for (var field in ['href','label','labelHtml','name','imgSrc','imgAlt','target','rel']) {
            if (structKeyExists(arguments.item,field) && !isSimpleValue(arguments.item[field])) return false;
        }
        return structKeyExists(arguments.item,'href');
    }
}
