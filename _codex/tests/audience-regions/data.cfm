<cfscript>
VARIABLES.audienceRegionOccupancyStatus = "ready";
VARIABLES.audienceRegionOccupancyQuery = queryNew("audience_uf,format,registered,potential,filled,empty,unclassified","varchar,varchar,integer,integer,integer,integer,integer");
// Literal, hand-calculated opportunities. Regional rows deliberately overlap globally.
fixtureRegionRows = [
    ["SC","all",120,100,60,30,10],["SC","ads",80,70,50,15,5],["SC","banners",30,20,10,8,2],["SC","other",10,10,0,7,3],
    ["SP","all",170,160,110,40,10],["SP","ads",120,120,100,15,5],["SP","banners",40,30,10,20,0],["SP","other",10,10,0,5,5],
    ["--","all",40,40,10,20,10],["--","ads",40,40,10,20,10],["--","banners",0,0,0,0,0],["--","other",0,0,0,0,0],
    ["AC","all",5,0,0,0,0],["AC","ads",5,0,0,0,0],["AC","banners",0,0,0,0,0],["AC","other",0,0,0,0,0]
];
for (fixtureRegion in fixtureRegionRows) queryAddRow(VARIABLES.audienceRegionOccupancyQuery, {
    "audience_uf"=fixtureRegion[1],"format"=fixtureRegion[2],"registered"=fixtureRegion[3],
    "potential"=fixtureRegion[4],"filled"=fixtureRegion[5],"empty"=fixtureRegion[6],"unclassified"=fixtureRegion[7]
});
VARIABLES.audienceCoveragePathsStatus = "ready";
VARIABLES.audienceCoveragePathsQuery = queryNew("page_folder,pageviews,pages_with_slots,opportunities,slot_views,last_received","varchar,integer,integer,integer,integer,timestamp");
queryAddRow(VARIABLES.audienceCoveragePathsQuery,{"page_folder"="/corridas","pageviews"=17,"pages_with_slots"=12,"opportunities"=24,"slot_views"=9,"last_received"=createDateTime(2026,9,13,12,0,0)});
queryAddRow(VARIABLES.audienceCoveragePathsQuery,{"page_folder"="/perfil<&\""","pageviews"=3,"pages_with_slots"=2,"opportunities"=4,"slot_views"=1,"last_received"=""});
queryAddRow(VARIABLES.audienceCoveragePathsQuery,{"page_folder"="","pageviews"=2,"pages_with_slots"=0,"opportunities"=0,"slot_views"=0,"last_received"=""});
</cfscript>
