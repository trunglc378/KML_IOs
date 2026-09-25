# PROMPT GIAO VIỆC CHO AI LẬP TRÌNH — KML-iOS v4.0 (kênh gửi kết quả Telegram)

> **Cách dùng:** dán toàn bộ nội dung dưới đây vào AI lập trình, kèm 5 tài liệu dự án
> (01-Tài-liệu-Giới-thiệu, 02-PMP, 03-SRS v4.0, 04-SDS v4.0, 05-Tài-liệu-Kiểm-thử v4.0).
> Prompt này không thay thế tài liệu — nó là chỉ dẫn thi hành cho tài liệu.

---

## 0. VAI TRÒ VÀ NHIỆM VỤ

Bạn là kỹ sư Flutter chính của nhánh iOS trong dự án KML (Hệ thống KML — nhánh iOS,
đồ án tốt nghiệp, người hướng dẫn: Phạm Đức Thắng — Đại học FPT).

Nhiệm vụ: hiện thực ứng dụng iOS bằng **Dart + Flutter** theo đúng **KML-SDS-001 v4.0**,
thoả mãn **KML-SRS-001 v4.0**, và phải vượt được bộ ca kiểm thử trong
**KML-TEST-001 v4.0**.

Điểm khác biệt của v4.0 so với v3.0: **kênh nhận kết quả đổi từ Backend + Web Dashboard
sang Telegram Bot**. Kênh web bị thay thế hoàn toàn, không chạy song song, không fallback.

---

## 1. RÀNG BUỘC BẤT KHẢ XÂM PHẠM (đọc trước khi viết bất kỳ dòng code nào)

Đây là các ràng buộc định hình toàn bộ dự án. Vi phạm một mục nào là hỏng cả sản phẩm.

1. **Chỉ dùng public API và permission của iOS.** Không tạo, không giả định, không
   "thử xem có được không" bất kỳ khả năng vượt sandbox nào.
2. **Danh sách "không thể làm" — tuyệt đối không hiện thực, không mô phỏng, không
   tạo API giả cho các việc sau:**
   - Đọc toàn bộ SMS/iMessage
   - Đọc database WhatsApp/Zalo/Signal/Telegram của ứng dụng khác
   - Dump Keychain của ứng dụng khác
   - Đọc filesystem toàn hệ thống
   - Ghi âm cuộc gọi do ứng dụng khác thực hiện
   - Keylogger toàn hệ thống
   - Chạy daemon toàn quyền liên tục
3. **Không viết code tấn công.** Không exploit chain, không implant, không C2, không
   kỹ thuật persistence. Nội dung spyware trong tài liệu là **phân tích phòng thủ** —
   chỉ dùng để đối chiếu capability, không để tái tạo.
4. **Bot token và chat_id không bao giờ hard-code.** Không trong source, không trong
   test, không trong file cấu hình được Git theo dõi.
5. **Token và chat_id không bao giờ xuất hiện trong log** — kể cả log debug, kể cả
   trong thông báo lỗi, kể cả trong URL.
6. **Mọi kết nối ra ngoài đều qua HTTPS/TLS.** Không nới lỏng ATS, không thêm ngoại lệ.
7. **Không dùng package bọc Telegram Bot API của bên thứ ba.** Tự viết client cho bốn
   phương thức cần dùng (lý do ở SDS v4.0 Mục 4.1).
8. **Tầng Domain không được import lớp gửi kết quả.** Đây là ràng buộc kiểm tra được
   bằng rà soát import, và có ca kiểm thử riêng (TC-IO-NFR-11).

---

## 2. KẾT QUẢ CẦN BÀN GIAO

| # | Sản phẩm | Ghi chú |
|---|----------|---------|
| 1 | Mã nguồn Flutter cho iOS | Chạy được trên thiết bị thật |
| 2 | Cấu hình môi trường dev/staging/prod | Kèm file mẫu, không chứa bí mật thật |
| 3 | Bộ unit test cho lớp gửi | Chạy không cần thiết bị |
| 4 | Bộ integration test | Có ca gửi thật tới chat test |
| 5 | Script kiểm tra bí mật trong repo | Dùng cho TC-IO-SEC-08 |
| 6 | README cấu hình bot | Các bước tạo bot, lấy chat_id, nạp cấu hình |

---

## 3. KIẾN TRÚC — BẮT BUỘC THEO (SDS v4.0 Mục 2)

### 3.1 Kiến trúc ba tầng, feature-first

```
┌──────────────────────────────────────────────┐
│ PRESENTATION                                 │
│ Screens · Widgets · Riverpod Providers       │
│ go_router điều hướng                         │
└───────────────┬──────────────────────────────┘
                │ (đọc/ghi trạng thái)
┌───────────────▼──────────────────────────────┐
│ DOMAIN                                       │
│ Entities · UseCases · Repository interfaces  │
└───────────────┬──────────────────────────────┘
                │ (triển khai)
┌───────────────▼──────────────────────────────┐
│ DATA                                         │
│ DTO · Repository impl · Local (cache)        │
│ Remote (dio) · Secure storage                │
│ + TelegramResultSender  ← MỚI v4.0           │
└──────────────────────────────────────────────┘
```

**Trách nhiệm từng tầng (SDS v4.0 Mục 2.2):**

| Tầng | Thành phần | Trách nhiệm |
|------|-----------|-------------|
| Presentation | Screens, Widgets, Providers/Blocs, go_router | Hiển thị, điều hướng, tiếp nhận tương tác |
| Domain | Entities, UseCases, Repository interface | Nghiệp vụ thuần, không phụ thuộc nền tảng |
| Data | DTO, Repository impl, Local, Remote, Secure storage | Truy cập dữ liệu, cache, gọi API, lưu bí mật |
| Native bridge | MethodChannel / EventChannel | Gọi chức năng native iOS khi cần |

### 3.2 Luồng phụ thuộc (hiện thực đúng thứ tự này)

1. Presentation (Provider/Bloc) gọi UseCase ở tầng Domain.
2. UseCase gọi Repository interface — **không biết gì về Telegram hay HTTP**.
3. Repository impl ở tầng Data ghi vào local cache, rồi đẩy gói kết quả vào TelegramQueue.
4. Result dispatcher (chạy nền) đọc TelegramQueue, gọi TelegramResultSender.
5. TelegramResultSender dùng TelegramClient và TokenStore, rồi ghi kết quả vào
   SendAuditRepository.

