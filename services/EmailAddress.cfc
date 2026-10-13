component output=false {
    public boolean function isValidAddress(required any address) {
        if (!isSimpleValue(arguments.address) || !len(arguments.address) || len(arguments.address)>254 || reFind("[\x00-\x20\x7f]",arguments.address)) return false;
        if (isValid("email",arguments.address)) return true;
        // ColdFusion's legacy validator rejects long TLDs such as .business.
        // The fallback accepts only ASCII dot-atoms and DNS labels with a long TLD.
        if (!reFindNoCase("^[^@]+@(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{7,63}$",arguments.address)) return false;
        var localPart=listFirst(arguments.address,"@");
        if (len(localPart)>64 || left(localPart,1)=="." || right(localPart,1)=="." || find("..",localPart)) return false;
        return reFind("^[A-Za-z0-9.!##$%&'*+/=?^_`{|}~-]+$",localPart)>0;
    }
}
