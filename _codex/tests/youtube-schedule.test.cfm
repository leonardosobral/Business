<cfscript>
scheduleService = new services.YoutubeBroadcastSchedule();
cases = [
    {input={id="example", contentDetails={duration="P0D"}, liveStreamingDetails={scheduledStartTime="2026-11-22T06:15:00-03:00"}}, authoritative=true, utc="2026-11-22T09:15:00Z"},
    {input={id="example", contentDetails={duration="P0D"}, liveStreamingDetails={scheduledStartTime="2026-11-22T10:00:00Z",actualStartTime="2026-11-22T10:25:00Z"}}, authoritative=true, utc="2026-11-22T10:00:00Z"},
    {input={id="example", contentDetails={duration="PT10M"}, snippet={publishedAt="2026-11-17T14:00:00Z"}}, authoritative=true, utc=""},
    {input={id="example", contentDetails={duration="P0D"}, liveStreamingDetails={scheduledStartTime="2026-11-22T06:15:00"}}, authoritative=false, utc=""},
    {input={id="example", contentDetails={duration="P0D"}, liveStreamingDetails={actualStartTime="2026-11-22T10:25:00Z"}}, authoritative=false, utc=""},
    {input={id="example"}, authoritative=false, utc=""}
];
for (item in cases) {
    extracted = scheduleService.fromYoutubeItem(item.input);
    if (extracted.authoritative NEQ item.authoritative OR compare(extracted.utc, item.utc) NEQ 0) {
        throw(type="YouTube.Schedule.Test",message="Unexpected schedule; expected " & serializeJSON({authoritative=item.authoritative, utc=item.utc}));
    }
}
writeOutput("RUNTV_SCHEDULE_PASS " & arrayLen(cases));
</cfscript>
