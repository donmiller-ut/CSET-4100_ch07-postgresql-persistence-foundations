# PostgreSQL 18 lab setup

Use a fresh cluster reserved for this lab. Do not run the bootstrap on an existing
course, shared, or production cluster. It creates named roles and a database and
intentionally fails if those objects already exist. The API does not connect to
this database yet. Allow time for installation and downloads before the lecture.

## Option A: existing disposable PostgreSQL installation

From the project root, confirm `psql --version`, then connect using your course's
administrator identity and actual host/port:

```bash
psql --host=localhost --port=5432 --username=postgres --dbname=postgres
```

At the `psql` prompt:

```sql
SELECT version(), current_user, current_database();
\i database/ch07/admin-bootstrap.sql
\password northstar_migrator
\password northstar_app
\q
```

Enter different untracked development passwords at the hidden prompts. Do not
copy them into SQL or URLs. Adapt the administrator username if your installation
uses a different one. Authentication must be configured by the course environment.
Do not weaken authentication rules to get past a failed connection.

## Option B: isolated Docker lab

Docker must be running. This route publishes no port and disables the container's
external network. Use its bundled `psql`; DBeaver cannot connect to this isolated
container. SQL skills are the same as in Option A.

From the project root in macOS/Linux Bash or Zsh:

```bash
read -r -s 'POSTGRES_PASSWORD?Temporary administrator password: '
export POSTGRES_PASSWORD
docker run --detach --name northstar-ch07-lab --network none \
  --env POSTGRES_PASSWORD \
  --env 'POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256 --auth-local=trust' \
  --mount "type=bind,source=$PWD,target=/workspace,readonly" \
  --tmpfs /var/lib/postgresql \
  postgres@sha256:1c59e2c3c818eaa0f0628f695b36e7c9e362d6b219b36a54a32df645cbd7e1af
unset POSTGRES_PASSWORD
```

The `read` line above is Zsh syntax. In Bash replace it with
`read -r -s -p 'Temporary administrator password: ' POSTGRES_PASSWORD`.
The pinned image is PostgreSQL 18.6. Download it before class if it is not cached.

In PowerShell, the equivalent setup is:

```powershell
$secret = Read-Host 'Temporary administrator password' -AsSecureString
$env:POSTGRES_PASSWORD = [System.Net.NetworkCredential]::new('', $secret).Password
docker run --detach --name northstar-ch07-lab --network none `
  --env POSTGRES_PASSWORD `
  --env 'POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256 --auth-local=trust' `
  --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" `
  --tmpfs /var/lib/postgresql `
  postgres@sha256:1c59e2c3c818eaa0f0628f695b36e7c9e362d6b219b36a54a32df645cbd7e1af
Remove-Item Env:POSTGRES_PASSWORD
Remove-Variable secret
```

The initialization arguments require SCRAM password authentication for TCP
connections, including localhost. The local Unix socket remains trusted for the
administrator inside this isolated container. Do not generalize that socket policy
to a shared installation. Test an incorrect runtime password: it must be rejected.

Container administrators can inspect environment values. Use only a temporary lab
password, and do not display container inspection output in recordings.
The container name is deliberate: if it already exists, inspect it and choose
another name rather than deleting an unknown container.

Wait until this returns `accepting connections`:

```bash
docker exec northstar-ch07-lab pg_isready --username=postgres
docker exec -it --workdir /workspace northstar-ch07-lab psql --username=postgres
```

Run the same SQL setup block from Option A. The administrator uses the local
container socket; the two lab roles will use password-authenticated TCP below.
Leave the administrator session with `\q`.

For the remaining commands, open a container shell:

```bash
docker exec -it --workdir /workspace northstar-ch07-lab bash
```

All remaining Bash/psql commands work inside that shell on Windows as well.

## Apply the reviewed proposal

From the project root or `/workspace` in the container shell:

```bash
export NORTHSTAR_MIGRATOR_URL=postgresql://northstar_migrator@localhost:5432/northstar_market
psql -X "$NORTHSTAR_MIGRATOR_URL" --set ON_ERROR_STOP=1 --single-transaction \
  --file database/ch07/schema-plan/V1__create_product_schema.sql
```

Supply the migration password at the prompt. Successful output includes
`CREATE TABLE` and grants. `--single-transaction` makes this schema script atomic;
`ON_ERROR_STOP` stops on errors. Do not add single-transaction to the bootstrap,
which includes `CREATE DATABASE`. Reapplying V1 fails because its table exists.
Use only a fresh disposable lab for retries; never edit applied shared migrations.

For a local Windows installation, set the URL using
`$env:NORTHSTAR_MIGRATOR_URL='postgresql://northstar_migrator@localhost:5432/northstar_market'`
and use `$env:NORTHSTAR_MIGRATOR_URL` in the `psql` command. Use one command line
instead of Bash backslash continuations. Run the Bash verifier through Git Bash,
or use the supplied Docker route. Windows commands are supplied, not platform-tested.

## Inspect as the runtime identity

```bash
export NORTHSTAR_APP_URL=postgresql://northstar_app@localhost:5432/northstar_market
psql -X "$NORTHSTAR_APP_URL"
```

Enter the different runtime password. Then inspect:

```sql
SELECT version();
SELECT current_user, current_database(), current_schema();
\d northstar.product
SELECT privilege_type FROM information_schema.role_table_grants
WHERE grantee = 'northstar_app' AND table_schema = 'northstar'
  AND table_name = 'product' ORDER BY privilege_type;
SELECT scale(1.2300), min_scale(1.2300);
\q
```

Expect `northstar_app`, `northstar_market`, `northstar`, four row privileges, and
scales 4 and 2. This proposed table has no relationship to the running API's map.

## Verify and clean up

In Bash, avoid repeated password prompts by keeping the runtime password only
in this temporary shell environment while the verifier runs:

```bash
read -r -s -p 'Runtime password: ' PGPASSWORD
export PGPASSWORD
bash database/ch07/verify-database.sh
unset PGPASSWORD
```

Environment variables are still sensitive to processes with sufficient local
privileges. Use this only on your disposable lab machine, do not print the value,
and close the shell afterward. An appropriately protected PostgreSQL password
file or approved secret manager is preferable for recurring use.

Expect approved row operations, `ROLLBACK`, and 11 expected SQLSTATE rejections.
A connection failure is an error, not proof that a constraint worked. Verification
leaves no rows, but identity sequence values may advance. On a clean lab,
`SELECT count(*) FROM northstar.product;` should return zero afterward.

Exit the container shell, confirm this is your disposable lab, then remove only
that named container:

```bash
docker stop northstar-ch07-lab
docker rm northstar-ch07-lab
```

Stopping this tmpfs-based lab discards all database contents. Recreate it and apply
the scripts to reset. This deliberately differs from durable production storage.
Do not generalize container cleanup to shared databases. For Option A, follow your
course's instance-specific shutdown/reset procedure, never a broad data-directory
deletion command.
