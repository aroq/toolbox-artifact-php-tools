#!/usr/bin/env bash

# Set strict bash mode
set -euo pipefail

. /toolbox/toolbox-utils/includes/log.sh

TOOLBOX_TOOL=${TOOLBOX_TOOL:-}
TOOLBOX_TOOL_PATH=${TOOLBOX_TOOL_PATH:-}
TOOLBOX_TOOL_DIRS=${TOOLBOX_TOOL_DIRS:-toolbox}
TOOLBOX_WRAP_ENTRYPOINT_MODE=${TOOLBOX_WRAP_ENTRYPOINT_MODE:-run}

_log TRACE "entrypoint.sh: Inside docker (aroq/toolbox-variant)"
_log DEBUG "TOOLBOX_TOOL: ${TOOLBOX_TOOL}"
_log DEBUG "TOOLBOX_TOOL_DIRS: ${TOOLBOX_TOOL_DIRS}"

if [ ! -f "${TOOLBOX_TOOL}" ]; then
IFS=" "
for i in $(echo "$TOOLBOX_TOOL_DIRS" | sed "s/,/ /g")
do
  _log DEBUG "Check if tool exists at path: ${i}/${TOOLBOX_TOOL}"
  if [[ -f "${i}/${TOOLBOX_TOOL}" ]]; then
    TOOLBOX_TOOL_PATH="${i}/${TOOLBOX_TOOL}"
    break
  fi
done
fi

if [[ -z ${TOOLBOX_TOOL_PATH} ]] || [[ ! -f ${TOOLBOX_TOOL_PATH} ]]; then
  _log ERROR "TOOLBOX_TOOL_PATH: ${TOOLBOX_TOOL_PATH} NOT FOUND!"
  exit 1
fi

_log DEBUG "TOOLBOX_TOOL_PATH=\"${TOOLBOX_TOOL_PATH}\""
_log TRACE "entrypoint.sh: Execute entrypoint in ${TOOLBOX_WRAP_ENTRYPOINT_MODE} mode"
_log TRACE "Env vars inside docker image:"
_log TRACE "$(env)"

case "$TOOLBOX_WRAP_ENTRYPOINT_MODE" in
  vars)
    echo "TOOLBOX_TOOL_PATH=\"${TOOLBOX_TOOL_PATH}\""
    if [[ -f ${TOOLBOX_TOOL_PATH} ]] && grep -Fq variant "${TOOLBOX_TOOL_PATH}"; then
      yq r -j "${TOOLBOX_TOOL_PATH}" | jq -r '. | recurse(.tasks[]?) | select(.bindParamsFromEnv == true) | .parameters | .[]? | .name' | uniq
    fi;;
  run)
    _log DEBUG "Execute tool: ${TOOLBOX_TOOL_PATH} $*"
    ${TOOLBOX_TOOL_PATH} "$@";;
esac
