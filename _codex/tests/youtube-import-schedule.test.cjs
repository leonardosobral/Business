const fs = require('node:fs');
const assert = require('node:assert/strict');
const test = require('node:test');
const importer = fs.readFileSync(require('node:path').resolve(__dirname, '../../api/youtube/jobs/import.cfm'), 'utf8');

test('the existing batch request supplies live metadata and publishes the schedule in both write paths', () => {
    assert.match(importer, /name="part" value="contentDetails,liveStreamingDetails"/);
    assert.match(importer, /fromYoutubeItem\(item\)/);
    assert.match(importer, /UPDATE tb_media[\s\S]*?youtube_scheduled_start_at = CAST\(<cfqueryparam[^>]*> AS timestamptz\)/);
    assert.match(importer, /INSERT INTO tb_media\s+\([^)]*youtube_scheduled_start_at[^)]*\)/);
});

test('curated refresh is authenticated, bounded, reuses the batch, and never writes in dry run', () => {
    assert.ok(importer.indexOf('<cfif NOT VARIABLES.hasValidJobToken>') < importer.indexOf('refreshCuratedYoutubeSchedules() />'));
    const refresh = importer.slice(importer.indexOf('<cffunction name="refreshCuratedYoutubeSchedules"'), importer.indexOf('<cffunction name="resolveChannelUploadsPlaylist"'));
    assert.match(refresh, /is_featured[\s\S]*id_evento[\s\S]*LIMIT 50/);
    assert.match(refresh, /fetchVideoDetailsBatch\(/);
    assert.match(refresh, /NOT schedule\.authoritative[\s\S]*NOT VARIABLES\.dryRun[\s\S]*UPDATE public\.tb_media[\s\S]*youtube_scheduled_start_at/);
    assert.match(importer, /<cfif NOT VARIABLES\.schedulesOnly>[\s\S]*processChannel\(/);
});