### 3.3 Cấu trúc thư mục (SDS v4.0 Mục 5.1)

```
lib/
├── main.dart
├── app/
│   ├── router/            # go_router
│   └── theme/
├── core/
│   ├── constants/         # + telegram_config.dart        ← MỚI
│   ├── errors/
│   ├── network/           # dio client, interceptors
│   │                      # + telegram_client.dart        ← MỚI
│   ├── notify/            # KÊNH GỬI KẾT QUẢ              ← MỚI
│   │   ├── telegram_result_sender.dart
│   │   ├── telegram_message_builder.dart
│   │   └── send_result.dart          # kiểu kết quả gửi
│   ├── security/          # + token_store.dart            ← MỚI
│   ├── permissions/       # permission_handler wrapper
│   ├── logging/           # audit log
│   └── platform/          # MethodChannel wrappers
├── features/
│   ├── onboarding/  consent/  device_info/  location/
│   ├── contacts/  calendar/  photos/  camera/  microphone/
│   ├── screen_record/  keyboard/  audit_log/
│   └── sync/              # + telegram_queue.dart         ← MỚI
└── shared/
    ├── widgets/
    └── utils/
```

Mỗi feature gồm ba thư mục con: `presentation/`, `domain/`, `data/`.

### 3.4 Thành phần mới của v4.0 (SDS v4.0 Mục 2.3)

| Thành phần | Vị trí | Trách nhiệm |
|-----------|--------|-------------|
| `telegram_client.dart` | core/network/ | Client dio gọi Bot API: base URL, timeout, interceptor, chuẩn hoá lỗi |
| `TelegramResultSender` | core/notify/ | Điều phối gửi: chọn phương thức, đóng gói, chia phần, xử lý kết quả |
| `TelegramMessageBuilder` | core/notify/ | Dựng phần đầu tin nhắn, escape ký tự, chia phần theo ranh giới bản ghi |
| `TelegramConfig` | core/constants/ | Đọc bot token, chat_id, timeout, số lần thử theo môi trường |
| `TelegramQueue` | features/sync/data/ | Hàng đợi bền vững các gói kết quả chưa gửi thành công |
| `TokenStore` | core/security/ | Đọc/ghi bot token và chat_id qua flutter_secure_storage |
| `SendAuditRepository` | features/audit_log/data/ | Ghi bản ghi nhật ký mỗi lần gửi vào audit_log |

**Lý do đặt `core/notify/` chứ không trong `features/`:** nhiều feature đều cần gửi kết
quả (device_info, location, contacts, calendar, photos, screen_record). Đặt ở core giữ
nguyên tắc feature-first mà không buộc các feature phụ thuộc lẫn nhau.

---

## 4. PACKAGE — CHỈ DÙNG NHỮNG THỨ NÀY (SDS v4.0 Mục 4)

| Mục đích | Package | Ghi chú |
|----------|---------|---------|
| Định vị | `geolocator` | CLLocationManager bên dưới |
| Quyền | `permission_handler` | Xin và kiểm tra trạng thái quyền |
| Lưu cấu hình nhẹ | `shared_preferences` | Cấu hình **không nhạy cảm** |
| CSDL local | `sqflite` | Cache dữ liệu và offline queue |
| HTTP | `dio` | Interceptors, retry |
| Lưu dữ liệu nhạy cảm | `flutter_secure_storage` | Keychain của chính app |
| Tác vụ nền | `workmanager` | Có giới hạn bởi iOS |
| Native bridge | MethodChannel / EventChannel | Chỉ khi cần |
| State management | `flutter_riverpod` | |
| Điều hướng | `go_router` | |

**Quy tắc package bắt buộc:**
- Không thêm package HTTP mới — dùng lại `dio` với một client riêng.
- Gửi tệp dùng `dio` + `FormData`; KHÔNG cần package multipart.
- KHÔNG dùng package bọc Bot API của bên thứ ba.
- Định dạng thời gian dùng `dayjs` nếu đã có; không thêm package mới.
- Kiểm tra kích thước/loại tệp nằm trong `TelegramResultSender`, không cần package.

---

## 5. STATE MANAGEMENT VÀ ĐIỀU HƯỚNG (SDS v4.0 Mục 3)

### 5.1 Riverpod (đề xuất chính, đã chốt)

### 5.2 Provider phải có

| Provider | Loại | Trạng thái |
|----------|------|-----------|
| `telegramConfigProvider` | Provider | Cấu hình đọc được từ cấu hình môi trường và secure storage |
| `telegramClientProvider` | Provider | Instance client dio đã cấu hình base URL và timeout |
| `resultSenderProvider` | Provider | Instance TelegramResultSender |
| `sendQueueProvider` | StreamProvider | Số gói đang chờ gửi, cho màn hình /sync |
| `botStatusProvider` | **AsyncNotifier** | Trạng thái cấu hình bot: đã cấu hình / chưa cấu hình / không hợp lệ |
| `auditLogProvider` | StreamProvider | Danh sách bản ghi gửi cho màn hình /audit-log |

**Lưu ý:** `botStatusProvider` phải là `AsyncNotifier`, KHÔNG dùng `FutureProvider` —
vì trạng thái cần cập nhật lại sau khi người dùng thay đổi cấu hình.

### 5.3 Route (không thêm route mới — chỉ bổ sung nội dung)

```
/onboarding     — Giới thiệu và mục đích thu thập (bắt buộc lần chạy đầu)
/consent        — Giải thích quyền trước khi xin quyền  [BỔ SUNG: nội dung kênh gửi]
/home           — Trang chính
/data/device, /data/location, /data/contacts, /data/calendar,
/data/photos, /data/camera, /data/microphone, /data/screen
/settings       — Cấu hình  [BỔ SUNG: mục Kênh gửi kết quả + nút kiểm tra bot]
/audit-log      — Nhật ký truy cập dữ liệu  [BỔ SUNG: bản ghi gửi]
```

---

## 6. HIỆN THỰC KÊNH GỬI — PHẦN CỐT LÕI

### 6.1 Luồng dữ liệu (SDS v4.0 Mục 6.1)

