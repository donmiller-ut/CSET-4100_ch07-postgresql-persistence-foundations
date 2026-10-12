# Chapter 7: PostgreSQL and persistence foundations

Open this folder in VS Code. It contains `pom.xml`, both Maven launchers, source,
tests, and `database/ch07`. No textbook repository or Git history is needed.
The Product API remains in memory. PostgreSQL is a separate lab in this chapter.
Do not expose either service to the internet.

## Software

Use JDK 25, VS Code with Java support, and a disposable PostgreSQL 18 installation
with its `psql` client. Docker is an optional way to run the supplied database lab
without installing PostgreSQL locally. DBeaver and Bruno are optional clients.
First builds need internet access for Maven dependencies. The wrapper supplies
Maven 3.9.16, not Java. Confirm `java -version` and `./mvnw --version` both show 25.

## Application build and run

```bash
./mvnw clean verify
java -jar target/northstar-market-0.0.1-SNAPSHOT.jar --server.address=127.0.0.1
```

On PowerShell use `.\mvnw.cmd clean verify`. The suite contains 40 tests and
does not require a database. In another terminal, request
`http://127.0.0.1:8080/api/products/42`, `/api/status`, and `/actuator/health`.
Use `curl` on macOS/Linux or `curl.exe` on Windows. Stop with Ctrl+C and confirm
requests no longer connect. Restart restores the seed and discards API changes.
If 8080 is occupied, append `--server.port=8090` and change the client URLs.

`contract/` contains the Chapter 6 contract retained here. `bruno-ch05/` and
`bruno-ch06/` contain the seven-request lifecycle and eleven-request boundary
collections. Run each from its own folder with
`bru run --env Local --env-var baseUrl=http://127.0.0.1:8080 --bail`.
They test HTTP behavior, not persistence. The appointment controller is test-only.

## PostgreSQL lab

Follow [database/ch07/README.md](database/ch07/README.md) for either the local
installation or isolated Docker route. Read the SQL before running it. Use a
fresh disposable cluster, never a shared database. The bootstrap refuses repeated
creation rather than silently changing existing roles.

Files used in the lecture:

- `database/ch07/admin-bootstrap.sql`: owner, migrator, runtime, and database.
- `database/ch07/schema-plan/V1__create_product_schema.sql`: reviewed proposal.
- `database/ch07/verify-allowed-operations.sql`: approved row operations and rollback.
- `database/ch07/verify-database.sh`: identity checks and 11 expected rejections.
- `database/ch07/application-database.env.example`: future configuration names only.
- `src/main/java/com/example/northstarmarket/product/PriceIncrementValidator.java`:
  application rule to compare with SQL `min_scale`.

The SQL checks accept `1.2300`, reject a fractional cent, and reject special
non-finite numeric values. The name check rejects ordinary spaces, but does not
reproduce all Java `@NotBlank` whitespace rules. `BY DEFAULT` identity permits
explicit SQL identifiers. The HTTP DTO separately rejects client-assigned IDs.
Rolled-back inserts still advance identity sequences. Never depend on gapless IDs.

## Provenance and limits

This package combines the reviewed Chapter 6 API at historical commit
`b0860c91329394185096a89b805f14423bc72fbc` with Chapter 7 database foundations from
`bc0a41b` and reviewed Chapter 7 overrides. The maintainer regenerates it with
`scripts/prepare-chapter-07.sh` in the textbook repository. Students do not need
that helper. The proposed V1 is only for a fresh Chapter 7 database; do not replace
an applied migration with it. Later application persistence requires a deliberate
schema migration path. This application has no JDBC driver, DataSource, JPA,
authentication, or operational logging pipeline. A healthy API does not prove
database connectivity. Container use here is setup convenience, not a deployment
lesson. No license grant is implied by this teaching package.
