--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0045-pgvector.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0350-pgvector splitStatements:false
-- Có pgvector: đổi embedding sang vector(1024) và dựng chỉ mục HNSW theo cosine (ADR-170, NFR-17-025). Không có (CI): giữ real[].
DO $vec$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
    EXECUTE 'ALTER TABLE ph17_assist.knowledge_chunk ALTER COLUMN embedding TYPE vector(1024) USING embedding::vector(1024)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS ix_knowledge_chunk_embedding ON ph17_assist.knowledge_chunk USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)';
  ELSE
    RAISE NOTICE 'Không có pgvector: embedding giữ real[] (chỉ để CI, ADR-170).';
  END IF;
END
$vec$;
--rollback empty
