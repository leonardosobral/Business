component extends="services.VerifiedAdmin" output=false {
    this.calls=[];
    this.failProfile=0;
    public void function classify(required numeric profileId,required string category,required string reason,required numeric actorId,required numeric revision) {
        if(arguments.profileId==this.failProfile)throw(type="VerifiedAdmin.Conflict",message="Stale revision");
        arrayAppend(this.calls,duplicate(arguments));
    }
}
