# daisy — the DX team's shared database

`daisy` is the **DX team's shared database**: one place, one agreed-upon name, where the
whole team reads and writes its data — instead of everyone keeping a private copy and
watching the numbers drift apart.

This directory holds everything needed to stand `daisy` up: a **PostgreSQL 15.12 running
under Docker Compose** that loads its schema on the first start. There is exactly one
service, `postgres`, and nothing else to maintain. The version is pinned so that every
machine runs the identical build.

> The "what do we actually use it for" part — which tables, who writes to them, where the
> data comes from — is not written yet. Fill it in here once the team settles it.

## Naming convention

Everything carries the word `daisy` so its origin is obvious at a glance: project `daisy`,
image `daisy-postgres:15.12`, container `daisy-postgres`, user `daisy`, database
`daisy_db`. Keep to this convention for anything you add.

## Layout

| File | Purpose |
| --- | --- |
| [compose.yml](compose.yml) | Defines the `postgres` service |
| [Dockerfile](Dockerfile) | Custom Postgres image: timezone + copies the initdb scripts |
| [.env.example](.env.example) | Environment variable template, copy it to `.env` |
| [initdb/01-init.sql](initdb/01-init.sql) | The `test_demo` table + 2 sample rows |
| `data/` | Postgres data, created by Docker on the first run. Never commit it |

## Running it

```bash
cp .env.example .env      # then set POSTGRES_PASSWORD
docker compose up -d --build
docker compose ps         # wait until the state reads "healthy"
```

## Connecting

```
postgresql://daisy:<POSTGRES_PASSWORD>@localhost:5432/daisy_db
```

Open psql inside the container:

```bash
docker compose exec postgres psql -U daisy -d daisy_db
```

Quick check that it works:

```bash
docker compose exec postgres psql -U daisy -d daisy_db -c 'select * from test_demo;'
```

## Everyday commands

```bash
docker compose logs -f postgres        # tail the logs
docker compose restart postgres        # restart
docker compose down                    # stop, KEEPING the data
rm -rf ./data                          # DELETE all data (run it after `down`)
```

Backup / restore:

```bash
mkdir -p backups
docker compose exec -T postgres pg_dump -U daisy -d daisy_db -Fc > backups/daisy.dump
docker compose exec -T postgres pg_restore -U daisy -d daisy_db --clean < backups/daisy.dump
```

## Notes

- **As configured, this is not actually shared yet.** Compose publishes the port on the
  `localhost` of whichever machine runs it, and the data lives in a local directory, so
  everyone who runs `docker compose up` gets their own private `daisy` and none of them
  see each other's data. Making it genuinely shared means hosting it on **one** machine
  the team can reach, publishing the port to the internal network rather than only
  `localhost`, and issuing a separate user per person instead of sharing the `daisy` user.
  That part has not been done.
- **A `.env` file is mandatory.** `compose.yml` declares `env_file: .env` without
  `optional: true`, so a missing file makes Compose fail immediately rather than boot with
  hidden defaults. `POSTGRES_DB`, `POSTGRES_USER` and `POSTGRES_PASSWORD` go straight from
  `.env` into the container; `POSTGRES_PORT` is interpolated by Compose itself and also
  errors out if it is not declared.
- **The project lives at `/opt/daisy` on the VM.** The bind mount in `compose.yml` uses a
  relative path (`./data`), so it does not depend on that location — Compose resolves it
  relative to where `compose.yml` sits. At `/opt/daisy`, the data lands in
  `/opt/daisy/data/pgdata`.
- **The data lives inside the project directory**, at `./data/pgdata`, via a bind mount
  rather than a named volume. That makes it visible and backup-able through a real path on
  the host. The consequence: `docker compose down -v` no longer deletes the data (`-v`
  only removes named volumes), so wiping it means deleting the `./data` directory
  yourself.
- `data/` is listed in both `.gitignore` and `.dockerignore`. Both entries are required:
  without the `.gitignore` line you commit the entire database, and without the
  `.dockerignore` line every `--build` copies the entire database into the build context.
- The scripts in `initdb/` **run only once**, while `./data` is still empty. Schema changes
  after that have to be applied as migrations, or reset from scratch with
  `docker compose down && rm -rf ./data && docker compose up -d --build`.
- `initdb/` is deliberately minimal: one `test_demo` table and 2 sample rows — no
  extensions, no separate schema, no triggers.
- The container's timezone is `Asia/Ho_Chi_Minh`, set in the [Dockerfile](Dockerfile).
