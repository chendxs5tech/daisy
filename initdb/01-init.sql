-- Chạy MỘT LẦN duy nhất, ở lần khởi động đầu tiên, khi PGDATA còn rỗng.
-- Được entrypoint chạy bằng superuser, trên database POSTGRES_DB (= daisy).
\set ON_ERROR_STOP on

CREATE TABLE IF NOT EXISTS test_demo (
  id         bigserial   PRIMARY KEY,
  name       text        NOT NULL,
  note       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO test_demo (name, note) VALUES
  ('demo 1', 'dữ liệu mẫu để test kết nối'),
  ('demo 2', NULL);