```
Thu thập (theo permission)
        ↓
Chuẩn hoá DTO (kèm platform = "ios", deviceId)
        ↓
Ghi vào local cache + offline queue
        ↓
Gói kết quả hoàn tất → đẩy vào telegram_queue
        ↓
Result dispatcher: đọc queue → TelegramResultSender
        ↓
Kiểm tra cấu hình: token hợp lệ? chat_id trong whitelist?
        ↓
TelegramMessageBuilder: dựng phần đầu, chia phần nếu cần
        ↓
telegram_client → Bot API (HTTPS/TLS)
        ↓
Thành công (ok:true) → ghi audit_log + send_log, xoá khỏi queue
Thất bại             → tăng attempts, giữ lại, retry theo backoff
        ↓
Tin nhắn / tệp đến chat Telegram đã whitelist
```

### 6.2 Quy tắc xử lý dữ liệu (SDS v4.0 Mục 6.2) — hiện thực đủ 8 quy tắc

1. Mọi bản ghi phải gắn `platform = "ios"` và `deviceId`, cả trong nội dung gửi đi lẫn trong bản ghi local.
2. Chỉ gửi dữ liệu thu được khi quyền còn hiệu lực **tại thời điểm thu thập**.
3. Nếu quyền bị thu hồi: ngừng thu thập, ngừng gửi dữ liệu mới, ghi nhật ký sự kiện.
4. Không gửi dữ liệu thuộc danh sách "không thể làm".
5. Gửi **bất đồng bộ**: không chặn luồng UI, không làm chậm tác vụ thu thập.
6. Mỗi gói kết quả chỉ gửi đến **đúng một** chat đích cố định.
7. Gửi theo **gói hoàn tất**, không gửi theo từng bước.
8. Cấu hình chưa hợp lệ → **giữ kết quả trong queue, không gửi**. Thà chậm còn hơn gửi sai đích.

### 6.3 Định nghĩa "gói kết quả hoàn tất" — BẮT BUỘC hiện thực đúng

Một gói được coi là hoàn tất khi thoả **cả ba** điều kiện:

1. Phiên thu thập cho loại dữ liệu đó đã kết thúc (người dùng dừng, hoặc tác vụ tự kết thúc).
2. Toàn bộ bản ghi của phiên đã được chuẩn hoá DTO và ghi xong vào local cache.
3. Không còn bản ghi nào của phiên đang chờ ghi (đã flush xong).

Với dữ liệu dạng luồng liên tục (ví dụ vị trí), gói được chốt theo **một trong hai**
điều kiện, tuỳ cấu hình: đạt ngưỡng số bản ghi, hoặc đạt ngưỡng thời gian kể từ lần
chốt trước. Cả hai ngưỡng nằm trong `telegram_config.dart`.

### 6.4 Chọn phương thức gửi (SDS v4.0 Mục 6.4) — quy tắc quyết định bắt buộc

| Loại kết quả | Điều kiện | Phương thức | Xử lý kèm theo |
|--------------|-----------|-------------|----------------|
| Văn bản ngắn | ≤ 4096 ký tự | `sendMessage` | `parse_mode` HTML; escape ký tự đặc biệt |
| Văn bản dài | > 4096 ký tự | `sendDocument` | Đóng gói .txt/.json rồi gửi tệp |
| Dữ liệu có cấu trúc | JSON/CSV bất kỳ | `sendDocument` | Đính kèm tệp, không nhúng vào tin nhắn |
| Ảnh chụp màn hình | ≤ 10 MB | `sendPhoto` | Kiểm tra kích thước trước khi gửi |
| Ảnh lớn | > 10 MB | `sendDocument` | Gửi như tệp để tránh bị nén |
| Tệp dữ liệu | ≤ 50 MB | `sendDocument` | Đính kèm trực tiếp |
| Tệp vượt giới hạn | > 50 MB | `sendDocument` | Chia thành nhiều phần, ghi rõ chỉ số phần |

**Giới hạn kỹ thuật phải kiểm tra trước khi gửi:** 4096 ký tự / tin nhắn văn bản,
50 MB / tệp gửi lên.

**Quy tắc chia phần:** chia theo **ranh giới bản ghi** — KHÔNG cắt giữa một bản ghi —
và ghi chỉ số phần ở đầu mỗi tin nhắn, dạng `[Phần 2/5]`.

### 6.5 Cấu trúc tin nhắn (SDS v4.0 Mục 6.5) — bốn phần cố định theo thứ tự

1. **Dòng định danh:** platform, deviceId và mã phiên.
2. **Dòng thời gian:** thời điểm thu thập ISO 8601 UTC và thời điểm gửi.
3. **Dòng tổng quan:** loại dữ liệu, số bản ghi trong gói, chỉ số phần nếu có.
4. **Phần thân:** nội dung kết quả, hoặc tham chiếu tệp đính kèm khi vượt ngưỡng văn bản.

Mẫu đầu tin nhắn (đã escape cho parse_mode HTML):

```
KML-iOS · platform=ios · deviceId=ios-dev-001
Phiên: SES-20260925-0042
Thu thập: 2026-09-25T08:00:00Z · Gửi: 2026-09-25T08:00:07Z
Loại: location · Số bản ghi: 12
──────────────
lat=21.0285 lon=105.8542 acc=10 alt=12.5
speed=0.0 bearing=180.0 at=2026-09-25T08:00:00Z
...
```

Với kết quả dạng tệp, phần thân chỉ gồm dòng định danh, thời gian, tổng quan và tên tệp;
dữ liệu nằm trong tệp đính kèm. Cách này giữ phần văn bản luôn ngắn.

### 6.6 Cấu hình theo môi trường (SDS v4.0 Mục 3.5 / 6.6)

| Tham số | dev | staging | prod | Nơi lưu |
|---------|-----|---------|------|---------|
| `BOT_TOKEN` | bot test | bot test | bot thật | `flutter_secure_storage` |
| `CHAT_ID` | chat cá nhân | chat nhóm test | chat đích thật | Secure storage + whitelist |
| `API_BASE` | https://api.telegram.org | https://api.telegram.org | https://api.telegram.org | Hằng số trong code |
| `TIMEOUT` | 15 giây | 15 giây | 30 giây | `telegram_config.dart` |
| `MAX_RETRY` | 3 lần | 3 lần | 5 lần | `telegram_config.dart` |
| `BACKOFF_BASE` | 1 giây | 1 giây | 2 giây | `telegram_config.dart` |
| `PACK_THRESHOLD` | 10 bản ghi | 10 bản ghi | 50 bản ghi | `telegram_config.dart` |
| `PACK_MAX_AGE` | 60 giây | 60 giây | 300 giây | `telegram_config.dart` |

---

