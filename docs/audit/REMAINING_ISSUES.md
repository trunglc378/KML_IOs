# REMAINING_ISSUES — KML-iOS v4.0

Gap nao la kien truc (Architect phai quyet dinh truoc khi code),
khi nao la code (Engineer co the tu fix theo spec).

---

## NHOM 1: YEU CAU ARCHITECT QUYET DINH

### [RI-001] Pham vi thu thap du lieu (Priority: CRITICAL)

9 FR thu thap du lieu (device, location, contacts, calendar, photos, camera, mic, screen)
CHUA co bat ky code nao. Truoc khi bat dau code, can xac dinh:

1. **Pham vi chinh xac**: Thu thap truong nao, dinh dang nao, tan suat nao?
2. **Permission flow**: Thu tung quyen rieng hay mot lan? Thoi diem xin quyen?
3. **Privacy manifest**: Khai bao cac API duoc dung (Required reason APIs)
4. **App Store review**: Du an co qua review khong? (ScreenCapture la sensitive API)

**Chua co quyet dinh thi kho code dung.**

### [RI-002] Tiêu chi "done" cho deviceId (Priority: MAJOR)

Spec chua ro deviceId phai la gi:
- UIDevice.current.identifierForVendor? (thay doi sau reset app)
- UUID random, luu Keychain? (on dinh hon)
- UDID? (Apple cam lay tu iOS 7)

**Kien nghi:** Dung identifierForVendor qua MethodChannel, luu Keychain khi first run.

### [RI-003] SendOutcomeMapper.oversize (Priority: MINOR) — [✅ RESOLVED]

- **Quyet dinh & Fix:** Da doi thanh `failed_oversize` de phan biet ro voi loi server, dong thoi doi `exhausted` thanh `failed_exhausted`.
- **Trang thai:** Da fix trong `lib/core/notify/telegram_dispatcher.dart`.

### [RI-004] SendAuditRepository vs TelegramDispatcher (Priority: MAJOR)

SDS v4.0 Muc 2.3 yeu cau class SendAuditRepository rieng.
Hien thi logic ghi log nam trong TelegramDispatcher._writeLogs().
Refactor se lam tang SRP nhung tang so luong class.

**Kien nghi:** Refactor theo dung SDS — tach SendAuditRepository ra rieng.

---

## NHOM 2: KY THUAT (ENGINEER CO THE TU FIX)

### [RI-005] Gap giua Schema va Code — telegram_queue.deviceId (MAJOR) — [✅ RESOLVED]

- Schema: bang `telegram_queue` co cot `deviceId TEXT`
- Code cu: `TelegramQueue.enqueue()` INSERT khong ghi `deviceId`
- **Fix:** Da them `deviceId` vao `QueuedPacket` va `enqueue()`, luu vao SQLite va anh xa lai trong `duePackets()`. Dispatcher uu tien lay `p.deviceId ?? _deviceId`.
- **Test:** Da them ca kiem thu #9 trong `test/core/telegram_queue_test.dart`.

### [RI-006] records.join('\\\\n') bug (MAJOR) — [✅ RESOLVED]

- File: `lib/core/notify/telegram_result_sender.dart:103`
- Bug: escape kep tao literal `\n` thay vi xuong dong thuc su
- **Fix:** Da sua thanh `records.join('\n')` (byte `5C 6E`).


### [RI-007] Flutter SDK PATH (BLOCKING EVERYTHING)

Khong the verify bat ky gi neu Flutter khong trong PATH.

**Cach fix:**
`powershell
# Neu Flutter da cai dat tai vi tri nao do, them vao PATH:
 = "C:\flutter\bin"  # chinh lai duong dan
C:/Users/ACER/.gemini/antigravity-ide/bin;C:\Program Files\Common Files\Oracle\Java\javapath;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files\Git\cmd;C:\Users\ACER\AppData\Local\Programs\Python\Python313\Scripts;C:\Program Files\Docker\Docker\resources\bin;C:\Program Files\nodejs\;C:\Users\ACER\AppData\Local\Programs\Python\Python39\Scripts\;C:\Users\ACER\AppData\Local\Programs\Python\Python39\;C:\Users\ACER\AppData\Local\Programs\Python\Python313;C:\Users\ACER\AppData\Local\Microsoft\WindowsApps;C:\spark\bin;C:\Users\ACER\AppData\Local\Programs\Python\Python313\Scripts;C:\hadoop\bin;C:\spark\python;%PYTHON_PATH%;C:\spark\python\lib\py4j-0.10.9.7-src.zip;C:\Users\ACER\AppData\Local\Programs\mongosh\;C:\Users\ACER\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\ACER\AppData\Roaming\npm;C:\Users\ACER\AppData\Local\Programs\Antigravity IDE\bin;C:\Users\ACER\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin; = ";C:/Users/ACER/.gemini/antigravity-ide/bin;C:\Program Files\Common Files\Oracle\Java\javapath;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files\Git\cmd;C:\Users\ACER\AppData\Local\Programs\Python\Python313\Scripts;C:\Program Files\Docker\Docker\resources\bin;C:\Program Files\nodejs\;C:\Users\ACER\AppData\Local\Programs\Python\Python39\Scripts\;C:\Users\ACER\AppData\Local\Programs\Python\Python39\;C:\Users\ACER\AppData\Local\Programs\Python\Python313;C:\Users\ACER\AppData\Local\Microsoft\WindowsApps;C:\spark\bin;C:\Users\ACER\AppData\Local\Programs\Python\Python313\Scripts;C:\hadoop\bin;C:\spark\python;%PYTHON_PATH%;C:\spark\python\lib\py4j-0.10.9.7-src.zip;C:\Users\ACER\AppData\Local\Programs\mongosh\;C:\Users\ACER\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\ACER\AppData\Roaming\npm;C:\Users\ACER\AppData\Local\Programs\Antigravity IDE\bin;C:\Users\ACER\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin;"
# Hoac them vinh vien vao User Environment Variables
`

---

## NHOM 3: BI CHAN BOI YEU TO NGOAI

### [RI-008] iOS native build (BLOCKED by GAP-BUILD-002)

Khong co ios/ directory. Can chay:
`ash
flutter create . --platforms ios
`
Sau do cau hinh:
- ios/Runner/Info.plist: them permission strings
- ios/Runner/PrivacyInfo.xcprivacy: them privacy manifest
- ios/Podfile: cau hinh target iOS version

### [RI-009] App Store submission (BLOCKED by RI-001 + RI-008)

Chua the submit cho den khi:
1. ios/ ton tai
2. Privacy manifest day du
3. All permission descriptions trong Info.plist
4. Flutter analyze 0 issues
5. Coverage >= 80%

---

## TONG KET

| Nhom | So van de | Chiu trach nhiem |
|------|-----------|-----------------|
| Architect quyet dinh | 4 (RI-001~004) | Solution Architect |
| Engineer fix | 3 (RI-005~007) | Flutter Engineer |
| Bi chan ngoai | 2 (RI-008~009) | Toan doi |

**Khong co van de nao "khong giai quyet duoc" — chi la chua duoc giai quyet.**
