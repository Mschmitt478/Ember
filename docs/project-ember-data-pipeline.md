# Project Ember Data Pipeline

Project Ember's first running path should use the data tools that already exist in the repo:

- `dbutils` for MySQL login/world schema install and migration application.
- `dbcparser` for generated DBC loaders and future DBC validation.
- Service configs that all point login/account/character/realm at the `mysql.db.login` connection profile.

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

## Current Shape

The current runtime services still read the `login` database connection profile:

- `src/login/InitHelpers.h`
- `src/account/InitHelpers.h`
- `src/character/InitHelpers.h`
- `src/realm/Service.cpp`

The `world` schema exists and `dbutils` can install it, but the current `world` service does not yet open a world database connection during startup.

## Remaining Data Work

- Load Matt's extracted 1.12.1 DBC directory through `EMBER_DBC_PATH` for the smoke harness.
- Build a local MySQL database using `project-ember-db.sh bootstrap`.
- Seed at least one login user, realm row, and any required lookup rows for a client-visible realm list.
- Decide whether the `world` schema should hold dynamic world runtime state only, with static gameplay data remaining DBC-backed for the initial build.
- Convert the smoke harness into OCLAW-18 automated integration coverage once seeded data is deterministic.
