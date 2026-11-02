# LineageOS 18.1 (Android 11) for Lenovo Tab 4 10 Plus — TB-X304X / L / F

Самостоятельная сборка LOS 18.1 для планшета **Lenovo TB-X304** (Qualcomm MSM8917 / Snapdragon 410, 2GB RAM).
Прошита и проверена на живом устройстве (TB-X304X): загрузка чистая, тач/камеры/Wi-Fi/сенсоры работают, без crash'ей.

English TL;DR: working self-build of LineageOS 18.1 for the MSM8917-based Lenovo TB-X304 tablet family, with pinned forks of device/kernel/vendor trees, exact host setup notes for WSL/modern Ubuntu, and a verified flashing recipe via TWRP OpenRecoveryScript.

## Что здесь лежит

| Файл | Назначение |
|---|---|
| `local_manifests/TBX304.xml` | фрагмент repo-манифеста: наши форки с **зафиксированными commit** |
| `scripts/host-setup.sh` | подготовка хоста (Ubuntu 24.04+/WSL): e2fsprogs conf, ncurses5 |
| `scripts/build.sh` | сборка `brunch TBX304` |
| `scripts/flash-ors.sh` | прошивка через TWRP + openrecoveryscript (без тыканья в экран) |
| `VERIFICATION.md` | результаты проверки на устройстве + разбор ошибок из logcat |

## Форки и зафиксированные ревизии

Всё базируется на работе org **lenovo-msm8917** (см. Благодарности). Мы форкнули все четыре дерева к себе и закоммитили единственный необходимый фикс.

| Дерево | Наш форк | Ветка | Commit сборки 2026-11-02 |
|---|---|---|---|
| device TBX304 | FASTCHIP/android_device_lenovo_TBX304 | lineage-18.1 | `07de7fecf9f12c33175299188ba554f7189d710e` |
| tb-common | FASTCHIP/device_lenovo_tb-common | lineage-18.1-msm8937 | `3324b11f720a1e6a5ad6f5f3d2f177390e23c6ac` |
| kernel msm8917 (3.18.140) | FASTCHIP/kernel_lenovo_msm8917 | lineage-18.1 | `16b80b67263ea91dbf3db816784da020e7919acf` |
| vendor blobs | FASTCHIP/vendor_lenovo | lineage-18.1-msm8937 | `d3f7d86…` (= upstream + фикс shared_libs для `libts_face_beautify_hal`, `libts_detected_face_hal`) |

⚠ Не путать с TB-X704/msm8953 (`lenovo-devs`, `lukaspieper`): их 18.1-образы **не подходят** для X304 — DTB `qcom,msm8953` против `qcom,msm8917` у этой платы. Проверка совместимости собранного boot: найти в образе FDT-magic `d0 0d fe ed` и прочитать compatible после него.

## Сборка

Требуется дерево LineageOS 18.1:

```bash
mkdir los18.1 && cd los18.1
repo init -u https://github.com/LineageOS/android -b lineage-18.1 --git-lfs
mkdir -p .repo/local_manifests
cp <этот репо>/local_manifests/TBX304.xml .repo/local_manifests/
repo sync -c -j8 --no-tags   # НЕ прерывать первый проход: оборванный sync оставляет пустые депа
./scripts/host-setup.sh      # до первой сборки, см. ниже «ловушки хоста»
source build/envsetup.sh
brunch TBX304                # ~2–4 ч на 32 потоках; выход: out/target/product/TBX304/lineage-*.zip + boot.img
```

### Ловушки хоста (Ubuntu 24.04+/WSL) — всё уже в host-setup.sh
1. **mke2fs**: бандл AOSP читает `/etc/mke2fs.conf` дистрибутива; в свежем Ubuntu там `metadata_csum_seed,orphan_file`, которых нет в старой libext2fs → падение всех образов («Invalid filesystem option set»). Лечится вырезанием токенов из конфа, **не** подменой бинарников.
2. **libncurses.so.5**: старый clang тулчейна LOS 18 требует ncurses5 — в новых Ubuntu только 6, нужен symlink.
3. WSL: долгая сборка живёт только пока жив сам `wsl.exe`; VM в простое выключается и убивает build' — перезапуск brunch продолжает с кэшей.

## Прошивка (TWRP 3.4.0, без касания экрана)

```bash
adb push lineage-18.1-*-TBX304.zip /data/los18.zip && adb shell sha256sum /data/los18.zip   # сверить хэш!
adb reboot recovery    # TWRP
adb shell "twrp wipe data; twrp wipe cache; twrp wipe dalvik"
adb shell "echo 'install /data/los18.zip' > /cache/recovery/openrecoveryscript"
adb reboot recovery    # TWRP выполнит установку сам
# после установки устройство уходит в system; первый старт 5–10 мин
```

Свайп-варнинг: sideload через `adb sideload` на TWRP 3.4.0 для этого билда отвалился («connection failed: closed») — ORS-путь работает надёжно.

Артефакты готовой сборки (boot.img, recovery.img) — в **Releases** этого репо. Полный OTA-zip (719 МБ) превышает лимит ассетов GitHub; собирается из этого манифеста за один brunch.

## Известные особенности (не баги этой сборки)
- ~450 строк `ANDR-PERF-*` E-лога в минуту загрузки: perf-HAL msm8917 спрашивает cluster id 0/1, которых на плате нет — косметика.
- `mdss_dsi_ack_err_status status=1008000`: DSI ACK ошибки панели при bring-up дисплея; в рантайме не повторяются. При появлении артефактов на экране — править panel-timing в ядре.
- `q6asm_callback payload size`, `FMQ grantorIdx` — штатный шум ADSP-аудио/health HAL на LOS 18.
- Root по умолчанию выключен (`adb root` → Developer options → Root access).

## Дальнейший путь
У того же org есть ветки ядра **lineage-19.1 / 20.0 / 21.0** для msm8917 — Android 12–14 на этой плате технически достижимы апгрейдом стека по тем же рецептам.

## Благодарности
- org [lenovo-msm8917](https://github.com/lenovo-msm8917) — рабочие деревья device/kernel/vendor/tb-common для Tab4 msm8917
- [lenovo-devs](https://github.com/lenovo-devs), lukaspieper — более ранние порты Tab4 и исследование X304
