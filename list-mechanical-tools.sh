#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CONFIG_FILE="${CONFIG_FILE:-}"
BOARD_BASE=""
DRILL_FILE=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/list-mechanical-tools.sh [--config <file>] [--board <name>] [--drill <file>]

Examples:
  ./scripts/list-mechanical-tools.sh
  ./scripts/list-mechanical-tools.sh --board ESP32_Shield_light
  ./scripts/list-mechanical-tools.sh --drill Fabrication/Drill/ESP32_Shield_light-drill.drl
EOF
}

# First pass: allow selecting an alternative config file.
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "--config" ]]; then
    j=$((i+1))
    CONFIG_FILE="${!j}"
    break
  fi
done

resolve_config_file() {
  if [[ -n "${CONFIG_FILE}" ]]; then
    printf '%s\n' "${CONFIG_FILE}"
    return
  fi

  if [[ -f "project.config.yaml" ]]; then
    printf '%s\n' "project.config.yaml"
    return
  fi

  if [[ -f "scripts/project.config.yaml" ]]; then
    printf '%s\n' "scripts/project.config.yaml"
    return
  fi

  printf '%s\n' "project.config.yaml"
}

CONFIG_FILE="$(resolve_config_file)"

cfg_get() {
  local key="$1"
  local file="$2"
  [[ -f "${file}" ]] || return 0
  awk -v k="${key}" '
    $0 ~ "^[[:space:]]*"k":[[:space:]]*" {
      v=$0
      sub("^[[:space:]]*"k":[[:space:]]*", "", v)
      sub(/[[:space:]]*#.*/, "", v)
      gsub(/^["'"'"']|["'"'"']$/, "", v)
      print v
      exit
    }
  ' "${file}"
}

if [[ -f "${CONFIG_FILE}" ]]; then
  cfg_board="$(cfg_get board_name "${CONFIG_FILE}")"
  [[ -n "${cfg_board}" ]] && BOARD_BASE="${cfg_board}"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --config)
      shift 2
      ;;
    --board)
      BOARD_BASE="${2:-}"
      shift 2
      ;;
    --drill)
      DRILL_FILE="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${DRILL_FILE}" ]]; then
  if [[ -z "${BOARD_BASE}" ]]; then
    PCB_FILE="$(ls *.kicad_pcb | head -n 1)"
    BOARD_BASE="${PCB_FILE%.kicad_pcb}"
  fi
  DRILL_FILE="Fabrication/Drill/${BOARD_BASE}-drill.drl"
fi

if [[ ! -f "${DRILL_FILE}" ]]; then
  echo "Drill file not found: ${DRILL_FILE}" >&2
  echo "Hint: run ./scripts/fabrication.sh first, or pass --drill <path>" >&2
  exit 1
fi

python3 scripts/list_drill_tools.py --drill "${DRILL_FILE}"
