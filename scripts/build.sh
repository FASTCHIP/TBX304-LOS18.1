#!/usr/bin/env bash
# Run from the root of a synced LOS 18.1 tree containing local_manifests/TBX304.xml.
set -euo pipefail
[ -f build/envsetup.sh ] || { echo "run from LOS 18.1 tree root"; exit 1; }
export USE_CCACHE=1 CCACHE_COMPRESS=1 CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
source build/envsetup.sh
brunch TBX304
echo "artifacts:"
ls -la out/target/product/TBX304/ | grep -E "\.zip|boot\.img|recovery\.img" || true
