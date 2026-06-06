# Project Ember Login-to-World Smoke

This is the first local smoke milestone for proving that Ember's service architecture can move toward a 1.12.1 login-to-world flow without inventing a second server stack.

## Scope

The smoke path is:

1. Build the service binaries.
2. Prepare isolated local-only configs for Fusion, login, account, character, realm, and world.
3. Start Fusion, which starts the service set in one process.
4. Verify that the services reach startup far enough to expose their local sockets and Spark services.

This does not yet prove full gameplay. World attach, player spawn, movement, logout, and reconnect remain downstream slices once service startup and handoff are stable.

## Local Harness

Use `scripts/openclaw/project-ember-smoke.sh`.

Required:

```sh
export EMBER_DBC_PATH=/path/to/1.12.1/dbcs
```

Optional:

```sh
export EMBER_BUILD_DIR=build/openclaw-vcpkg
export EMBER_RUNTIME_DIR=.openclaw/smoke
export EMBER_SMOKE_TIMEOUT=20
export EMBER_DB_HOST=127.0.0.1
export EMBER_DB_PORT=3306
export EMBER_DB_USER=ember
export EMBER_DB_PASSWORD=ember
export EMBER_DB_NAME=ember_login
```

Prepare configs:

```sh
scripts/openclaw/project-ember-smoke.sh prepare
```

Check that binaries, configs, and DBC inputs are present:

```sh
scripts/openclaw/project-ember-smoke.sh preflight
```

Run the smoke:

```sh
scripts/openclaw/project-ember-smoke.sh run
```

The generated runtime files live under `.openclaw/smoke` by default and are intentionally local-only:

- Login client bind: `127.0.0.1:3724`
- Realm client bind: `127.0.0.1:8085`
- World gateway bind: `127.0.0.1:8086`
- Spark services: `127.0.0.1:6000` through `6005`
- STUN, port forwarding, metrics, and console input are disabled

## Current External Prerequisites

The harness does not store credentials or ship data. A complete run still needs:

- Extracted 1.12.1 DBC files.
- A local MySQL-compatible database loaded with the login/character/world schemas expected by the current services. Use `scripts/openclaw/project-ember-db.sh` for the repo-native install/update path.
- Built service binaries in `EMBER_BUILD_DIR`.

## Acceptance Checklist

- `fusion`, `login`, `account`, `character`, `realm`, and `world` binaries exist.
- Smoke configs are generated without secrets committed to git.
- `preflight` fails fast for missing binaries, missing runtime config, or missing DBC data.
- `run` starts Fusion using the generated local-only configuration and exits under the configured timeout.

## Follow-up Tickets

- OCLAW-18: convert this harness into automated realm/world handoff integration coverage.
- OCLAW-7: define the repeatable DBC and SQL data loading path.
- OCLAW-19: clean up character creation placeholders before treating character create/login as complete.
