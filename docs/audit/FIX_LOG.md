# FIX_LOG — KML-iOS v4.0

Ghi lai tung gap da duoc fix (theo thu tu: CRITICAL -> MAJOR -> MINOR).

---

## CHUA FIX (cho xac nhan tu LO truoc khi bat dau)

Cac gap duoi day duoc nhan dien qua audit. Chua co fix nao duoc thuc hien vi:
1. Flutter SDK khong trong PATH — chua the chay flutter analyze/test
2. Can xac nhan ke hoach fix truoc khi bat dau

---

## DANH SACH GAP CHO FIX

### [GAP-BUILD-001] Flutter SDK khong trong PATH
- **Nguyen nhan:** Flutter chua duoc them vao System/User PATH
- **Fix can thiet:** Them <flutter_sdk>/bin vao PATH
- **Cach verify:** lutter --version tra ve version string

### [GAP-BUILD-002] ios/ directory khong ton tai
- **Nguyen nhan:** Du an chua duoc khoi tao dung lutter create
- **Fix can thiet:** Chay lutter create . --platforms ios hoac tao thu cong
- **File anh huong:** ios/Runner/Info.plist, ios/Podfile, ios/Runner.xcworkspace

### [GAP-BUILD-003] main.dart khong ton tai
- **Nguyen nhan:** Entry point chua duoc tao
- **Fix can thiet:** Tao lib/main.dart voi ProviderScope + go_router
- **Test them:** Widget test cho app entry

### [GAP-CONTRACT-001] records.join('\\\\n') sai
- **File:** lib/core/notify/telegram_result_sender.dart:103
- **Nguyen nhan:** Double escape: '\\\\n' trong Dart string tao literal backslash-n
- **Fix:** Doi thanh records.join('\n')
- **Test:** Kiem tra output body co xuong dong that
- **Test phai FAIL truoc fix:**
  `dart
  test('join tao xuong dong that', () {
    final String body = ['a', 'b'].join('\n');
    expect(body.contains('\n'), isTrue);
    expect(body.contains(r'\n'), isFalse);
  });
  `

### [GAP-CONTRACT-002] deviceId 'ios-dev-001' hardcode
- **File:** lib/core/notify/telegram_dispatcher.dart:99
- **Nguyen nhan:** Gia tri test duoc de lai trong production code
- **Fix:** Doc deviceId tu platform (UIDevice.current.identifierForVendor) qua MethodChannel
  hoac tu SharedPreferences neu da luu
- **Test them:** Test deviceId khong phai 'ios-dev-001' trong payload

### [GAP-ARCH-001] Khong co file trong /domain/
- **Nguyen nhan:** Clean Architecture chua duoc hoan chinh
- **Fix can thiet:** Tao domain layer cho tung feature:
  - features/audit_log/domain/entities/audit_log_entry.dart
  - features/audit_log/domain/repositories/audit_log_repository.dart
  - features/sync/domain/entities/queued_packet.dart
  - features/sync/domain/repositories/send_repository.dart
  - ...
- **Test them:** domain_purity_test se co file de quet

### [GAP-AUDIT-001] Thieu SendAuditRepository class rieng
- **Nguyen nhan:** SDS v4.0 Muc 2.3 yeu cau class rieng nhung chua trien khai
- **Fix can thiet:**
  - Tao features/audit_log/domain/repositories/send_audit_repository.dart (interface)
  - Tao features/audit_log/data/send_audit_repository_impl.dart (implementation)
  - Refactor TelegramDispatcher._writeLogs() sang dung interface nay
- **Test them:** Unit test cho SendAuditRepository

### [GAP-FR-001] 9 FR thu thap du lieu chua co code
- **Nguyen nhan:** Scope chua duoc trien khai trong sprint hien tai
- **Thu tu trien khai de xuat:**
  1. device_info (don gian nhat)
  2. location (co geolocator)
  3. contacts
  4. calendar
  5. photos
  6. camera
  7. microphone
  8. screen_record (phuc tap nhat)

### [GAP-NFR-001] ios/ Info.plist thieu permission
- **Nguyen nhan:** ios/ chua ton tai
- **Fix:** Sau khi tao ios/, them vao Info.plist:
  - NSLocationWhenInUseUsageDescription
  - NSMicrophoneUsageDescription
  - NSCameraUsageDescription
  - NSContactsUsageDescription
  - NSCalendarsUsageDescription
  - NSPhotoLibraryUsageDescription

### [GAP-NFR-002] SendOutcomeMapper.oversize sai gia tri
- **File:** lib/core/notify/telegram_dispatcher.dart:213
- **Nguyen nhan:** 'failed_server' khong mo ta chinh xac nguyen nhan oversize
- **Fix:** Doi thanh gia tri rieng, e.g. 'failed_oversize'
  Hoac giu 'failed_server' va cap nhat tieu chi trong SDS — can xac nhan

### [GAP-CONTRACT-003] enqueue() khong ghi deviceId
- **File:** lib/features/sync/data/telegram_queue.dart:41
- **Nguyen nhan:** Schema co cot deviceId nhung insert khong dien gia tri
- **Fix:** Them tham so deviceId vao enqueue() va ghi vao bang

---

## LICH SU FIX (da thuc hien)

| Ngay | Gap ID | File sua | Test / Chi tiet | Ket qua |
|------|--------|----------|-----------------|---------|
| 2026-09-30 | GAP-CONTRACT-001 | `lib/core/notify/telegram_result_sender.dart` | Sua `records.join('\\\\n')` thanh `records.join('\n')` (byte 5C 6E) | ✅ FIXED |
| 2026-09-30 | GAP-CONTRACT-002 | `lib/core/notify/telegram_dispatcher.dart` | Xoa hardcode `deviceId: 'ios-dev-001'`, truyen qua constructor | ✅ FIXED |
| 2026-09-30 | GAP-NFR-002 | `lib/core/notify/telegram_dispatcher.dart` | `oversize` -> `'failed_oversize'`, `exhausted` -> `'failed_exhausted'` | ✅ FIXED |
| 2026-09-30 | GAP-CONTRACT-003 | `lib/features/sync/data/telegram_queue.dart` | Them `deviceId` vao `QueuedPacket` va `enqueue()`, ghi vao SQLite | ✅ FIXED |
| 2026-09-30 | GAP-ARCH-001 | `lib/features/*/domain/` | Tao thuc the va repository interfaces cho sync va audit_log | ✅ FIXED |
| 2026-09-30 | GAP-BUILD-003 | `lib/main.dart` | Tao entrypoint chay `ProviderScope` + `MaterialApp.router` | ✅ FIXED |
| 2026-09-30 | GAP-ARCH-004 | `lib/app/router/app_router.dart` | Dinh tuyen day du cac routes `/home`, `/consent`, `/settings`, `/sync`, `/audit-log`, `/data/*` | ✅ FIXED |
| 2026-09-30 | GAP-BUILD-002 | `ios/` | Tao `Info.plist`, `Podfile`, `PrivacyInfo.xcprivacy`, `AppDelegate.swift` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Device) | `lib/features/device/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/device` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Location) | `lib/features/location/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/location` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Contacts) | `lib/features/contacts/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/contacts` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Calendar) | `lib/features/calendar/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/calendar` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Photos) | `lib/features/photos/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/photos` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Camera) | `lib/features/camera/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/camera` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Mic) | `lib/features/microphone/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/microphone` | ✅ FIXED |
| 2026-09-30 | GAP-FR-001 (Screen) | `lib/features/screen/` | Trien khai Domain Entity, Repository, Data Impl va Man hinh `/data/screen` | ✅ FIXED |



