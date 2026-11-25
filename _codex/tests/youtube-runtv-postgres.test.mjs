import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';
import {PGlite} from '@electric-sql/pglite';

const rr = new URL('../../../RoadRunners/', import.meta.url);
const read = (file) => fs.readFileSync(new URL(file, rr), 'utf8');

test('the exact migration preserves existing videos and both readers convert the scheduled instant to Brasília', async (t) => {
    const db = new PGlite();
    t.after(() => db.close());
    await db.exec(`
        CREATE TABLE public.tb_media (id_media serial PRIMARY KEY, data_publicacao timestamp NOT NULL);
        INSERT INTO public.tb_media (data_publicacao) VALUES (timestamp '2026-11-17 18:45');
    `);
    const readers = ['includes/backend/backend_evento.cfm', 'includes/backend/backend_video_destaque.cfm'].map((file) => {
        const [, expression] = read(file).match(/^\s*(\(to_jsonb\(media\)->>[^\n]+ AS scheduled_start_at),?$/m);
        return `SELECT to_char(scheduled_start_at,'YYYY-MM-DD HH24:MI') AS local_time,
                       to_char(data_publicacao,'YYYY-MM-DD HH24:MI') AS publication
                FROM (SELECT data_publicacao, ${expression} FROM public.tb_media media) dates`;
    });
    const before = {local_time: null, publication: '2026-11-17 18:45'};
    for (const query of readers) assert.deepEqual((await db.query(query)).rows, [before]);
    const migration = read('_codex/sql/migrations/2026-11-19_runtv_scheduled_start.sql');
    await db.exec(migration);
    await db.exec(migration);
    await db.query('UPDATE public.tb_media SET youtube_scheduled_start_at = $1::timestamptz', ['2026-11-22T09:15:00Z']);
    const scheduled = {...before, local_time: '2026-11-22 06:15'};
    for (const query of readers) assert.deepEqual((await db.query(query)).rows, [scheduled]);
});
