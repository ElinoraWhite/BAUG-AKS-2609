#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <base-manifest> <output-manifest> <color>" >&2
  exit 1
fi

BASE_MANIFEST="$1"
OUTPUT_MANIFEST="$2"
COLOR="$3"

if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
  echo "Color must be blue or green" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cp "$BASE_MANIFEST" "$WORKDIR/base.yaml"

cat > "$WORKDIR/kustomization.yaml" <<KUSTOMIZATION
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base.yaml
patches:
  - target:
      kind: Deployment
      name: order-service
    patch: |-
      - op: replace
        path: /metadata/name
        value: order-service-${COLOR}
      - op: add
        path: /spec/selector/matchLabels/color
        value: ${COLOR}
      - op: add
        path: /spec/template/metadata/labels/color
        value: ${COLOR}
  - target:
      kind: Deployment
      name: product-service
    patch: |-
      - op: replace
        path: /metadata/name
        value: product-service-${COLOR}
      - op: add
        path: /spec/selector/matchLabels/color
        value: ${COLOR}
      - op: add
        path: /spec/template/metadata/labels/color
        value: ${COLOR}
  - target:
      kind: Deployment
      name: store-front
    patch: |-
      - op: replace
        path: /metadata/name
        value: store-front-${COLOR}
      - op: add
        path: /spec/selector/matchLabels/color
        value: ${COLOR}
      - op: add
        path: /spec/template/metadata/labels/color
        value: ${COLOR}
  - target:
      kind: Service
      name: order-service
    patch: |-
      - op: add
        path: /spec/selector/color
        value: ${COLOR}
  - target:
      kind: Service
      name: product-service
    patch: |-
      - op: add
        path: /spec/selector/color
        value: ${COLOR}
  - target:
      kind: Service
      name: store-front
    patch: |-
      - op: add
        path: /spec/selector/color
        value: ${COLOR}
KUSTOMIZATION

kubectl kustomize "$WORKDIR" > "$OUTPUT_MANIFEST"
