# TODO

Checklist for the native fork (decoder-dev/Telegram-iOS, branch ios). Status
legend: работает / частично / заглушка / не сделано / невозможно / не проверено.

- [x] 01 аудит безопасности: diff форка против TelegramMessenger/Telegram-iOS, SECURITY_REVIEW.md, LICENSE форка (чисто, см. SECURITY_REVIEW.md)
- [ ] 02 CI: зелёная sideload-ipa без изменений кода, workflow_dispatch + paths-ignore + concurrency + bazel cache, проверка ipa в CI, ссылка на ран (CI зелёный: ран 37315771258; СТОП: ждать установки через SideStore)
- [x] 03 инвентарь: FEATURES_NATIVE.md (ayu + materialgram), сверка путей из PIVOT.md, пересчёт оценки строк в DECISIONS.md (~2-4k)
- [ ] 04 peek last seen
- [ ] 05 kept-диалоги (удалённые/покинутые чаты остаются)
- [ ] 06 секретные чаты в основном списке
- [ ] 07 режим стримера (ScreenCaptureDetection)
- [ ] 08 история правок и сохранение удалённых (если неполные)
- [ ] 09 фильтры и переводчик
- [ ] 10 materialgram: темы Google Day/Dark, шрифт, пузыри без хвостиков, скругления, цветной фон ответа
- [ ] 11 materialgram: перемотка кружков, удаление >100 сообщений, экспорт, остальное из FEATURES.md
- [ ] 12 прочее из инвентаря
- [ ] 13 финал: чистый клон, зелёная сборка с нуля, проверка ipa, git log -S без секретов, FINAL_REPORT.md, ручной чек-лист, README (SideStore)
