#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: project-ember-smoke.sh <prepare|preflight|run>

Environment:
  EMBER_BUILD_DIR      CMake build directory. Default: build/openclaw-vcpkg
  EMBER_RUNTIME_DIR    Runtime config/log directory. Default: .openclaw/smoke
  EMBER_DBC_PATH       Absolute or repo-relative path to extracted 1.12.1 DBC files.
  EMBER_SMOKE_TIMEOUT  Seconds to keep Fusion running in run mode. Default: 20

Optional database values for generated mysql_config.conf:
  EMBER_DB_HOST, EMBER_DB_PORT, EMBER_DB_USER, EMBER_DB_PASSWORD, EMBER_DB_NAME
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  cd -- "${script_dir}/../.." && pwd
}

abs_path() {
  local value="$1"
  local base="$2"
  if [[ "${value}" = /* ]]; then
    printf '%s\n' "${value}"
  else
    printf '%s/%s\n' "${base}" "${value}"
  fi
}

write_common_log_config() {
  local service="$1"
  local file="$2"
  cat <<EOF
[remote_log]
service_name = ${service}
verbosity = none
host = localhost
port = 514

[file_log]
verbosity = info
path = logs/${file}
midnight_rotate = 0
mode = truncate
size_rotate = 0
log_timestamp = 1
timestamp_format = [%d/%m/%Y %H:%M:%S]
log_severity = 1

[console_log]
enable_input = false
suggestions = false
verbosity = info
colours = false
EOF
}

write_monitor_config() {
  cat <<'EOF'
[metrics]
enabled = false
statsd_host = localhost
statsd_port = 8125

[monitor]
enabled = false
interface = 127.0.0.1
port = 3900
EOF
}

write_runtime_configs() {
  local runtime_dir="$1"
  local dbc_path="$2"
  local db_host="${EMBER_DB_HOST:-127.0.0.1}"
  local db_port="${EMBER_DB_PORT:-3306}"
  local db_user="${EMBER_DB_USER:-ember}"
  local db_password="${EMBER_DB_PASSWORD:-ember}"
  local db_name="${EMBER_DB_NAME:-ember_login}"

  mkdir -p "${runtime_dir}/logs"

  cat > "${runtime_dir}/mysql_config.conf" <<EOF
[mysql.db.login]
username = ${db_user}
password = ${db_password}
database = ${db_name}
host = ${db_host}
port = ${db_port}
EOF

  cat > "${runtime_dir}/fusion.conf" <<'EOF'
[mdns]
active = false
config = mdns.conf
prefix = [mdns]
file = logs/fusion_mdns.log

[account]
active = true
config = account.conf
prefix = [account]
file = logs/fusion_account.log

[character]
active = true
config = character.conf
prefix = [character]
file = logs/fusion_character.log

[login]
active = true
config = login.conf
prefix = [login]
file = logs/fusion_login.log

[realm]
active = true
config = realm.conf
prefix = [realm]
file = logs/fusion_realm.log

[world]
active = true
config = world.conf
prefix = [world]
file = logs/fusion_world.log

[remote_log]
service_name = fusion
verbosity = none
host = localhost
port = 514

[file_log]
verbosity = info
path = logs/fusion.log
midnight_rotate = 0
mode = truncate
size_rotate = 0
log_timestamp = 1
timestamp_format = [%d/%m/%Y %H:%M:%S]
log_severity = 1

[console_log]
enable_input = false
suggestions = false
verbosity = info
colours = false
prefix = [fusion]
EOF

  cat > "${runtime_dir}/login.conf" <<EOF
[login]
builds = 1, 12, 1, 5875

[dbc]
path = ${dbc_path}

[integrity]
enabled = 0
bin_path = ""

[misc]
locales = false
verified_emails = false

[patches]
bin_path = ""

[survey]
id = 0
path = Survey.mpq

[network]
interface = 127.0.0.1
port = 3724
tcp_no_delay = true

[spark]
address = 127.0.0.1
port = 6000

[nsd]
host = 127.0.0.1
port = 6010

[stun]
enabled = false
server = stun.l.google.com
port = 3479
protocol = udp

[forward]
enabled = false
method = upnp
gateway = 0.0.0.0

[database]
config_path = mysql_config.conf
min_connections = 1
max_connections = 2

$(write_common_log_config login login.log)

$(write_monitor_config)
EOF

  cat > "${runtime_dir}/realm.conf" <<EOF
[realm]
id = 1
max_slots = 10000
max_sockets = -1
reserved_slots = 5
auth_timeout = 30
char_list_timeout = 900
builds = 1, 12, 1, 5875

[dbc]
path = ${dbc_path}

[quirks]
list_zone_hide = true

[misc]
concurrency = 0

[network]
interface = 127.0.0.1
port = 8085
compression = 0
tcp_no_delay = true

[spark]
address = 127.0.0.1
port = 6002

[nsd]
host = 127.0.0.1
port = 6010

[stun]
enabled = false
server = stun.l.google.com
port = 3479
protocol = udp

[forward]
enabled = false
method = upnp
gateway = 0.0.0.0

[database]
config_path = mysql_config.conf

$(write_common_log_config realm realm.log)

$(write_monitor_config)
EOF

  cat > "${runtime_dir}/world.conf" <<EOF
[world]
id = 0
map_id = 0

[dbc]
path = ${dbc_path}

[network]
interface = 127.0.0.1
port = 8086
tcp_no_delay = true

[spark]
address = 127.0.0.1
port = 6005

[nsd]
host = 127.0.0.1
port = 6010

[database]
config_path = mysql_config.conf
min_connections = 1
max_connections = 2

$(write_common_log_config world world.log)
EOF

  cat > "${runtime_dir}/account.conf" <<EOF
[spark]
address = 127.0.0.1
port = 6003

[nsd]
host = 127.0.0.1
port = 6010

[database]
config_path = mysql_config.conf
min_connections = 1
max_connections = 2

$(write_common_log_config account account.log)

$(write_monitor_config)
EOF

  cat > "${runtime_dir}/character.conf" <<EOF
defer_zone_placement = 0
max_chars_slots_account = 100
max_chars_slots_server = 10

[dbc]
path = ${dbc_path}

[spark]
address = 127.0.0.1
port = 6001

[nsd]
host = 127.0.0.1
port = 6010

[database]
config_path = mysql_config.conf
min_connections = 1
max_connections = 2

$(write_common_log_config character character.log)

$(write_monitor_config)
EOF

  cat > "${runtime_dir}/mdns.conf" <<EOF
[mdns]
interface = 127.0.0.1
port = 5353

[spark]
address = 127.0.0.1
port = 6010

$(write_common_log_config mdns mdns.log)

$(write_monitor_config)
EOF
}

check_binary() {
  local path="$1"
  [[ -x "${path}" ]] || die "missing executable: ${path}"
}

preflight() {
  local root="$1"
  local build_dir="$2"
  local runtime_dir="$3"
  local dbc_path="$4"

  check_binary "${build_dir}/src/fusion/fusion"
  check_binary "${build_dir}/src/login"
  check_binary "${build_dir}/src/realm"
  check_binary "${build_dir}/src/world"
  check_binary "${build_dir}/src/account"
  check_binary "${build_dir}/src/character"

  [[ -d "${runtime_dir}" ]] || die "runtime directory is missing; run prepare first"
  [[ -f "${runtime_dir}/fusion.conf" ]] || die "fusion.conf is missing; run prepare first"
  [[ -n "${dbc_path}" ]] || die "EMBER_DBC_PATH is required for service startup"
  [[ -d "${dbc_path}" ]] || die "DBC path does not exist: ${dbc_path}"

  echo "preflight ok"
  echo "repo: ${root}"
  echo "build: ${build_dir}"
  echo "runtime: ${runtime_dir}"
  echo "dbc: ${dbc_path}"
}

main() {
  local command="${1:-}"
  if [[ -z "${command}" || "${command}" == "-h" || "${command}" == "--help" ]]; then
    usage
    exit 0
  fi

  local root
  root="$(repo_root)"
  local build_dir
  build_dir="$(abs_path "${EMBER_BUILD_DIR:-build/openclaw-vcpkg}" "${root}")"
  local runtime_dir
  runtime_dir="$(abs_path "${EMBER_RUNTIME_DIR:-.openclaw/smoke}" "${root}")"
  local dbc_path=""
  if [[ -n "${EMBER_DBC_PATH:-}" ]]; then
    dbc_path="$(abs_path "${EMBER_DBC_PATH}" "${root}")"
  fi

  case "${command}" in
    prepare)
      [[ -n "${dbc_path}" ]] || die "EMBER_DBC_PATH is required to write runtime configs"
      write_runtime_configs "${runtime_dir}" "${dbc_path}"
      echo "prepared ${runtime_dir}"
      ;;
    preflight)
      preflight "${root}" "${build_dir}" "${runtime_dir}" "${dbc_path}"
      ;;
    run)
      [[ -n "${dbc_path}" ]] || die "EMBER_DBC_PATH is required for service startup"
      write_runtime_configs "${runtime_dir}" "${dbc_path}"
      preflight "${root}" "${build_dir}" "${runtime_dir}" "${dbc_path}"
      cd "${runtime_dir}"
      timeout --foreground "${EMBER_SMOKE_TIMEOUT:-20}" "${build_dir}/src/fusion/fusion" fusion.conf
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
