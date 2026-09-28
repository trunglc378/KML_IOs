# Hướng dẫn cài đặt — KML-iOS v4.0

> Tài liệu cho người cài đặt và kiểm thử. Hai kịch bản: **có cáp** và **không cáp**.
> Không chứa token ở bất kỳ đâu trong file này.

---

## 1. Điều kiện chung

| Hạng mục | Yêu cầu |
|---|---|
| Máy build | macOS + Xcode (bản mới nhất hỗ trợ phiên bản iOS tối thiểu) |
| Tài khoản | Apple Developer — bắt buộc cho TestFlight |
| Flutter | SDK ổn định, `flutter doctor` sạch phần iOS |
| Chứng chỉ | Development + Distribution, cài vào Keychain trên máy build |
| Provisioning profile | Khớp bundle ID, chứng chỉ, và danh sách thiết bị |

**Kiểm tra nhanh môi trường:**

    flutter doctor -v
    flutter devices

---

## 2. Kịch bản A — CÓ kết nối điện thoại với máy tính

Dùng khi cài trực tiếp lên thiết bị đã đăng ký trong provisioning profile.

**Bước 1 — Lấy dependencies và kiểm tra thiết bị:**

    flutter pub get
    flutter devices

**Bước 2 — Cài trực tiếp lên thiết bị (bản dev):**

    flutter run --dart-define=FLAVOR=dev --release

**Hoặc build .ipa rồi cài thủ công:**

    flutter build ipa --dart-define=FLAVOR=dev
    # File .ipa sinh ra ở build/ios/ipa/

### Ba điểm dễ vướng

1. **Mở Xcode ít nhất một lần** để ký (auto-signing với team đã chọn).
2. **Nếu `flutter run` báo lỗi signing:** mở `ios/Runner.xcworkspace` → chọn Team
   → để Xcode tự tạo profile.
3. **Thiết bị phải nằm trong danh sách đã đăng ký** của provisioning profile
   Development. Thiết bị chưa đăng ký sẽ báo lỗi ở bước ký.

---

## 3. Kịch bản B — KHÔNG có kết nối điện thoại với máy tính

Dùng khi build trên máy này nhưng cài qua TestFlight (không cần cáp).

**Bước 1 — Build .ipa với Distribution signing:**

    flutter build ipa --release --dart-define=FLAVOR=staging

**Bước 2 — Upload lên App Store Connect:**

    # Cách 1: mở Xcode Organizer
    open build/ios/archive/Runner.xcarchive

    # Cách 2: dùng app Transporter để upload file .ipa

**Bước 3 — Phân phối qua TestFlight:**

1. Sau khi upload: App Store Connect → TestFlight.
2. Thêm người thử → họ nhận email.
3. Người thử cài qua app **TestFlight** trên iPhone.

### Lưu ý về thời gian xử lý

> Bản TestFlight cần thời gian xử lý — **thường 5–30 phút** — trước khi người
> thử nhận email. **Không rút ngắn được.** Đây là rủi ro A4 trong tài liệu kiểm thử.
>
> Nếu cần kiểm thử gấp, dùng **kịch bản A** (có cáp) — cài trực tiếp, không chờ.

---

## 4. Nạp cấu hình bot trước khi chạy

Ba cách:

| Cách | Lệnh / thao tác | Khi nào dùng |
|---|---|---|
| Qua /settings | Mở app → /settings → nhập token + chat_id → Lưu → Kiểm tra kết nối | Test thủ công (khuyến nghị) |
| Qua --dart-define | --dart-define=TELEGRAM_BOT_TOKEN=… | Build tự động |
| Qua biến môi trường | \$env:TELEGRAM_BOT_TOKEN=… | Script đo chỉ tiêu |

### Cảnh báo bắt buộc đọc

> **Cách `--dart-define` nhúng token vào binary.** Token sẽ nằm trong file
> `.ipa` và có thể bị trích xuất bằng công cụ phân tích. **Chỉ dùng cho build dev,**
> **không dùng cho prod.** Với prod, nạp token qua màn hình `/settings` (lưu vào
> Keychain của thiết bị).

### Bảng chat_id của dự án

Bot: **@KML_IOs_bot**, bot_id **8920168927**. (Không ghi token trong tài liệu này.)

| Vai trò | chat_id | Ghi chú |
|---|---|---|
| dev | 5887530234 | chat cá nhân — người nhận chính |
| staging | -5152160106 | chat nhóm — **số âm** |
| prod | -5022357153 | chat nhóm — **số âm** |
| Ngoài whitelist | 8178322761 | chat cá nhân — dùng để thử ca `blocked` |

> **chat_id của nhóm là số âm.** Giữ nguyên dấu trừ khi khai báo và khi truyền
> vào Bot API. Bất kỳ chỗ nào validate “chỉ chữ số” sẽ chặn nhầm số âm.
>
> Mỗi flavor chỉ chấp nhận **đúng một** chat_id trong bảng trên. Gửi tới chat_id
> ngoài whitelist của flavor đang chạy bị chặn ngay, **không phát sinh request**
> (trạng thái `blocked`).

---

## 5. Nạp cấu hình bot trước khi chạy

**Cách 1 — Qua màn hình `/settings` (khuyến nghị):**

1. Mở app → **Cài đặt** (`/settings`).
2. Nhập **bot token** và **chat_id** (ví dụ dev: `5887530234`).
3. Nhấn **Lưu**.
4. Nhấn **Kiểm tra kết nối** — phải báo **“Kết nối thành công”**.

Token được lưu vào **Keychain của chính app**, không vào SQLite thường và không
vào `shared_preferences`.

**Cách 2 — Qua `--dart-define`:**

    flutter run --release --dart-define=FLAVOR=dev \
      --dart-define=TELEGRAM_BOT_TOKEN=<token>

> **Cảnh báo:** cách này **nhúng token vào binary**. Token nằm trong file `.ipa`
> và có thể bị trích xuất bằng công cụ phân tích. **Chỉ dùng cho build dev,**
> **không dùng cho prod.** Với prod, nạp token qua màn hình `/settings`.

---

## 6. Xác nhận sau khi cài

**Bước 1 — Thiết bị đã nhận:**

    flutter devices

**Bước 2 — Xem log khi app đang chạy:**

    flutter logs

**Bước 3 — Chạy bộ unit test (không cần thiết bị):**

    flutter test test/

**Bước 4 — Kiểm tra trong app:**

1. Mở app → **Cài đặt** → trạng thái phải hiển thị **“đã cấu hình”** (màu xanh).
2. Nhấn **Kiểm tra kết nối** → phải hiện **“Kết nối thành công”**.
3. Chạy một thao tác thu thập (ví dụ: vị trí).
4. Mở Telegram → kiểm tra tin đã đến chat đích trong **≤ 10 giây**.
5. Mở `/audit-log` → phải có bản ghi với `outcome = success`.

Nếu bước 4 không đạt, xem `docs/README-telegram-bot.md` Mục 6 — Xử lý sự cố.
