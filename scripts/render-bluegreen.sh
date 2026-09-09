#!/usr/bin/env bash
#
# Render the aks-store-quickstart manifests for a blue/green deployment.
#
# Usage: render-bluegreen.sh <manifest> <color> <output-dir>
#
# Three files are written to <output-dir>:
#
#   infra.yaml     - resources that are shared between both colors (the RabbitMQ
#                    StatefulSet and its Service). They are applied unchanged.
#   workloads.yaml - the Deployments, renamed to "<name>-<color>" and labelled
#                    with "color: <color>" so that the blue and green versions
#                    can run side by side.
#   services.yaml  - the Services in front of those Deployments, with a
#                    "color: <color>" selector so that traffic is only sent to
#                    the requested color. Applying this file performs the
#                    cutover.
#
set -euo pipefail

MANIFEST="${1:?usage: render-bluegreen.sh <manifest> <color> <output-dir>}"
COLOR="${2:?usage: render-bluegreen.sh <manifest> <color> <output-dir>}"
OUTPUT_DIR="${3:?usage: render-bluegreen.sh <manifest> <color> <output-dir>}"

if [[ "${COLOR}" != "blue" && "${COLOR}" != "green" ]]; then
  echo "error: color must be either 'blue' or 'green', got '${COLOR}'" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

# The apps that take part in the blue/green rollout are the ones backed by a
# Deployment. Everything else (the RabbitMQ StatefulSet) is shared state and is
# deployed once.
BLUE_GREEN_APPS="$(yq eval-all -N 'select(.kind == "Deployment") | .spec.selector.matchLabels.app' "${MANIFEST}" | sort -u | paste -sd, -)"
export BLUE_GREEN_APPS
export COLOR

# shellcheck disable=SC2016 # $app is a yq variable, not a shell variable
yq eval '
  select(.kind != "Deployment")
  | select(.kind != "Service" or (.spec.selector.app as $app | strenv(BLUE_GREEN_APPS) | split(",") | contains([$app]) | not))
' "${MANIFEST}" >"${OUTPUT_DIR}/infra.yaml"

yq eval '
  select(.kind == "Deployment")
  | .metadata.name = .metadata.name + "-" + strenv(COLOR)
  | .metadata.labels.color = strenv(COLOR)
  | .spec.selector.matchLabels.color = strenv(COLOR)
  | .spec.template.metadata.labels.color = strenv(COLOR)
' "${MANIFEST}" >"${OUTPUT_DIR}/workloads.yaml"

# shellcheck disable=SC2016 # $app is a yq variable, not a shell variable
yq eval '
  select(.kind == "Service")
  | select(.spec.selector.app as $app | strenv(BLUE_GREEN_APPS) | split(",") | contains([$app]))
  | .spec.selector.color = strenv(COLOR)
' "${MANIFEST}" >"${OUTPUT_DIR}/services.yaml"
