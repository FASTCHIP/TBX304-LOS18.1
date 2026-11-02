# Верификация сборки 2026-11-02 на живом TB-X304X

Все проверки — реальные прогоны adb/dumpsys на устройстве сразу после установки, не «должно работать».

## Идентичность сборки
| Поле | Значение |
|---|---|
| flavor | `lineage_TBX304-userdebug 11 RQ3A.211001.001 eng.root.20261102` test-keys |
| security patch | framework 2024-02-05, vendor 2018-10-01 |
| OTA zip | 718 620 285 B, sha256 `fc2b2a24b7bf98adae2ff469f1d6b1a922a417c06c6f7350572b6bbc49523686` (совпал при загрузке на устройство) |
| boot.img | 11 198 464 B; DTB inside: `qcom,msm8917-qrd-sku5` — идентичен stock-boot платы ✓ |

## Функциональные пробы
| Подсистема | Проверка | Результат |
|---|---|---|
| Загрузка | `sys.boot_completed`, SurfaceFlinger | 1; 61 surface, live ✓ |
| Экран | `dumpsys window displays` | 800x1280 @160dpi, родной режим ✓ |
| Тач | `getevent -pl`, инъекции input | goodix-ts, 15 MT-слотов + pen; tap/swipe проходят ✓ |
| Камеры | `dumpsys media.camera` | provider@2.4 поднят, **Number of camera devices: 2** ✓ |
| Звук | ps HAL/audio | audio.service + audioserver активны ✓ |
| Wi-Fi | svc wifi enable / dumpsys | включается, «Wi-Fi is enabled» ✓ |
| Сенсоры | `dumpsys sensorservice` | **23/23 h/w sensors running** ✓ |
| Батарея/термо | dumpsys battery, thermal-engine | телеметрия живая (level/voltage/temp), thermal running ✓ |
| /data | df | смонтирован, FBE ✓ |

## Лог-аудит (logcat ~9.5k строк с момента бутa)
- dropbox / tombstones / ANR / crash-buffer — **пусто**, ни одного FATAL/signal.
- Перезапусков system_server/оболочки нет.

Разбор E-тегов (всё известное для этой платформы):
| Тег | Объём | Диагноз |
|---|---|---|
| ANDR-PERF-TARGET/RESOURCEQS/OPTSHANDLER | ~450 строк | perf-HAL msm8917 опрашивает cluster/core id 0/1, которых на плате нет — косметика |
| mdss_dsi_ack_err_status=1008000 / fifo_status | 74+ всплеском при bring-up дисплея | в рантайме новых нет (счётчик dmesg за 3+ мин: 0). Следить при артефактах экрана → panel-timing |
| q6asm_callback payload size / Utils channel-count | ~170 | шум ADSP-аудио стека |
| FMQ grantorIdx | ~80 | noise health/power HAL на LOS 18 |
| Пропущенные кадры SF | 271 за первый бут | норма для первого старта + setup wizard |

## Что не проверялось автоматом
Телефонии у платы нет; GPS, динамики/микрофон на слух, глубокую нагрузку GPU — субъективная часть, оставляем владельцу.