## 7. TELEGRAM BOT API CLIENT (SDS v4.0 Mục 8)

### 7.1 Endpoint — chỉ bốn phương thức này

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/bot<token>/sendMessage` | Gửi tin nhắn văn bản |
| POST | `/bot<token>/sendDocument` | Gửi tệp đính kèm |
| POST | `/bot<token>/sendPhoto` | Gửi ảnh |
| GET | `/bot<token>/getMe` | Kiểm tra bot token hợp lệ |

**Bắt buộc:** client là một **instance dio riêng**, KHÔNG dùng chung với client gọi dịch
vụ khác — base URL khác, timeout khác, và interceptor phải che token trong log. Dùng
chung client sẽ dễ dẫn tới việc interceptor ghi log URL đầy đủ và làm lộ token.

### 7.2 Cấu hình client

| Tham số | Giá trị | Ghi chú |
|---------|---------|---------|
| `baseUrl` | `https://api.telegram.org` | Hằng số, không đổi theo môi trường |
| `connectTimeout` | 10 giây | |
| `receiveTimeout` | 30 giây | Gửi tệp cần lâu hơn gửi văn bản |
| `sendTimeout` | 60 giây | Áp dụng cho `sendDocument` và `sendPhoto` |
| `validateStatus` | luôn trả về `true` | Tự kiểm tra mã trạng thái để thống nhất xử lý lỗi |

### 7.3 Xử lý phản hồi — bốn quy tắc bắt buộc

Phản hồi có dạng `{ ok: boolean, result: {...} }` khi thành công, hoặc
`{ ok: false, error_code: number, description: string }` khi lỗi.

1. **Kiểm tra trường `ok`** trước khi coi là thành công — Bot API trả HTTP 200 kèm
   `ok:false` cho một số lỗi logic. Chỉ nhìn mã HTTP là KHÔNG đủ.
2. **Chuẩn hoá lỗi** thành một kiểu nội bộ thống nhất (`SendResult`) trước khi chuyển lên lớp gọi.
3. **Khi bị giới hạn tần suất**, đọc `retry_after` từ tham số của phản hồi — đây là thời
   gian chờ bắt buộc, **ưu tiên hơn backoff mặc định**.
4. **Không ghi nguyên văn thân phản hồi vào log** khi có nguy cơ chứa token.

### 7.4 Kiểu `SendResult` — sáu trạng thái bắt buộc (SDS v4.0 Mục 8.5)

| Trạng thái | Điều kiện | Hành vi của dispatcher |
|-----------|-----------|----------------------|
| `success` | `ok:true` | Ghi `audit_log` + `send_log`; xoá gói khỏi queue; xoá tệp tạm |
| `retryable` | Lỗi mạng, timeout, HTTP 5xx, HTTP 429 | Tăng `attempts`; đặt `nextAttemptAt` theo backoff hoặc `retry_after`; giữ trong queue |
| `fatal_auth` | HTTP 401, `ok:false` do token sai hoặc bị thu hồi | Dừng gửi; đánh dấu cấu hình không hợp lệ; giữ trong queue; **không thử lại** |
| `fatal_config` | HTTP 400, chat_id sai, chat chưa start bot | Dừng gửi; báo cấu hình không hợp lệ; giữ trong queue; **không thử lại** |
| `blocked` | chat_id ngoài whitelist | Chặn ngay tại chỗ; ghi cảnh báo; **không phát sinh request ra ngoài** |
| `oversize` | Tệp vượt 50 MB sau khi chia | Bỏ gói; ghi `audit_log` mức lỗi; thông báo cho người dùng |

---

## 8. CSDL LOCAL (SDS v4.0 Mục 7)

### 8.1 Quy tắc lưu trữ

- Dữ liệu nhạy cảm (token, khoá) lưu bằng `flutter_secure_storage`, **không** trong SQLite thường.
- Bản ghi đã gửi được giữ tối thiểu theo cấu hình rồi dọn định kỳ.
- `audit_log` **không tự xoá sớm** vì phục vụ kiểm toán.
- Không lưu bí mật của ứng dụng khác — app không có khả năng truy cập chúng.

### 8.2 Bảng dữ liệu

| Bảng | Trường chính | Mục đích |
|------|--------------|----------|
| `device_info` | id, osVersion, model, networkType, collectedAt, **sent** | Thông tin thiết bị/mạng |
| `locations` | id, latitude, longitude, accuracy, altitude, speed, bearing, collectedAt, **sent** | Mẫu vị trí |
| `contacts` | id, name, phone, email, collectedAt, **sent** | Danh bạ |
| `calendar_events` | id, title, startAt, endAt, collectedAt, **sent** | Sự kiện lịch |
| `audit_log` | id, action, target, result, at, platform | Nhật ký truy cập, phục vụ kiểm toán |
| `telegram_queue` | xem 8.3 | Hàng đợi gói kết quả chờ gửi ← MỚI |
| `send_log` | xem 8.4 | Bản ghi riêng cho mỗi lần gửi ← MỚI |

**Lưu ý đổi tên:** trường `synced` của v3.0 đổi thành **`sent`** ở v4.0, vì đích gửi
không còn là server đồng bộ. Các trường còn lại giữ nguyên.

### 8.3 Bảng `telegram_queue` — bảng quyết định độ bền của kênh gửi

Mỗi dòng là **một gói kết quả chờ gửi**, KHÔNG phải một tin nhắn. Một gói có thể sinh
nhiều tin nhắn khi phải chia phần, và **gói chỉ được xoá khi toàn bộ các phần đã gửi
thành công**.

| Cột | Kiểu | Ý nghĩa |
|-----|------|---------|
| `id` | INTEGER PK | Khoá chính tự tăng |
| `sessionId` | TEXT | Mã phiên thu thập, dùng để truy vết và chống gửi trùng |
| `payloadKind` | TEXT | `device_info` \| `location` \| `contacts` \| `calendar` \| `photo` \| `screen` |
| `payloadPath` | TEXT | Đường dẫn tệp tạm chứa nội dung đã đóng gói |
| `recordCount` | INTEGER | Số bản ghi trong gói, dùng cho dòng tổng quan |
| `attempts` | INTEGER | Số lần đã thử gửi |
| `lastError` | TEXT | Thông báo lỗi lần thử gần nhất, **đã lọc bí mật** |
| `createdAt` | TEXT | Thời điểm gói vào queue, ISO 8601 UTC |
| `nextAttemptAt` | TEXT | Thời điểm sớm nhất được thử lại, ISO 8601 UTC |

