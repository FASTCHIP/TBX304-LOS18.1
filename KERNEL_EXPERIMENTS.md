# Kernel upgrade experiments (4.9 wip) — results and how to reproduce

## Verdict
Modern-kernel attempt on kernel 4.9 was **closed as not viable without board-level bring-up work**.
The tablet ships and stays on stock-based `3.18.140-perf-g16b80b67` (which is the final release of
the entire 3.18 LTS series upstream — there is nothing newer in that tree lineage).

## What was proven working
Full reproducible pipeline for a standalone modern CAF kernel against our LOS 18.1 ROM:

1. Source: `lukaspieper/android_kernel_lenovo_msm8953` branch `android-11-4.9-wip`, cloned to
   `/home/fastchip/lenovo_tab/k49`. Contains full QRD-SKU5 DTS (`msm8917-pmi8937-qrd-sku5`), which
   matches our device: stock Lenovo X304 DTB is plain "MSM8917-PMI8937 QRD SKU5" too.
2. Toolchain: AOSP prebuilt clang r383902b compiles; GNU bfd ld from `gcc-aarch64-linux-gnu` links
   (new lld refuses legacy vmlinux link: `-shared and -pie may not be used together`).
3. Build fixes needed on old trees with new clang: mass angled→quoted local includes (~151 files),
   TRACE_INCLUDE_PATH relative paths, sealing empty dirs (`obj-y += x_empty.o`), real config gate
   names from Makefiles (`CONFIG_MSMB_CAMERA` gates camera_v2), weak stub for
   `msm_isp_set_avtimer_fptr` when camera disabled, re-enable IIO for SMB1355 charger.
4. Packaging: bootimg **v0** header (magic@0, sizes/addr @8..36, tags@32=0x80000100, page 2048,
   name@48, cmdline@64) — keep all fields of reference image, swap kernel section with
   `Image.gz + dtb`. Script: see this repo history / scratch `make_boot_v3.py`.
5. Test bench method: flash experimental kernel into **recovery partition** (system untouched);
   rollback = fastboot flash saved recovery/boot image. Lenovo LK ignores `fastboot reboot-recovery`,
   use `adb reboot recovery` (misc BCB). Kernel panics pre-init land the tablet in EDL
   (`VID_05C6&PID_900E`); recover via VOL UP+POWER → fastboot.

## What failed and why (status of knowledge)
Three payloads (uncompressed Image, Image.gz+dtb via boot, same via recovery; second build had
ARM_PSCI enabled) all died within seconds of init: black screen, zero USB enumeration, device falls
to EDL emergency download. DTB parity with stock verified (same board model, same placeholder
memory node filled by LK). Remaining suspects require serial console to resolve: internal QRD debug
UART is the only way to get panic output. Community consensus (XDA "Kuntao" threads): porting
Lenovo-specific drivers to 4.9 is a large project nobody finished for this tablet.
Related longer-term option: org `msm89x7-mainline` (mainline Linux + lk2nd bootloader for
MSM8917/37/40), incomplete functionality.

## Artifacts on disk (Windows E:)
- `boot_49_tbx304.img`, `recovery_49_tbx304.img`, `recovery_49v2_tbx304.img` — experimental images (do NOT flash without understanding above).
- `boot.img`, `recovery.img` — known-good LOS 18.1 images (rollback targets).
