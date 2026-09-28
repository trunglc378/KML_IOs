# Cấu hình kênh gửi kết quả Telegram — KML-iOS v4.0

> Tài liệu cho **người vận hành**, không phải cho lập trình viên.
> Không chứa token ở bất kỳ đâu trong file này.

---

## 1. Tạo bot qua BotFather

1. Mở Telegram, tìm **@BotFather** (có dấu tick xanh).
2. Gửi lệnh /newbot
3. Đặt **tên hiển thị** (ví dụ: KML-iOS Bot).
4. Đặt **username**, phải kết thúc bằng bot (ví dụ: KML_IOs_bot).
5. BotFather trả về **token** dạng <bot_id>:<secret>.

> **CẢNH BÁO BẢO MẬT:** token là toàn quyền với bot. Không dán vào chat,
> không chụp ảnh màn hình, không commit vào Git. Nếu nghi ngờ bị lộ,
> gửi /revoke cho BotFather để cấp token mới NGAY.

---

## 2. Lấy chat_id

**Bước 1:** người nhận mở chat với bot, nhấn **Start**, gửi một tin bất kỳ.

**Bước 2:** mở URL sau trên trình duyệt (thay <TOKEN> bằng token thật):

    https://api.telegram.org/bot<TOKEN>/getUpdates

Tìm trường chat.id trong kết quả. Đó là **chat_id**.

> **PHÂN BIỆT bot_id VÀ chat_id** — lẫn hai giá trị này gây lỗi chat not found:
> - bot_id là trường result.id của getMe (ví dụ: 8920168927).
> - chat_id nằm trong message.chat.id của getUpdates.

> **Chat group có chat_id SỐ ÂM** (dạng -100... hoặc -5...).
> Giữ nguyên dấu trừ khi khai báo và khi truyền vào Bot API.

---

## 3. Bảng cấu hình của dự án

Bot: **@KML_IOs_bot**, bot_id 8920168927.

| Vai trò | chat_id | Title | Type |
|---|---|---|---|
| dev | 5887530234 | Lucie Xuân | private |
| staging | -5152160106 | KML-iOS · Test | group |
| prod | -5022357153 | KML-iOS · Kết quả | group |
| Ngoài whitelist | 8178322761 | Nắng Lào Cai | private |

> **KHÔNG ghi token vào README.** Token chỉ nằm trong --dart-define lúc build
> hoặc nhập qua màn hình /settings.

> **Cả ba flavor dùng CHUNG một bot** — nên token giống nhau, và bot KHÔNG
> còn là cơ chế phân biệt môi trường. Ranh giới phân biệt chuyển sang
> chat_id và **whitelist theo flavor**. Không có whitelist, cấu hình nhầm
> chat_id ở dev sẽ đẩy dữ liệu thử nghiệm vào chat chính thức.

---

## 4. Nạp cấu hình vào app

### Cách 1 — Qua màn hình /settings (khuyến dùng)

1. Mở app, vào **Cài đặt**.
2. Nhập **Bot token** (ô nhập bị che) và **Chat id**.
3. Nhấn **Lưu cấu hình**. Giá trị được lưu vào Keychain của thiết bị.
4. Nhấn **Kiểm tra kết nối** để xác nhận token còn hiệu lực.

> Nút kiểm tra kết nối CHỈ để chẩn đoán. Nó KHÔNG thay thế bước đối chiếu
> whitelist trước mỗi lần gửi — đó là hai cơ chế khác nhau.

### Cách 2 — Qua --dart-define khi build

    flutter build ios --flavor prod \
      --dart-define=FLAVOR=prod \
      --dart-define=TELEGRAM_BOT_TOKEN=<token> \
      --dart-define=TELEGRAM_CHAT_ID=-5022357153 \
      --dart-define=TELEGRAM_CHAT_WHITELIST=-5022357153 \
      --dart-define=TIMEOUT_SECONDS=30 \
      --dart-define=MAX_RETRY=5 \
      --dart-define=BACKOFF_BASE_SECONDS=2 \
      --dart-define=PACK_THRESHOLD=50 \
      --dart-define=PACK_MAX_AGE_SECONDS=300

**Sáu biến cấu hình:**

| Biến | Ý nghĩa | dev | staging | prod |
|---|---|---|---|---|
| FLAVOR | Môi trường | dev | staging | prod |
| TIMEOUT_SECONDS | Timeout | 15 | 15 | 30 |
| MAX_RETRY | Số lần thử | 3 | 3 | 5 |
| BACKOFF_BASE_SECONDS | Cơ số backoff | 1 | 1 | 2 |
| PACK_THRESHOLD | Ngưỡng số bản ghi | 10 | 10 | 50 |
| PACK_MAX_AGE_SECONDS | Ngưỡng thời gian | 60 | 60 | 300 |

---

## 5. Bốn endpoint được dùng

| Method | Endpoint | Dùng khi |
|---|---|---|
| POST | /bot<token>/sendMessage | Văn bản ≤ 4096 ký tự |
| POST | /bot<token>/sendDocument | Tệp đính kèm, hoặc văn bản dài |
| POST | /bot<token>/sendPhoto | Ảnh ≤ 10 MB |
| GET | /bot<token>/getMe | Nút kiểm tra kết nối ở /settings |

> App KHÔNG dùng package bọc Bot API của bên thứ ba. Client được viết riêng
> trong lib/core/network/telegram_client.dart.

---

## 6. Xử lý sự cố

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| chat not found | Chưa nhấn Start, hoặc sai chat_id | Nhấn Start; kiểm lại getUpdates |
| 401 Unauthorized | Token sai hoặc bị thu hồi | Cấp token mới qua /revoke |
| 403 Forbidden | Bot không có quyền gửi vào chat | Kiểm quyền của bot trong group |
| 429 Too Many Requests | Chạm giới hạn tần suất | App tự chờ theo retry_after |
| Tin không đến | chat_id ngoài whitelist của flavor | Kiểm telegram_config.dart |
| Gói nằm mãi trong queue | Cấu hình chưa hợp lệ | Kiểm trạng thái ở /settings |

---

## 7. Lưu ý về group

Bot có can_read_all_group_messages: false — **gửi được vào group nhưng không
đọc tin thường**. Dự án chỉ cần GỬI, nên không cần tắt privacy.

Chỉ tắt privacy (BotFather → /setprivacy → **Disable**) nếu muốn bot phản hồi
lệnh trong group. Dự án hiện tại KHÔNG làm điều này — bot chỉ gửi, không nhận lệnh.

---

## 8. Cách chạy script đo ba chỉ tiêu chất lượng

Đặt biến môi trường (không commit):

    \$env:TELEGRAM_BOT_TOKEN='<token>'
    \$env:TELEGRAM_CHAT_ID='5887530234'  # check-secrets:ignore
    dart run tooling/measure_quality.dart --flavor=dev

> **Chạy script đo RIÊNG**, không chạy cùng lúc với test khác. Script gửi
> tuần tự để tránh chạm giới hạn tần suất làm số đo vô nghĩa.