**Chỉ mục bắt buộc:**
- Index trên `nextAttemptAt` — để dispatcher lấy nhanh các gói đến hạn.
- **Unique index trên `(sessionId, payloadKind)`** — để chống đẩy trùng một gói vào queue.
- `payloadPath` trỏ tới tệp tạm; tệp được **xoá** khi gói gửi thành công hoặc bị bỏ.

### 8.4 Bảng `send_log`

| Cột | Kiểu | Ý nghĩa |
|-----|------|---------|
| `id` | INTEGER PK | Khoá chính tự tăng |
| `sessionId` | TEXT | Mã phiên, nối với `telegram_queue` để truy vết |
| `method` | TEXT | `sendMessage` \| `sendDocument` \| `sendPhoto` |
| `chatIdSuffix` | TEXT | **Bốn ký tự cuối** của chat_id — đủ để đối chiếu mà không lộ đầy đủ |
| `attempts` | INTEGER | Số lần thử cho lần gửi này |
| `outcome` | TEXT | `success` \| `failed_network` \| `failed_auth` \| `failed_server` \| `failed_rate_limit` \| `blocked_whitelist` |
| `sentAt` | TEXT | Thời điểm kết thúc lần gửi, ISO 8601 UTC |

`send_log` là **nguồn tra cứu duy nhất** sau khi đổi kênh: vì không còn Dashboard, màn
hình `/audit-log` phải đọc được đủ thông tin để trả lời câu hỏi "gói nào đã được gửi,
lúc nào, mấy lần, và kết quả cuối ra sao".

---

## 9. XỬ LÝ LỖI VÀ ĐỘ TIN CẬY (SDS v4.0 Mục 12)

### 9.1 Ma trận xử lý lỗi — hiện thực đủ 10 tình huống

| Tình huống | Phát hiện | Hành vi thiết kế |
|-----------|-----------|-----------------|
| Mất mạng | Lỗi socket / timeout | Giữ gói trong queue; thử lại khi có mạng |
| HTTP 400 | `ok:false`, tham số sai | Không thử lại; ghi log; báo cấu hình sai |
| HTTP 401 | Bot token sai hoặc bị thu hồi | Dừng gửi; yêu cầu cập nhật token; không thử lại |
| HTTP 403 | Bot không có quyền gửi tới chat | Không thử lại; báo kiểm tra quyền của bot trong chat |
| HTTP 429 | `retry_after` trong phản hồi | Chờ đúng số giây trong `retry_after` rồi gửi lại |
| HTTP 5xx | Lỗi phía Telegram | Thử lại theo backoff luỹ tiến, có giới hạn |
| Tệp quá lớn | Vượt 50 MB | Chia nhỏ tệp; nếu vẫn vượt thì bỏ gói và ghi log lỗi |
| Văn bản quá dài | Vượt 4096 ký tự | Chuyển sang gửi tệp hoặc chia phần có đánh số |
| chat_id ngoài whitelist | Kiểm tra cấu hình nội bộ | Chặn gửi; ghi log mức cảnh báo |
| Chat chưa start bot | `ok:false`, "chat not found" | Không thử lại; báo người dùng mở bot và nhấn start |

### 9.2 Cơ chế thử lại và hàng đợi

- Retry theo **backoff luỹ tiến** với giới hạn số lần theo cấu hình — **tránh vòng lặp vô hạn**.
- Với HTTP 429, thời gian chờ do `retry_after` quyết định và **luôn được ưu tiên hơn** backoff mặc định.
- Hàng đợi **bền vững** qua lần đóng/mở ứng dụng; gói chưa gửi không bị mất.
- Gói gửi thành công được xoá khỏi queue; bản ghi đã gửi được giữ tối thiểu theo cấu hình rồi dọn định kỳ.
- **Không gửi khi cấu hình chưa hợp lệ.**
- Gói bị **lỗi vĩnh viễn** (oversize, dữ liệu hỏng) được đánh dấu và đưa ra khỏi vòng thử,
  để **không chặn các gói phía sau**.

### 9.3 Bảo mật và quyền riêng tư — tám yêu cầu

| Yêu cầu | Thiết kế | Truy vết |
|---------|----------|----------|
| Token không lộ trong log | Không log URL tuyệt đối; che token dạng `***:<secret>` | NFR-IO-13 |
| chat_id không lộ đầy đủ | Chỉ ghi 4 ký tự cuối khi cần đối chiếu | NFR-IO-13 |
| Lưu bí mật an toàn | `flutter_secure_storage` / Keychain của app | NFR-IO-05 |
| Không commit bí mật | Token nạp từ cấu hình môi trường khi build | NFR-IO-13 |
| Truyền tải mã hoá | Toàn bộ kết nối Bot API qua HTTPS/TLS | NFR-IO-04 |
| Gửi đúng đích | Đối chiếu chat_id với whitelist **trước mỗi lần gửi** | FR-IO-NOT-03 |
| Audit gửi kết quả | Mỗi lần gửi có bản ghi hành động, kết quả, thời điểm | FR-IO-CON-03 |
| Tệp tạm được dọn | Xoá tệp đóng gói sau khi gửi xong hoặc khi bỏ gói | NFR-IO-15 |

### 9.4 Ghi log và telemetry

- Mỗi lần gửi ghi vào `send_log`: mã phiên, phương thức, 4 ký tự cuối chat_id, số lần thử, kết quả cuối, thời điểm.
- Mỗi lần gửi cũng ghi một bản ghi vào `audit_log` để `/audit-log` hiển thị chung với sự kiện truy cập khác.
- Đơn vị thời gian dùng **ISO 8601 UTC**, thống nhất với DTO.
- `audit_log` không tự xoá sớm vì phục vụ kiểm toán.

---

## 10. HÀNH VI KHI iOS SUSPEND/TERMINATE (SDS v4.0 Mục 9)

iOS giới hạn nghiêm ngặt việc chạy nền. **Thiết kế chấp nhận điều đó thay vì chống lại nó.**

