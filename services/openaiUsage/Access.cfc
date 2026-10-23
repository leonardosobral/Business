component output=false {
    private boolean function truth(required any value){return isSimpleValue(value) AND listFindNoCase("true,1,t,yes,sim",trim(value & "")) GT 0;}
    public boolean function allowed(required any isAdmin,required any effectiveAdmin,required boolean delegated){return truth(isAdmin) AND truth(effectiveAdmin) AND !delegated;}
}
