#!/usr/bin/env bash
# Host prep for LOS 18.1 builds on Ubuntu >= 24.04 / WSL. Run as root BEFORE the first brunch.
set -euo pipefail

# 1) e2fsprogs conf: strip feature tokens unknown to AOSP-bundled mke2fs (metadata_csum_seed, orphan_file).
#    Without this every image step dies with "Invalid filesystem option set". Never symlink host binaries instead!
if grep -qE "orphan_file|metadata_csum_seed" /etc/mke2fs.conf; then
  cp -n /etc/mke2fs.conf /etc/mke2fs.conf.orig
  sed -i 's/,orphan_file//g; s/,metadata_csum_seed//g; s/metadata_csum_seed,//g' /etc/mke2fs.conf
  echo "mke2fs.conf patched (backup: /etc/mke2fs.conf.orig)"
else
  echo "mke2fs.conf already clean"
fi

# 2) old clang toolchain needs libncurses.so.5
NEEDLE=$(find "$(pwd)/prebuilts/misc/linux-x86/clang" -name 'clang.real' 2>/dev/null | head -1 || true)
if [ "${NEEDLE:-}" = "" ]; then NEEDLE=llvm_prebuilt; fi
if ! ldconfig -p | grep -q "libncurses.so.5"; then
  LIB6=$(ldconfig -p | awk '/libncurses\.so\.6/{print $NF; exit}')
  if [ -n "${LIB6:-}" ]; then
    ln -sf "$LIB6" /usr/lib/x86_64-linux-gnu/libncurses.so.5
    ln -sf "$(dirname $LIB6)/$(basename ${LIB6/ncurses/ncursesw})" /usr/lib/x86_64-linux-gnu/libncursesw.so.5 2>/dev/null || true
    echo "symlinked ncurses 6 -> 5"
  else
    echo "WARN: neither libncurses.so.5 nor .so.6 found; install libncurses6" >&2
  fi
fi

# 3) sanity
command -v repo >/dev/null || { echo "install repo first: apt-get install repo (or pip x)"; }
echo "host prep done"
