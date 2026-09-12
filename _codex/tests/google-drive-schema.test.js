const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('Drive migration is repeatable and enforces one valid root', async () => {
    const {PGlite} = await import(require.resolve('@electric-sql/pglite'));
    const db = new PGlite();
    try {
        await db.exec('CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY)');
        const sql = fs.readFileSync(path.resolve(__dirname, '../../administracao/drive/drive_schema.sql'), 'utf8');
        await db.exec(sql);
        await db.exec(sql);
        await db.exec("INSERT INTO public.tb_usuarios(id) VALUES (7)");
        await db.exec("INSERT INTO public.tb_google_drive_config(id,root_folder_id,root_folder_name,criado_por) VALUES (1,'folder_ABC-123','RunnerHub Business',7)");
        await assert.rejects(db.exec("INSERT INTO public.tb_google_drive_config(id,root_folder_id,root_folder_name) VALUES (2,'other','Other')"));
        await assert.rejects(db.exec("UPDATE public.tb_google_drive_config SET root_folder_id='../outside' WHERE id=1"));
        await db.exec("INSERT INTO public.tb_google_drive_auditoria(id_usuario,acao,file_id,nome,estado) VALUES (7,'upload','file_1','regulamento.pdf','success')");
        const audit = await db.query("SELECT acao,estado FROM public.tb_google_drive_auditoria");
        assert.equal(audit.rows[0].acao, 'upload');
        assert.equal(audit.rows[0].estado, 'success');
    } finally { await db.close(); }
});