| Tình huống | Hành vi iOS | Thiết kế xử lý |
|-----------|-------------|----------------|
| App vào background | Bị suspend sau thời gian ngắn | Hoàn tất ghi local; lưu queue; dừng tác vụ dài |
| App bị terminate | Tiến trình bị kết thúc | Queue đã bền trong SQLite; lần mở sau đọc lại và gửi tiếp |
| Tác vụ nền bị giới hạn | Không được chạy vô hạn | Dùng `workmanager` trong ngưỡng iOS cho phép |
| Thiết bị khoá | Ảnh hưởng Data Protection class | Chọn class phù hợp; không giả định luôn truy cập được |
| Mất mạng khi gửi | Yêu cầu thất bại | Gói ở lại queue; thử lại theo backoff khi có mạng |
| Bot token không hợp lệ | HTTP 401 | Dừng gửi; yêu cầu cập nhật token; giữ gói trong queue |
| Người dùng thu hồi quyền | Thu thập dừng | Ngừng gửi dữ liệu mới; ghi nhật ký sự kiện |

**Giả định thiết kế bắt buộc ghi nhận trong code comment:** iOS không cho phép gửi mạng
đáng tin cậy khi app ở nền. Phần lớn việc gửi diễn ra khi app đang mở hoặc vừa được mở
lại. Hàng đợi là cơ chế **bảo đảm** chứ không phải phương tiện để chạy nền liên tục.
Đây là giới hạn của nền tảng, không phải khiếm khuyết của thiết kế.

---

## 11. CẤU HÌNH iOS (SDS v4.0 Mục 10)

### 11.1 Info.plist — usage description (đủ và đúng)

| Khoá | Mục đích |
|------|----------|
| `NSLocationWhenInUseUsageDescription` | Giải thích vì sao cần vị trí khi đang dùng |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Chỉ khai báo **khi thực sự dùng** |
| `NSMicrophoneUsageDescription` | Giải thích vì sao cần microphone |
| `NSCameraUsageDescription` | Giải thích vì sao cần camera |
| `NSContactsUsageDescription` | Giải thích vì sao cần danh bạ |
| `NSCalendarsUsageDescription` | Giải thích vì sao cần lịch |
| `NSPhotoLibraryUsageDescription` | Giải thích vì sao cần thư viện ảnh |

**Mọi usage description phải phản ánh đúng mục đích sử dụng thực tế.** Mô tả chung
chung hoặc gây hiểu nhầm là nguyên nhân phổ biến bị App Store Review từ chối.

### 11.2 Privacy manifest và ATS — bổ sung v4.0

- Khai báo privacy manifest cho các loại dữ liệu thu thập và mục đích sử dụng.
- **Khai báo dữ liệu được chia sẻ với bên thứ ba (Telegram)** — đây là thay đổi mới của v4.0.
- ATS bật mặc định: HTTPS/TLS cho mọi kết nối, kể cả `api.telegram.org`. **Không nới lỏng ngoại lệ.**
- Tuân thủ Data Protection cho dữ liệu lưu cục bộ.
- **Không** khai báo tracking — dữ liệu không dùng cho mục đích quảng cáo.

### 11.3 Scheme và build flavor

| Flavor | Mục đích | Signing | Phân phối | Cấu hình bot |
|--------|----------|---------|-----------|--------------|
| `dev` | Phát triển hằng ngày | Development certificate | Cài trực tiếp lên thiết bị đã đăng ký | Bot test, chat cá nhân |
| `staging` | Kiểm thử nội bộ | Development/Distribution | TestFlight internal | Bot test, chat nhóm test |
| `prod` | Bản nộp/chính thức | Distribution certificate | App Store / TestFlight external | Bot thật, chat đích thật |

---

## 12. GIAO DIỆN — NỘI DUNG CẦN BỔ SUNG

### 12.1 Màn hình `/consent` — nội dung bắt buộc mới (FR-IO-NOT-05)

Phải nêu rõ: **kết quả thu thập được gửi tới một dịch vụ bên ngoài (Telegram), không
chỉ ở lại trên thiết bị.** Thông báo này phải xuất hiện **trước** khi hộp thoại xin
quyền hệ thống hiện ra. Nội dung phải khớp với khai báo trong privacy manifest.

Cơ sở: đổi kênh nhận làm thay đổi bản chất luồng dữ liệu — dữ liệu nay rời khỏi hạ
tầng của hệ thống. Người dùng cần biết trước khi cấp quyền.

### 12.2 Màn hình `/settings` — mục Kênh gửi kết quả

- Hiển thị trạng thái cấu hình bot ở ba mức: **đã cấu hình / chưa cấu hình / không hợp lệ**.
- Nút **kiểm tra kết nối** gọi `getMe` để xác nhận token còn hiệu lực.
- Thông báo lỗi **không được chứa token**.
- **Nút kiểm tra kết nối chỉ dùng để chẩn đoán** — nó KHÔNG thay thế bước đối chiếu
  whitelist trước mỗi lần gửi. Đây là hai cơ chế khác nhau.

### 12.3 Màn hình `/sync` và `/audit-log`

- `/sync`: hiển thị số gói kết quả đang chờ gửi.
- `/audit-log`: hiển thị bản ghi cho mỗi lần gửi, đọc từ `send_log`, đủ để trả lời
  "gói nào đã gửi, lúc nào, mấy lần, kết quả cuối ra sao".

---

## 13. YÊU CẦU CHỨC NĂNG PHẢI THOẢ (SRS v4.0)

### 13.1 Năm yêu cầu mới — mỗi yêu cầu nêu đủ tiêu chí chấp nhận

**FR-IO-NOT-01 — Gửi kết quả qua Telegram Bot** (Ưu tiên: Cao)
- Sau khi một gói kết quả hoàn tất, app gửi kết quả đến chat Telegram đã cấu hình qua Telegram Bot API, thay cho việc đẩy lên Backend.
- ✓ Kết quả xuất hiện trong đúng chat đích đã cấu hình.
- ✓ **Không còn request nào gửi tới endpoint Backend** của hệ thống từ nhánh iOS.
- ✓ Mọi gói kết quả gửi đi đều có thể truy vết qua mã phiên và deviceId.

**FR-IO-NOT-02 — Gửi đúng loại nội dung** (Cao)
- App chọn phương thức gửi phù hợp với loại kết quả.
- ✓ Không có kết quả nào bị cắt do vượt giới hạn ký tự.
- ✓ Kết quả dài được gửi dạng tệp hoặc chia phần có đánh số thứ tự.
- ✓ Việc chia phần **không cắt giữa một bản ghi**.

