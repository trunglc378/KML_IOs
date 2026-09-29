# TÀI LIỆU CẤU HÌNH VÀ VẬN HÀNH KÊNH TELEGRAM BOT (TELEGRAM_SETUP.md)

**Dự án:** KML_iOS v4.0  
**Tài liệu tham chiếu chuẩn:** `KML-SRS-001 v4.0`, `KML-SDS-001 v4.0`, `doc/Telegram_Infor.txt`

---

## 1. Tổng quan & Thông tin Kênh Telegram

Kênh truyền dữ liệu chính thức của hệ thống **KML_iOS v4.0** sử dụng giao thức **Telegram Bot API** qua HTTPS an toàn.

### 1.1. Thông tin Bot chính thức
- **Tên Bot:** `KML_IOs`
- **Username:** `@KML_IOs_bot`
- **ID Bot:** `8920168927`
- **Token Format:** `<bot_id>:<secret_hash>` (ví dụ: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 1.2. Danh sách Whitelist Chat ID theo Môi trường (Flavor)
Hệ thống KML_iOS áp dụng cơ chế **Whitelist cưỡng bức (Forced Whitelist)** ở tầng `TelegramConfig` (SDS v4.0 Mục 11.2.1). Bất kỳ nỗ lực gửi tin nhắn đến Chat ID nằm ngoài whitelist của môi trường đang chạy sẽ bị **chặn ngay lập tức (blocked)** trước khi gửi request ra mạng, đảm bảo không rò rỉ dữ liệu nhạy cảm.

| Môi trường (Flavor) | Loại hình nhận | Chat ID Whitelist | Mô tả mục tiêu |
|---|---|---|---|
| **Dev** | Cá nhân (Direct Message) | `5887530234` | Tài khoản Telegram cá nhân của kỹ sư kiểm thử |
| **Staging** | Nhóm Supergroup | `-5152160106` | Kênh giám sát và nghiệm thu chất lượng hệ thống |
| **Production** | Nhóm Supergroup | `-5022357153` | Kênh tiếp nhận dữ liệu vận hành chính thức |
| **Bị chặn (Blacklist/Test)** | Không xác thực | `8178322761` | Chat ID dùng kiểm thử kịch bản chặn xâm nhập |

> **LƯU Ý ĐẶC BIỆT VỀ CHAT ID NHÓM TELEGRAM:**
> Tất cả các ID của Supergroup Telegram **bắt buộc phải có dấu trừ `-` phía trước** (ví dụ: `-5152160106`). Nếu bỏ dấu trừ, Telegram API sẽ hiểu nhầm là User ID và trả về lỗi `chat not found`.

---

## 2. Quy tắc An toàn và Bảo vệ Secret

Theo yêu cầu nghiêm ngặt từ quy chuẩn kiến trúc và kiểm thử an ninh (`TC-IO-SEC-08`):
1. **Không commit secret:** Tuyệt đối không lưu Bot Token hoặc Chat ID trong kho Git mã nguồn công khai hoặc các file cấu hình theo dõi.
2. **Không log token nguyên vẹn:** Trong nhật ký log hoặc màn hình UI, chỉ được phép hiển thị token dạng che mờ (masking), ví dụ:
   ```text
   1234567890:ABCdefGHIjklMNOpqrsTUVwxyz 
   --> 1234567890:ABCdefGH...UVwxyz
   ```
3. **Thứ tự ưu tiên cấu hình (Precedence Order):**
   1. Keychain / Secure Storage lưu trên thiết bị (ưu tiên cao nhất nếu người dùng cấu hình cục bộ).
   2. Biến biên dịch `--dart-define` (khi build release hoặc CI/CD).
   3. File môi trường cục bộ `.env` (chỉ dùng nội bộ máy trạm, file này nằm trong `.gitignore`).

---

## 3. Hướng dẫn Thiết lập Bot từ BotFather

Nếu cần tạo mới hoặc cấu hình lại Bot cho môi trường riêng, thực hiện theo các bước sau:

1. Mở ứng dụng Telegram, tìm kiếm bot chính thức **`@BotFather`** (có tích xanh xác thực).
2. Gửi lệnh `/newbot` để bắt đầu quy trình tạo bot.
3. Đặt tên hiển thị cho bot (Display Name), ví dụ: `KML_IOs_Staging`.
4. Đặt username kết thúc bằng `bot` (ví dụ: `my_kml_ios_test_bot`).
5. BotFather sẽ phản hồi chứa đoạn mã **HTTP API Token**. Lưu token này vào nơi an toàn (Password Manager / Keychain).
6. Tắt tính năng tự thêm vào nhóm bừa bãi (nếu cần bảo mật cao):
   - Gửi lệnh `/setjoingroups` -> Chọn bot -> Chọn `Disable`.
7. Bật chế độ Group Privacy:
   - Gửi lệnh `/setprivacy` -> Chọn bot -> Chọn `Enable`.

---

## 4. Kiểm tra Kết nối Bot bằng Curl (Sanity Check)

Trước khi cấu hình vào ứng dụng, kỹ thuật viên có thể dùng terminal để kiểm tra tính khả dụng của bot và xác thực Chat ID:

### 4.1. Kiểm tra thông tin Bot (`getMe`):
```bash
curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe"
```
**Kết quả mong đợi:**
```json
{
  "ok": true,
  "result": {
    "id": 8920168927,
    "is_bot": true,
    "first_name": "KML_IOs",
    "username": "KML_IOs_bot",
    "can_join_groups": true,
    "can_read_all_group_messages": false,
    "supports_inline_queries": false
  }
}
```

### 4.2. Lấy Chat ID của nhóm/kênh (`getUpdates`):
1. Thêm Bot vào nhóm kiểm thử.
2. Gửi một tin nhắn bất kỳ vào nhóm (ví dụ: `/start` hoặc `ping`).
3. Chạy lệnh:
   ```bash
   curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates"
   ```
4. Tìm trường `"chat":{"id": -5152160106, ...}` trong chuỗi JSON trả về để lấy chính xác Chat ID.

### 4.3. Thử nghiệm gửi tin nhắn mẫu (`sendMessage`):
```bash
curl -s -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage" \
  -d "chat_id=-5152160106" \
  -d "text=<b>[SANITY TEST]</b> KML_iOS v4.0 Bot Connected Successfully" \
  -d "parse_mode=HTML"
```

---

## 5. Quy trình Đổi Token (Token Rotation) Khi Bị Rò Rỉ

Trong trường hợp token bị lộ hoặc cần thu hồi định kỳ theo chính sách an ninh thông tin:

1. **Thu hồi và cấp mới qua BotFather:**
   - Mở Telegram, nhắn tin cho `@BotFather`.
   - Gửi lệnh `/revoke`.
   - Chọn bot cần đổi token (`@KML_IOs_bot`).
   - BotFather sẽ lập tức vô hiệu hóa token cũ và sinh ra chuỗi token mới.
2. **Cập nhật cấu hình CI/CD:**
   - Truy cập trang quản trị CI/CD (Codemagic, GitHub Actions, GitLab CI).
   - Cập nhật biến môi trường bảo mật `TELEGRAM_BOT_TOKEN` với giá trị mới.
3. **Cập nhật trên thiết bị client:**
   - Người dùng mở ứng dụng KML_iOS -> Vào màn hình **Settings** -> Nhập token mới hoặc cập nhật thông qua bản build OTA mới.
   - Nhấn **"Kiểm tra kết nối Bot"** để xác nhận bot mới hoạt động trước khi đồng bộ dữ liệu.
4. **Kiểm tra audit log:**
   - Kiểm tra nhật ký `audit_log` và `send_log` trên ứng dụng để xác nhận các gói tin sau thời điểm đổi token đều phản hồi mã `200 OK`.
