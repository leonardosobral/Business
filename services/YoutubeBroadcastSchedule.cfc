component output=false {
    public struct function fromYoutubeItem(required struct item) output=false {
        var schedule = {authoritative=false, utc=""};
        if (!structKeyExists(arguments.item, "contentDetails") || !isStruct(arguments.item.contentDetails)) {
            return schedule;
        }

        // The videos.list batch requested liveStreamingDetails; ordinary videos omit it.
        if (!structKeyExists(arguments.item, "liveStreamingDetails")) {
            schedule.authoritative = true;
            return schedule;
        }
        var live = arguments.item.liveStreamingDetails;
        if (!isStruct(live) || !structKeyExists(live, "scheduledStartTime") || !isSimpleValue(live.scheduledStartTime)) {
            return schedule;
        }

        try {
            schedule.utc = createObject("java", "java.time.OffsetDateTime").parse(javaCast("string", trim(live.scheduledStartTime))).toInstant().toString();
            schedule.authoritative = true;
        } catch (any invalidTimestamp) {
            // Missing or malformed live metadata must not erase a previously confirmed time.
        }
        return schedule;
    }
}
