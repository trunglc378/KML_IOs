# TRACEABILITY_MATRIX — KML-iOS v4.0

| Req ID | Mo ta | File trien khai | Test Case | Trang thai | Ghi chu |
|--------|-------|-----------------|-----------|-----------|---------|
| FR-IO-NOT-01 | Gui ket qua qua Telegram Bot | core/notify/telegram_result_sender.dart | test/core/telegram_result_sender_test.dart | PARTIAL | Co code, co test, chua chay flutter test |
| FR-IO-NOT-02 | Gui dung loai noi dung | core/notify/telegram_result_sender.dart, telegram_message_builder.dart | test/core/telegram_message_builder_test.dart | DONE | Da fix bug join('\n') tai byte 5C 6E |
| FR-IO-NOT-03 | Whitelist va cau hinh dich | core/constants/telegram_config.dart, core/security/token_store.dart | test/core/telegram_config_whitelist_test.dart | DONE | Whitelist & Keychain kiem tra chat che |
| FR-IO-NOT-04 | Xu ly loi + hang doi ben vung | core/notify/telegram_dispatcher.dart, features/sync/data/telegram_queue.dart | test/core/telegram_dispatcher_test.dart, telegram_queue_test.dart | DONE | Da fix deviceId persistence + SendOutcomeMapper values |
| FR-IO-NOT-05 | Thong bao kenh gui trong /consent | features/consent/presentation/consent_screen.dart | test/widget/consent_screen_test.dart | DONE | Da wire vao app_router.dart (/consent) |
| FR-IO-DEV-01 | Thu thap device info | features/device/data/device_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/device |
| FR-IO-LOC-01 | Thu thap vi tri GPS | features/location/data/location_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao entity, repo dung geolocator, man hinh /data/location |
| FR-IO-LOC-02 | Thu thap vi tri lien tuc | features/location/data/location_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Ho tro continuousLocationStream |
| FR-IO-CON-01 | Thu thap danh ba | features/contacts/data/contacts_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/contacts |
| FR-IO-CAL-01 | Thu thap lich | features/calendar/data/calendar_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/calendar |
| FR-IO-PHO-01 | Thu thap anh | features/photos/data/photos_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/photos |
| FR-IO-CAM-01 | Thu thap camera | features/camera/data/camera_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/camera |
| FR-IO-MIC-01 | Thu thap microphone | features/microphone/data/microphone_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/microphone |
| FR-IO-SCR-01 | Thu thap screen record | features/screen/data/screen_collector_repository_impl.dart | test/features/data_collection_entities_test.dart | DONE | Da tao domain entity, repo, presentation screen /data/screen |
| FR-IO-CON-02 | Kiem tra quyen truoc khi thu thap | tat ca cac collector repositories (permission_handler) | test/features/data_collection_entities_test.dart | DONE | Check & request permission truoc khi truy cap |
| FR-IO-CON-03 | Ghi audit log moi lan truy cap | core/notify/telegram_dispatcher.dart (_writeLogs) | KHONG CO | PARTIAL | Ghi log nhung khong co test rieng, khong co SendAuditRepository |
| FR-IO-SYN-01 | Gui qua hang doi Telegram | features/sync/data/telegram_queue.dart | test/core/telegram_queue_test.dart | PARTIAL | Co code, co test |
| FR-IO-SYN-02 | Sync lai khi co mang / chay ngam | features/sync/data/background_sync_service.dart, lib/main.dart | test/features/background_sync_test.dart | DONE | Workmanager & BGTaskScheduler da duoc tich hop hoan chinh |
| FR-IO-ERR-01 | Xu ly loi toan cuc | core/errors/app_exception.dart | KHONG CO | PARTIAL | Co kieu loi nhung khong co global handler |
| NFR-IO-04 | ATS/HTTPS | ios/Runner/Info.plist | KHONG CO | DONE | Da tao Info.plist khoa NSAllowsArbitraryLoads=false |
| NFR-IO-05 | Secure storage | core/security/token_store.dart | test/core/telegram_masking_test.dart | DONE | Keychain dung |
| NFR-IO-06 | Data Protection | token_store.dart (first_unlock_this_device) | KHONG CO | PARTIAL | Code dung, chua co test |
| NFR-IO-07 | Privacy manifest | ios/Runner/PrivacyInfo.xcprivacy | KHONG CO | DONE | Da tao PrivacyInfo.xcprivacy theo chuan iOS 17+ |
| NFR-IO-11 | Domain thuan khiet | check_domain_purity.dart | test/architecture/domain_purity_test.dart | DONE | Da tao domain files; 0 vi pham tren ca 4 files |
| NFR-IO-13 | Bi mat khong lo trong log | core/security/secret_redactor.dart | test/core/telegram_masking_test.dart | DONE | SecretRedactor dung |
| NFR-IO-14 | Gui bat dong bo | telegram_dispatcher.dart (async) | KHONG CO | PARTIAL | Co code async, chua co test do do tre |
| NFR-IO-15 | Bao toan ket qua khi gui that bai | features/sync/data/telegram_queue.dart | test/core/telegram_queue_test.dart | DONE | SQLite persistent |
| NFR-IO-16 | Ton trong retry_after | telegram_dispatcher.dart (retryAfter ?? backoffFor) | test/core/telegram_dispatcher_test.dart | DONE | Dung uu tien |
| NFR-IO-17 | Chi gui dung dich | telegram_result_sender.dart (_checkConfig), telegram_config.dart (whitelist) | test/core/telegram_config_whitelist_test.dart | DONE | Whitelist check truoc moi lan gui |
| TC-IO-NOT-01 | Gui den dung chat | telegram_result_sender_test.dart | - | PARTIAL | Unit test OK, chua co integration test |
| TC-IO-NOT-02 | Chon dung phuong thuc gui | telegram_message_builder_test.dart | - | DONE | Da fix byte 5C 6E; message builder thoa man |
| TC-IO-NOT-03 | Mat mang — hang doi bao toan | telegram_queue_test.dart | - | DONE | Unit test OK & da fix integration test call |
| TC-IO-NOT-04 | Token sai | telegram_client_test.dart | - | PARTIAL | Unit test OK |
| TC-IO-NOT-05 | Rate limit thu lai | telegram_dispatcher_test.dart | - | DONE | Unit test OK, retry_after priority verified |
| TC-IO-SEC-08 | Whitelist va bao mat | telegram_config_whitelist_test.dart | - | DONE | Whitelist check truoc gui |
| TC-IO-UI-05 | Consent nen kenh Telegram | consent_screen_test.dart | - | DONE | Co widget test & da wire router |
| TC-IO-UI-06 | Settings 3 trang thai | settings_screen_test.dart | - | DONE | Co widget test |
| TC-IO-NFR-11 | Domain thuan khiet | domain_purity_test.dart | - | DONE | Da kiem tra script: 0 vi pham |
| TC-IO-NFR-13 | Bi mat khong lo log | telegram_masking_test.dart | - | DONE | Co test & check_secrets PASS |
| TC-IO-FOR-05 | Khong forensic artefact | KHONG CO | KHONG CO | MISSING | Khong co test |
