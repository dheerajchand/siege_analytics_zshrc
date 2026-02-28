# Module: Database

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
PostgreSQL helpers and credential wiring.

## Environment
- `PGHOST` (default `localhost`)
- `DEFAULT_PG_USER` (default current shell user)
- `PGUSER` (default `${DEFAULT_PG_USER}`)
- `PGPORT` (default `5432`)
- `PGDATABASE` (default `postgres`)
- `PGPASSWORD` (set by `setup_postgres_credentials`)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `setup_postgres_credentials` | Configure `PGPASSWORD` | `get_credential`, `store_credential` | Interactive shell for prompts |
| `pg_test_connection` | Test PostgreSQL connectivity | `psql` | Database reachable |
| `pg_connect` | Connect to database | `psql` | `PGPASSWORD` set or prompt allowed |
| `psql_quick` | Quick `psql` session | `psql` | Uses current env defaults |
| `database_status` | Print status summary | `psql` | `psql` available for version/health |

## Notes
- Credential storage uses `credentials.zsh` when available.
- `pg_connect --test` is equivalent to `pg_test_connection`.
