-- Runs EXACTLY ONCE, on the first start, while PGDATA is still empty.
-- Executed by the entrypoint as the superuser, against POSTGRES_DB (= daisy_db).
\set ON_ERROR_STOP on

CREATE TABLE IF NOT EXISTS test_demo (
  id         bigserial   PRIMARY KEY,
  name       text        NOT NULL,
  note       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO test_demo (name, note) VALUES
  ('demo 1', 'sample row for testing the connection'),
  ('demo 2', NULL);
