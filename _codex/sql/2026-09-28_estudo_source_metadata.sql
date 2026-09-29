-- Record CRLF -> LF normalization separately from the original file-byte hash.
-- Does not change source SQL text; all previous revisions stay immutable.
SET LOCAL lock_timeout='3s';
DO $metadata$
DECLARE rec record; cell record; note_record record;
BEGIN
 FOR rec IN SELECT * FROM (VALUES ('dba-202509-estudo_treinos.sql.txt','6b0b1a3a6e7c24fa389b97a2b7e156ce462fe29e714bc6b08d818bdad40d1857','76bf29784ac3cb15d21d14f1be926b69b95931f01ce2d01b1bb72ac35804dcea'),('dba-202509-regiao_capital_interior.sql.txt','9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0','7a6f0a28a751cb47d4a8b4c87be429117bf7c9c0e895f065228978dee380860d'),('dba-202509-script_perfil_2025_segundo_semestre.txt.txt','52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364','c5fb5d5b38f79e20cde40760d91942da0b3ee06d2ba6170bfe90dd293c3ade3f'),('dba-202509-script_perfil_br_corre_2025.sql.txt','766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117','675652db70f6bbe27ce5559780bd1f807b9fa012ed6001b5c6536c95ee605f57')) AS v(source_prefix,file_sha,text_sha)
 LOOP
  SELECT * INTO STRICT cell FROM estudo.notebook_cells WHERE source_key=rec.source_prefix||'-cell-2' FOR UPDATE;
  IF encode(sha256(convert_to(cell.content,'UTF8')),'hex')<>rec.text_sha OR cell.origem->>'sha256_copia'<>rec.file_sha THEN
   RAISE EXCEPTION 'Fonte mudou; interromper ajuste de metadados';
  END IF;
  IF cell.origem->>'sha256_texto_importado' IS NULL THEN
   IF cell.version<>1 THEN RAISE EXCEPTION 'Fonte editada; revisar metadados manualmente'; END IF;
   SELECT * INTO STRICT note_record FROM estudo.notebook_cells WHERE source_key=rec.source_prefix||'-cell-1' FOR UPDATE;
   IF note_record.version<>1 THEN RAISE EXCEPTION 'Nota editada; revisar metadados manualmente'; END IF;
   UPDATE estudo.notebook_cells SET origem=origem||jsonb_build_object('sha256_texto_importado',rec.text_sha,'normalizacao','Finais de linha CRLF convertidos para LF na importacao; conteudo SQL preservado.'),updated_by=NULL WHERE id=cell.id;
   UPDATE estudo.notebook_cells SET content=content||E'\n\nNormalização na importação: finais de linha CRLF convertidos para LF. O hash acima é o do arquivo; o texto no editor tem SHA-256: '||rec.text_sha,
    origem=origem||jsonb_build_object('sha256_texto_importado',rec.text_sha,'normalizacao','CRLF para LF'),updated_by=NULL WHERE id=note_record.id;
  END IF;
 END LOOP;
END;
$metadata$;
