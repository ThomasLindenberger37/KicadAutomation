#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

CONFIG_FILE="${CONFIG_FILE:-project.config.yaml}"
LEGACY_CONFIG="${SCRIPT_DIR}/project.config.yaml"
EXAMPLE_CONFIG="${SCRIPT_DIR}/ECAMPLE_CONFIG.yaml"

echo "Repository root: ${ROOT_DIR}"
echo "Submodule path: ${SCRIPT_DIR}"
echo "Config file: ${CONFIG_FILE}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  if [[ -f "${LEGACY_CONFIG}" ]]; then
    cp "${LEGACY_CONFIG}" "${CONFIG_FILE}"
    echo "Migrated config from ${LEGACY_CONFIG} to ${CONFIG_FILE}"
  elif [[ -f "${EXAMPLE_CONFIG}" ]]; then
    cp "${EXAMPLE_CONFIG}" "${CONFIG_FILE}"
    echo "Created ${CONFIG_FILE} from ${EXAMPLE_CONFIG}"
  else
    echo "No config template found. Expected ${EXAMPLE_CONFIG}" >&2
    exit 1
  fi
else
  echo "Keeping existing ${CONFIG_FILE}"
fi

echo
echo "Bootstrap complete."
echo "Next step: edit ${CONFIG_FILE} for board_name/output_name if needed."