**FR-IO-NOT-03 — Cấu hình và whitelist đích gửi** (Cao)
- Bot token và chat_id nạp từ cấu hình theo môi trường, lưu bằng secure storage, mọi lần gửi đối chiếu whitelist.
- ✓ Không có bot token hay chat_id đầy đủ trong mã nguồn, trong log, hoặc trong repo.
- ✓ Kết quả không được gửi tới chat ngoài whitelist; trường hợp này có bản ghi cảnh báo.
- ✓ Màn hình settings hiển thị đúng trạng thái cấu hình và có nút kiểm tra kết nối bot.

**FR-IO-NOT-04 — Xử lý lỗi và độ bền của hàng đợi** (Cao)
- App xử lý được mất mạng, lỗi xác thực, lỗi máy chủ và giới hạn tần suất; gói chưa gửi được giữ lại và thử lại theo backoff có giới hạn.
- ✓ Kết quả không mất khi mất mạng hoặc khi app bị đóng.
- ✓ Khi bị giới hạn tần suất, app tôn trọng thời gian chờ do máy chủ trả về.
- ✓ Không có vòng lặp thử lại vô hạn; số lần thử không vượt giới hạn cấu hình.
- ✓ Một gói lỗi vĩnh viễn **không chặn** các gói phía sau.

**FR-IO-NOT-05 — Thông báo kênh gửi trong consent** (Cao)
- Màn hình consent nêu rõ kết quả được gửi tới một dịch vụ bên ngoài (Telegram).
- ✓ Người dùng được thông báo trước khi hộp thoại xin quyền hệ thống xuất hiện.
- ✓ Nội dung thông báo khớp với khai báo trong privacy manifest.

### 13.2 Một yêu cầu sửa đổi

**FR-IO-SYN-01 (sửa đổi)** — App gửi dữ liệu đã chuẩn hoá ra khỏi thiết bị theo hàng
đợi bền vững, đến chat Telegram đã cấu hình, qua Telegram Bot API.
- Thay đổi so với v3.0: đích gửi đổi từ Backend sang Telegram; cơ chế hàng đợi, backoff
  và giới hạn số lần thử **giữ nguyên**.

### 13.3 Mười bốn yêu cầu giữ nguyên — không được phá vỡ

`FR-IO-DEV-01`, `FR-IO-LOC-01`, `FR-IO-LOC-02`, `FR-IO-CON-01`, `FR-IO-CAL-01`,
`FR-IO-PHO-01`, `FR-IO-CAM-01`, `FR-IO-MIC-01`, `FR-IO-KBD-01`, `FR-IO-SCR-01`,
`FR-IO-CON-02`, `FR-IO-CON-03`, `FR-IO-ERR-01`, `FR-IO-SYN-02`.

---

## 14. YÊU CẦU PHI CHỨC NĂNG (SRS v4.0)

### 14.1 Năm NFR mới của v4.0

| NFR ID | Yêu cầu | Loại | Tiêu chí đo lường |
|--------|---------|------|-------------------|
| NFR-IO-13 | Bí mật không lộ trong log hoặc mã nguồn | Security | Không có bot token hay chat_id đầy đủ trong log và trong repo |
| NFR-IO-14 | Thời gian gửi kết quả không chặn luồng chính | Performance | Gửi bất đồng bộ; không làm chậm tác vụ thu thập |
| NFR-IO-15 | Bảo toàn kết quả khi gửi thất bại | Reliability | Gói chờ gửi còn nguyên sau khi đóng/mở app |
| NFR-IO-16 | Giới hạn tần suất được tôn trọng | Reliability | Tuân thủ thời gian chờ máy chủ trả về khi bị giới hạn |
| NFR-IO-17 | Chỉ gửi đến đích đã cấu hình | Security | 100% lần gửi khớp whitelist chat_id |

### 14.2 Mười hai NFR giữ nguyên

`NFR-IO-01` (khởi động ≤ 3 giây), `NFR-IO-02` (pin), `NFR-IO-03` (bộ nhớ),
`NFR-IO-04` (ATS/HTTPS), `NFR-IO-05` (secure storage), `NFR-IO-06` (Data Protection),
`NFR-IO-07` (privacy manifest), `NFR-IO-08` (khả dụng), `NFR-IO-09` (tương thích iOS),
`NFR-IO-10` (đa ngôn ngữ), `NFR-IO-11` (khả năng bảo trì — tách tầng),
`NFR-IO-12` (tuân thủ App Store Guidelines).

---

## 15. PHẢI VƯỢT ĐƯỢC BỘ KIỂM THỬ (KML-TEST-001 v4.0)

Code của bạn sẽ được đánh giá bằng các ca sau. Viết code sao cho vượt được chúng.

### 15.1 Ca gửi kết quả (mới v4.0)

| Mã ca | Tên | Kết quả mong đợi |
|-------|-----|-----------------|
| TC-IO-NOT-01 | Gửi đến đúng chat đã cấu hình | Tin nhắn đến đúng chat; `send_log` ghi nhận mã phiên, phương thức, số lần thử, kết quả cuối, thời điểm; `/audit-log` hiển thị bản ghi tương ứng |
| TC-IO-NOT-02 | Chọn đúng phương thức gửi | Văn bản ngắn → tin nhắn; kết quả dài → tệp/phần có đánh số; ảnh nhỏ → `sendPhoto`; ảnh lớn → tệp; không cắt cụt; không cắt giữa bản ghi |
| TC-IO-NOT-03 | Mất mạng — hàng đợi bảo toàn | Gói ở lại queue, không mất; số lần thử tăng theo cấu hình; sau khi có mạng, gói được gửi |
| TC-IO-NOT-04 | Bot token sai hoặc bị thu hồi | Không crash; gửi dừng và báo cấu hình không hợp lệ; không thử lại vô hạn; **token không xuất hiện trong log**; gói vẫn trong queue |
| TC-IO-NOT-05 | Giới hạn tần suất và thử lại | Chờ đúng `retry_after`; không gói nào mất; số lần thử không vượt cấu hình; gói lỗi vĩnh viễn không chặn gói sau |

### 15.2 Ca sửa đổi

| Mã ca | Thay đổi so với v3.0 |
|-------|---------------------|
| TC-IO-13 | Kết quả mong đợi kiểm chứng trên chat Telegram và `send_log`, thay vì trên server và Dashboard |
| TC-IO-14 | Tiền đề đổi sang "gói kết quả chưa gửi được trong hàng đợi"; queue còn nguyên sau khi mở lại app |
| TC-IO-UI-05 | Consent phải nêu thêm thông tin về kênh gửi Telegram |

