# Project Ember Data Pipeline

Project Ember's first running path should use the data tools that already exist in the repo:

- `dbutils` for MySQL login/world schema install and migration application.
- `dbcparser` for generated DBC loaders and future DBC validation.
- Service configs that point login/account/character/realm at the `mysql.db.login` connection profile and prepare a `mysql.db.world` profile for the world runtime schema path.

## Local Database Wrapper

Use `scripts/openclaw/project-ember-db.sh` after building the `dbutils` target.

Show the commands without connecting to MySQL:

```sh
scripts/openclaw/project-ember-db.sh print
```

Create databases and users:

```sh
export EMBER_DB_ROOT_USER=root
export EMBER_DB_ROOT_PASSWORD=...
export EMBER_LOGIN_DB_PASSWORD=...
export EMBER_WORLD_DB_PASSWORD=...
scripts/openclaw/project-ember-db.sh install
```

Apply migrations:

```sh
scripts/openclaw/project-ember-db.sh update
```

Install, then update:

```sh
scripts/openclaw/project-ember-db.sh bootstrap
```

Seed a smoke-test login user and realm after the login schema exists:

```sh
cmake --build build/openclaw-vcpkg --target srpgen
scripts/openclaw/project-ember-seed.sh print
scripts/openclaw/project-ember-seed.sh apply
```

## Environment

The wrapper accepts:

- `EMBER_BUILD_DIR`: CMake build directory, default `build/openclaw-vcpkg`.
- `EMBER_SQL_DIR`: SQL root, default `sql/`.
- `EMBER_DB_HOST`: MySQL host, default `127.0.0.1`.
- `EMBER_DB_PORT`: MySQL port, default `3306`.
- `EMBER_DB_ROOT_USER`: privileged DB user, default `root`.
- `EMBER_DB_ROOT_PASSWORD`: privileged DB password, default empty.
- `EMBER_LOGIN_DB`: login DB name, default `ember_login`.
- `EMBER_LOGIN_DB_USER`: login service DB user, default `ember_login`.
- `EMBER_LOGIN_DB_PASSWORD`: login service DB password, default `ember_login`.
- `EMBER_WORLD_DB`: world DB name, default `ember_world`.
- `EMBER_WORLD_DB_USER`: world service DB user, default `ember_world`.
- `EMBER_WORLD_DB_PASSWORD`: world service DB password, default `ember_world`.
- `EMBER_DB_CLEAN`: set to `1` to pass `--clean` during install.

Do not commit real database passwords. Export them only in the local shell or use a local secret manager.

`scripts/openclaw/project-ember-seed.sh` accepts the same login database connection variables plus:

- `MYSQL_CLIENT`: mysql-compatible client, default `mysql`.
- `EMBER_DEFAULT_USER`: smoke account username, default `OPENCLAW`.
- `EMBER_DEFAULT_PASS`: smoke account password, default `openclaw`.
- `EMBER_DEFAULT_EMAIL`: smoke account email, default `openclaw@example.invalid`.
- `EMBER_REALM_ID`: realm id to upsert, default `1`.
- `EMBER_REALM_NAME`: realm name, default `Ember Local`.
- `EMBER_REALM_IP`: realm IP advertised to the client, default `127.0.0.1`.
- `EMBER_REALM_PORT`: realm port advertised to the client, default `8085`.
- `EMBER_REALM_TYPE`: realm type, default `1`.
- `EMBER_REALM_FLAGS`: realm flags, default `0`.
- `EMBER_REALM_POPULATION`: realm population, default `0`.
- `EMBER_REALM_CREATION`: realm creation setting, default `0`.
- `EMBER_REALM_CATEGORY`: realm category, default `1`.
- `EMBER_REALM_REGION`: realm region, default `3`.

## Current Shape

The current runtime services still read the `login` database connection profile:

- `src/login/InitHelpers.h`
- `src/account/InitHelpers.h`
- `src/character/InitHelpers.h`
- `src/realm/Service.cpp`

The `world` schema exists and `dbutils` can install it, but the current `world` service does not yet open a world database connection during startup.
The smoke harness already emits `mysql.db.world` in `mysql_config.conf` so the world service can move to that profile without changing the local runtime wrapper.

## Remaining Data Work

- Load Matt's extracted 1.12.1 DBC directory through `EMBER_DBC_PATH` for the smoke harness.
- Build a local MySQL database using `project-ember-db.sh bootstrap`.
- Run the smoke seed against a local MySQL/MariaDB instance once one is available.
- Decide whether the `world` schema should hold dynamic world runtime state only, with static gameplay data remaining DBC-backed for the initial build.
- Convert the smoke harness into OCLAW-18 automated integration coverage once seeded data is deterministic.
