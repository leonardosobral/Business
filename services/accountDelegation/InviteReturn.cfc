component output=false {
    public boolean function capture(required struct state,required any token) {
        if(!isSimpleValue(token) || !reFind('^[a-f0-9]{64}$',token & '')) {clear(state);return false;}
        state.invitePendingToken=token & '';
        state.invitePendingReturn='/convites/';
        return true;
    }
    public string function pendingToken(required struct state) {
        if(!structKeyExists(state,'invitePendingToken') || !isSimpleValue(state.invitePendingToken)
            || !reFind('^[a-f0-9]{64}$',state.invitePendingToken & '')) return '';
        return state.invitePendingToken & '';
    }
    public string function consumeRedirect(required struct state) {
        var safe=structKeyExists(state,'invitePendingReturn') && isSimpleValue(state.invitePendingReturn)
            && compare(state.invitePendingReturn & '','/convites/')==0 && len(pendingToken(state));
        structDelete(state,'invitePendingReturn',false);
        return safe?'/convites/':'';
    }
    public void function clear(required struct state) {
        structDelete(state,'invitePendingToken',false);
        structDelete(state,'invitePendingReturn',false);
    }
}