### 15.3 Ca bảo mật và giao diện mới

| Mã ca | Yêu cầu |
|-------|---------|
| TC-IO-SEC-08 | Whitelist và bảo mật bí mật: không gửi tới chat ngoài whitelist và có cảnh báo; không tìm thấy token/chat_id đầy đủ trong log; không có bí mật trong repo |
| TC-IO-UI-06 | Màn hình settings hiển thị đúng ba trạng thái cấu hình; nút kiểm tra kết nối hoạt động; thông báo lỗi không chứa token |

### 15.4 Ca phi chức năng liên quan trực tiếp

`TC-IO-NFR-13` (bí mật không lộ — rà log, log thiết bị, rà repo),
`TC-IO-NFR-14` (gửi không chặn luồng chính),
`TC-IO-NFR-15` (bảo toàn kết quả khi đóng/mở app),
`TC-IO-NFR-16` (giới hạn tần suất),
`TC-IO-NFR-17` (gửi đúng đích).

**Đặc biệt chú ý `TC-IO-NFR-11`:** khả năng bảo trì được kiểm chứng bằng **rà soát
import** — tầng Domain không được phụ thuộc vào lớp gửi. Đây không phải ca chạy thử.

### 15.5 Ca phòng thủ bắt buộc

**TC-IO-FOR-05** — Không artefact forensic nào đi qua kênh Telegram. Artefact điều tra
(sms.db, dữ liệu Safari, danh sách process, crash log) **không được** xuất hiện trên
chat Telegram; mã nguồn **không có** liên kết giữa quy trình điều tra và lớp gửi.

---

## 16. QUY TRÌNH LÀM VIỆC BẮT BUỘC

### 16.1 Thứ tự hiện thực

1. **Dựng khung dự án** — cấu trúc thư mục, dependency, flavor dev/staging/prod.
2. **Tầng dữ liệu trước** — bảng SQLite, gồm `telegram_queue` và `send_log`.
3. **DTO và entity** — kèm `platform = "ios"` và `deviceId`.
4. **`TelegramConfig` + `TokenStore`** — đọc cấu hình, whitelist, che bí mật trong log.
5. **`telegram_client`** — dio instance riêng, bốn endpoint, `SendResult`.
6. **`TelegramMessageBuilder`** — dựng phần đầu, escape HTML, chia phần theo bản ghi.
7. **`TelegramResultSender`** — quy tắc chọn phương thức, ma trận 6 trạng thái.
8. **`TelegramQueue` + dispatcher** — backoff, `retry_after`, gói lỗi vĩnh viễn.
9. **Provider và màn hình** — `/settings`, `/consent`, `/sync`, `/audit-log`.
10. **Unit test** cho lớp gửi — chạy được không cần thiết bị.
11. **Integration test + kiểm thử gửi thật** tới chat test.

### 16.2 Trước khi viết code, hãy xác nhận

Trả lời gọn bốn điểm này trước khi bắt đầu, để chốt các giá trị còn để trống:

1. Ba chỉ tiêu chất lượng trong SRS v4.0 Mục 5.3 (thời gian đến Telegram, tỷ lệ gửi
   thành công, số lần thử lại tối đa) — giá trị cụ thể là bao nhiêu?
2. `PACK_THRESHOLD` và `PACK_MAX_AGE` cho từng môi trường — chốt theo bảng ở Mục 6.6
   hay theo giá trị khác?
3. Bot test và chat test đã tạo chưa, và người nhận đã nhấn `start` chưa?
4. Bundle ID đã chốt chưa (PMP cảnh báo không đổi bundle ID sau GĐ1)?

### 16.3 Quy tắc viết code

- **Tầng Domain thuần khiết.** Không import `dio`, không import `telegram_*`, không
  import `flutter_secure_storage` ở tầng Domain.
- **Không chặn UI.** Mọi thao tác gửi phải bất đồng bộ; không `await` gửi trong widget handler.
- **Comment bằng tiếng Việt** cho các quyết định thiết kế, đặc biệt chỗ hiện thực các
  quy tắc ở Mục 6.2 và ma trận lỗi ở Mục 9.1.
- **Mỗi hằng số cấu hình** nằm trong `telegram_config.dart`; không rải magic number trong code.
- **Không log bí mật** — kiểm tra lại mọi chỗ có `print`, `debugPrint`, `log` trước khi nộp.
- **Không commit bí mật** — thêm `.env`, `*.secrets.*`, file cấu hình local vào `.gitignore`.
- **Không tạo endpoint Backend** cho nhánh iOS. Nếu còn code cũ gọi `/api/agent/sync`,
  xoá nó — tiêu chí chấp nhận của FR-IO-NOT-01 yêu cầu không còn request nào tới Backend.

### 16.4 Khi không chắc

Nếu một điểm trong tài liệu mâu thuẫn hoặc thiếu, **dừng lại và hỏi** — không tự suy
diễn theo hướng mở rộng khả năng của ứng dụng. Các ràng buộc ở Mục 1 là bất khả xâm
phạm; phần còn lại có thể làm rõ.

---

## 17. GHI NHẬN TRUNG THỰC — ĐỌC TRƯỚC KHI BẮT ĐẦU

Ba điểm dưới đây là hệ quả thật của việc đổi kênh, không phải lời cảnh báo hình thức.
Cần được phản ánh trong code, trong comment, và trong tài liệu bàn giao.

1. **Kết quả rời khỏi hạ tầng của hệ thống** và nằm trên hạ tầng của bên thứ ba.
   Hệ thống **không thể xoá hoặc thu hồi** kết quả đã gửi.
2. **Không còn Dashboard để đối chiếu.** Màn hình `/audit-log` cục bộ trở thành
   **nguồn tra cứu duy nhất**. Đây là lý do `send_log` phải được thiết kế đủ chi tiết.
3. **Màn hình consent phải nêu rõ điều này** (FR-IO-NOT-05). Đây không phải yêu cầu
   hình thức — người dùng cần biết dữ liệu được gửi tới dịch vụ bên ngoài trước khi cấp quyền.

Ngoài ra: kênh Telegram **không mở rộng** phạm vi dữ liệu ứng dụng tạo ra được. Danh
sách "không thể làm" ở Mục 1 vẫn nguyên vẹn, và kênh gửi mới không được trở thành
đường rò rỉ artefact điều tra (TC-IO-FOR-05).
