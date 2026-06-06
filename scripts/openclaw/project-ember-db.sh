#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: project-ember-db.sh <print|install|update|bootstrap>

Commands:
  print      Show the dbutils command that would run.
  install    Create login/world databases and users with dbutils.
  update     Apply login/world migrations with dbutils.
  bootstrap  Run install, then update.

Environment:
  EMBER_BUILD_DIR          CMake build directory. Default: build/openclaw-vcpkg
  EMBER_SQL_DIR            SQL directory. Default: sql/
  EMBER_DB_HOST            MySQL host. Default: 127.0.0.1
  EMBER_DB_PORT            MySQL port. Default: 3306
  EMBER_DB_ROOT_USER       Privileged DB user. Default: root
  EMBER_DB_ROOT_PASSWORD   Privileged DB password. Default: empty
  EMBER_LOGIN_DB           Login DB name. Default: ember_login
  EMBER_LOGIN_DB_USER      Login service DB user. Default: ember_login
  EMBER_LOGIN_DB_PASSWORD  Login service DB password. Default: ember_login
  EMBER_WORLD_DB           World DB name. Default: ember_world
  EMBER_WORLD_DB_USER      World service DB user. Default: ember_world
  EMBER_WORLD_DB_PASSWORD  World service DB password. Default: ember_world
  EMBER_DB_CLEAN           Set to 1 to pass --clean during install.
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

quote_cmd() {
  printf '%q ' "$@"
  printf '\n'
}

dbutils_args() {
  local mode="$1"
  local root="$2"
  local build_dir="$3"
  local sql_dir="$4"
  local dbutils="${build_dir}/src/tools/dbutils/dbutils"

  [[ -x "${dbutils}" ]] || die "missing dbutils executable: ${dbutils}"
  [[ -d "${sql_dir}" ]] || die "missing SQL directory: ${sql_dir}"

  local common=(
    "--database-type" "mysql"
    "--sql-dir" "${sql_dir%/}/"
    "--login.hostname" "${EMBER_DB_HOST:-127.0.0.1}"
    "--login.port" "${EMBER_DB_PORT:-3306}"
    "--login.root-user" "${EMBER_DB_ROOT_USER:-root}"
    "--login.root-password" "${EMBER_DB_ROOT_PASSWORD:-}"
    "--login.db-name" "${EMBER_LOGIN_DB:-ember_login}"
    "--world.hostname" "${EMBER_DB_HOST:-127.0.0.1}"
    "--world.port" "${EMBER_DB_PORT:-3306}"
    "--world.root-user" "${EMBER_DB_ROOT_USER:-root}"
    "--world.root-password" "${EMBER_DB_ROOT_PASSWORD:-}"
    "--world.db-name" "${EMBER_WORLD_DB:-ember_world}"
    "--shutup"
  )

  case "${mode}" in
    install)
      DBUTILS_COMMAND=(
        "${dbutils}"
        "--install" "login" "world"
        "--login.set-user" "${EMBER_LOGIN_DB_USER:-ember_login}"
        "--login.set-password" "${EMBER_LOGIN_DB_PASSWORD:-ember_login}"
        "--world.set-user" "${EMBER_WORLD_DB_USER:-ember_world}"
        "--world.set-password" "${EMBER_WORLD_DB_PASSWORD:-ember_world}"
        "${common[@]}"
      )
      if [[ "${EMBER_DB_CLEAN:-0}" == "1" ]]; then
        DBUTILS_COMMAND+=("--clean")
      fi
      ;;
    update)
      DBUTILS_COMMAND=(
        "${dbutils}"
        "--update" "login" "world"
        "${common[@]}"
      )
      ;;
    *)
      die "unknown dbutils mode: ${mode}"
      ;;
  esac
}

run_mode() {
  local action="$1"
  local dry_run="$2"
  local root="$3"
  local build_dir="$4"
  local sql_dir="$5"

  dbutils_args "${action}" "${root}" "${build_dir}" "${sql_dir}"

  if [[ "${dry_run}" == "1" ]]; then
    quote_cmd "${DBUTILS_COMMAND[@]}"
  else
    "${DBUTILS_COMMAND[@]}"
  fi
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
  local sql_dir
  sql_dir="$(abs_path "${EMBER_SQL_DIR:-sql}" "${root}")"

  case "${command}" in
    print)
      run_mode install 1 "${root}" "${build_dir}" "${sql_dir}"
      run_mode update 1 "${root}" "${build_dir}" "${sql_dir}"
      ;;
    install)
      run_mode install 0 "${root}" "${build_dir}" "${sql_dir}"
      ;;
    update)
      run_mode update 0 "${root}" "${build_dir}" "${sql_dir}"
      ;;
    bootstrap)
      run_mode install 0 "${root}" "${build_dir}" "${sql_dir}"
      run_mode update 0 "${root}" "${build_dir}" "${sql_dir}"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

declare -a DBUTILS_COMMAND
main "$@"
