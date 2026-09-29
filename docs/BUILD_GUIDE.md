# HƯỚNG DẪN BUILD VÀ CÀI ĐẶT ỨNG DỤNG KML_iOS v4.0 (BUILD_GUIDE.md)

Tài liệu này cung cấp hướng dẫn chi tiết dành cho DevOps, Kỹ sư phần mềm và Kỹ thuật viên triển khai ứng dụng **KML_iOS** (phiên bản v4.0) từ mã nguồn Flutter, hỗ trợ cả hai kịch bản môi trường:
- **Kịch bản A (Có máy Mac và cáp USB):** Quy trình chuẩn trực tiếp thông qua Xcode và thiết bị thật.
- **Kịch bản B (Không có cáp USB / Môi trường Windows):** Các giải pháp mạng không dây, TestFlight/Ad-Hoc, CI/CD Cloud và sideloading enterprise.

---

## MỤC LỤC
1. [Yêu cầu tiên quyết](#1-yêu-cầu-tiên-quyết)
2. [Cấu hình bảo mật và Biến môi trường](#2-cấu-hình-bảo-mật-và-biến-môi-trường)
3. [KỊCH BẢN A: Build với máy Mac và Cáp USB (Trực tiếp)](#3-kịch-bản-a-build-với-máy-mac-và-cáp-usb-trực-tiếp)
4. [KỊCH BẢN B: Triển khai Không cần cáp USB](#4-kịch-bản-b-triển-khai-không-cần-cáp-usb)
   - [B1: Xcode Wireless Debugging (Mạng Wi-Fi nội bộ)](#b1-xcode-wireless-debugging-mạng-wi-fi-nội-bộ)
   - [B2: Phân phối nội bộ qua Apple TestFlight / Ad-Hoc OTA](#b2-phân-phối-nội-bộ-qua-apple-testflight--ad-hoc-ota)
   - [B3: CI/CD Cloud Build từ máy Windows (Codemagic / GitHub Actions)](#b3-cicd-cloud-build-từ-máy-windows-codemagic--github-actions)
   - [B4: Sideloading tệp IPA bằng công cụ AltStore / Sideloadly qua Wi-Fi](#b4-sideloading-tệp-ipa-bằng-công-cụ-altstore--sideloadly-qua-wi-fi)
5. [Kiểm tra sau khi cài đặt (Post-Installation Verification)](#5-kiểm-tra-sau-khi-cài-đặt-post-installation-verification)
6. [Xử lý sự cố thường gặp (Troubleshooting)](#6-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 1. Yêu cầu tiên quyết

### Môi trường phát triển:
- **Flutter SDK:** Phiên bản 3.19.x (hoặc tương thích mới hơn).
- **Dart SDK:** Phiên bản 3.3.x.
- **macOS:** macOS Sonoma (14.x) trở lên (đối với máy trạm build trực tiếp).
- **Xcode:** Phiên bản 15.x trở lên, kèm theo iOS SDK 17.x+.
- **CocoaPods:** 1.14.x trở lên (`sudo gem install cocoapods`).
- **Apple Developer Account:** Tài khoản cá nhân (Personal Team) hoặc Doanh nghiệp (Enterprise/Organization).

---

## 2. Cấu hình bảo mật và Biến môi trường

> **QUY TẮC BẢO MẬT TUYỆT ĐỐI (SDS v4.0 Mục 11.2 & TC-IO-SEC-08):**
> Tuyệt đối KHÔNG hardcode bot token hoặc chat_id trong mã nguồn hay commit tệp `.env` vào kho chứa Git. Mọi thông tin nhạy cảm phải được truyền qua `--dart-define` hoặc file cấu hình cục bộ không lưu trên repo.

### Các biến cấu hình chính:
- `FLAVOR`: `dev`, `staging`, hoặc `prod`.
- `TELEGRAM_BOT_TOKEN`: Mã token bot Telegram (ví dụ: `8920168927:AAEOJV3AERdnNDfyZz5X7vY1e85xaVlP5QI`).
- `TELEGRAM_CHAT_ID`: ID người nhận hoặc ID nhóm Telegram (chú ý: Chat ID nhóm là số âm, ví dụ Staging: `-5152160106`, Production: `-5022357153`).

### Chuẩn bị file cấu hình cục bộ (tùy chọn):
Sao chép mẫu cấu hình từ các file ví dụ:
```bash
cp config/env.staging.json.example config/env.staging.json
# Điền các giá trị thực tế vào config/env.staging.json (file này đã được .gitignore bảo vệ)
```

---

## 3. KỊCH BẢN A: Build với máy Mac và Cáp USB (Trực tiếp)

Đây là kịch bản chuẩn cho lập trình viên có máy Mac và iPhone kết nối vật lý bằng cáp Lightning/Type-C.

### Bước A1: Chuẩn bị thiết bị iPhone
1. Cắm cáp kết nối iPhone với máy Mac.
2. Trên màn hình iPhone, chọn **"Tin cậy máy tính này" (Trust this computer)** và nhập mật mã mở khóa.
3. Kích hoạt chế độ nhà phát triển:
   - Vào **Cài đặt (Settings)** -> **Quyền riêng tư & Bảo mật (Privacy & Security)**.
   - Cuộn xuống dưới cùng chọn **Chế độ nhà phát triển (Developer Mode)** -> Bật **BẬT (ON)** -> Khởi động lại máy theo yêu cầu.

### Bước A2: Cấu hình Signing & Capabilities trên Xcode
1. Mở thư mục dự án iOS trong Xcode:
   ```bash
   cd ios
   pod install
   open Runner.xcworkspace
   ```
2. Trong thanh điều hướng bên trái Xcode, nhấp chọn **Runner** (Target chính).
3. Chuyển sang tab **Signing & Capabilities**:
   - Tích chọn **Automatically manage signing**.
   - Mục **Team**: Chọn tài khoản Apple Developer của bạn.
   - Mục **Bundle Identifier**: Đặt định danh duy nhất (ví dụ: `com.kml.ios.app` hoặc theo cấu hình doanh nghiệp).
4. Kiểm tra các quyền (Capabilities):
   - Background Modes (Location updates, Background fetch).
   - Đảm bảo các mô tả cấp quyền trong `Info.plist` đã có sẵn (`NSLocationWhenInUseUsageDescription`, `NSContactsUsageDescription`, `NSCalendarsUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`).

### Bước A3: Thực hiện Build và Chạy ứng dụng qua CLI
Từ thư mục gốc dự án, thực thi lệnh Flutter run kèm theo biến cấu hình:

```bash
# Build & Run môi trường Dev:
flutter run --release -d <DEVICE_ID> \
  --dart-define=FLAVOR=dev \
  --dart-define=TELEGRAM_BOT_TOKEN="8920168927:AAEOJV3AERdnNDfyZz5X7vY1e85xaVlP5QI" \
  --dart-define=TELEGRAM_CHAT_ID="5887530234"

# Hoặc môi trường Staging (Supergroup):
flutter run --release -d <DEVICE_ID> \
  --dart-define=FLAVOR=staging \
  --dart-define=TELEGRAM_BOT_TOKEN="8920168927:AAEOJV3AERdnNDfyZz5X7vY1e85xaVlP5QI" \
  --dart-define=TELEGRAM_CHAT_ID="-5152160106"
```

### Bước A4: Xác nhận Trust Profile trên iPhone
Lần đầu cài đặt bằng Personal Team, ứng dụng sẽ chưa thể mở ngay:
1. Vào **Cài đặt (Settings)** -> **Cài đặt chung (General)** -> **Quản lý VPN & Thiết bị (VPN & Device Management)**.
2. Chọn profile của nhà phát triển (tên Apple ID của bạn) -> Chọn **Tin cậy (Trust)**.
3. Mở ứng dụng `KML_iOS` trên màn hình chính và cấp các quyền theo kịch bản kiểm thử.

---

## 4. KỊCH BẢN B: Triển khai Không cần cáp USB

Trong trường hợp máy Mac và iPhone không có kết nối cáp vật lý hoặc máy trạm phát triển chính chạy hệ điều hành Windows, hãy chọn một trong các phương án B1 đến B4 dưới đây.

---

### B1: Xcode Wireless Debugging (Mạng Wi-Fi nội bộ)
*Áp dụng khi:* Có máy Mac và iPhone kết nối chung một mạng Wi-Fi (yêu cầu ghép nối 1 lần đầu hoặc dùng chung tài khoản Apple ID).

#### Các bước thực hiện:
1. Đảm bảo máy Mac và iPhone kết nối cùng mạng Wi-Fi (hoặc iPhone phát Personal Hotspot cho máy Mac).
2. Trên Xcode: Mở menu **Window** -> **Devices and Simulators** (`Cmd + Shift + 2`).
3. Chọn thiết bị iPhone ở cột bên trái, tích chọn ô **"Connect via network"**.
4. Khi biểu tượng quả cầu mạng xuất hiện bên cạnh tên thiết bị, thiết bị đã sẵn sàng cho kết nối không dây.
5. Kiểm tra danh sách thiết bị trên terminal:
   ```bash
   flutter devices
   ```
6. Thực hiện lệnh build và deploy không dây tương tự như kịch bản A:
   ```bash
   flutter run -d <WIRELESS_DEVICE_ID> --dart-define=FLAVOR=staging \
     --dart-define=TELEGRAM_BOT_TOKEN="8920168927:AAEOJV3AERdnNDfyZz5X7vY1e85xaVlP5QI" \
     --dart-define=TELEGRAM_CHAT_ID="-5152160106"
   ```

---

### B2: Phân phối nội bộ qua Apple TestFlight / Ad-Hoc OTA
*Áp dụng khi:* Phân phối bản build cho tester, QA hoặc khách hàng thử nghiệm từ xa mà không cần cắm cáp hay can thiệp kỹ thuật.

#### Quy trình tạo gói IPA và phân phối:
1. **Build file Archive từ máy Mac:**
   ```bash
   flutter build ipa --release \
     --dart-define=FLAVOR=staging \
     --dart-define=TELEGRAM_BOT_TOKEN="8920168927:AAEOJV3AERdnNDfyZz5X7vY1e85xaVlP5QI" \
     --dart-define=TELEGRAM_CHAT_ID="-5152160106" \
     --export-options-plist=ios/ExportOptions.plist
   ```
2. **Tải lên TestFlight bằng altool/xcrun:**
   ```bash
   xcrun altool --upload-app --type ios \
     -f build/ios/ipa/KML_iOS.ipa \
     --apiKey <APP_STORE_CONNECT_KEY_ID> \
     --apiIssuer <ISSUER_ID>
   ```
3. **Cài đặt trên iPhone:**
   - Tester mở ứng dụng **TestFlight** trên iPhone.
   - Nhận lời mời tham gia nhóm thử nghiệm qua email hoặc link mời công khai.
   - Bấm **Cài đặt (Install)** trực tiếp qua kết nối mạng di động/Wi-Fi.

---

### B3: CI/CD Cloud Build từ máy Windows (Codemagic / GitHub Actions)
*Áp dụng khi:* Đội ngũ kỹ sư làm việc hoàn toàn trên môi trường Windows và cần xuất bản gói cài đặt iOS tự động lên đám mây.

#### Mô hình kiến trúc CI/CD:
```
[Windows Dev] --(git push)--> [GitHub / GitLab] 
                                    │
                                (Webhook)
                                    ▼
                      [Codemagic / GitHub Actions (macOS Runner)]
                                    │
                      - flutter build ipa
                      - Apple Signing Certificate (.p12 + MobileProvision)
                      - Secure Environment Variables
                                    │
                                    ▼
                      [Artifact: KML_iOS.ipa / TestFlight]
```

#### Ví dụ tệp cấu hình Codemagic (`codemagic.yaml`):
```yaml
workflows:
  ios-release:
    name: Build KML iOS Release
    instance_type: mac_mini_m2
    environment:
      groups:
        - telegram_credentials # Chứa TELEGRAM_BOT_TOKEN và TELEGRAM_CHAT_ID bí mật
      flutter: 3.19.5
      xcode: 15.3
    scripts:
      - name: Get dependencies
        script: flutter pub get
      - name: Run verification checks
        script: |
          dart run tooling/check_secrets.dart
          dart run tooling/check_domain_purity.dart
          flutter test
      - name: Build IPA
        script: |
          flutter build ipa --release \
            --dart-define=FLAVOR=staging \
            --dart-define=TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
            --dart-define=TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
    artifacts:
      - build/ios/ipa/*.ipa
```

---

### B4: Sideloading tệp IPA bằng công cụ AltStore / Sideloadly qua Wi-Fi
*Áp dụng khi:* Đã có file `.ipa` được xuất ra từ CI/CD hoặc máy Mac khác, muốn cài đặt lên iPhone từ máy tính Windows/Mac mà không dùng TestFlight.

#### Hướng dẫn cài đặt qua Sideloadly:
1. Tải và cài đặt phần mềm **Sideloadly** trên máy tính (hỗ trợ cả Windows và macOS).
2. Đảm bảo máy tính đã cài đặt **iTunes** và **iCloud** (phiên bản tải trực tiếp từ Apple, không dùng bản Microsoft Store).
3. Khởi động Sideloadly, kéo tệp `KML_iOS.ipa` vào giao diện phần mềm.
4. Nhập Apple ID cá nhân để ký lại ứng dụng (Free Developer Certificate).
5. Tích chọn **Wi-Fi Install** trong phần nâng cao (sau khi đã kết nối đồng bộ 1 lần đầu).
6. Bấm **Start** để hoàn tất nạp ứng dụng vào iPhone qua mạng không dây.
7. Vào **Settings -> General -> VPN & Device Management** trên iPhone để Trust Profile trước khi mở app.

---

## 5. Kiểm tra sau khi cài đặt (Post-Installation Verification)

Sau khi cài đặt thành công ứng dụng trên thiết bị mục tiêu, kỹ thuật viên tiến hành quy trình kiểm tra theo danh mục (Checklist):

1. **Khởi chạy ứng dụng:** Mở ứng dụng từ màn hình chính, kiểm tra giao diện Home hiển thị tiêu đề `KML-iOS v4.0`.
2. **Kiểm tra kết nối Telegram:**
   - Điều hướng tới màn hình **Cài đặt (Settings)**.
   - Nhấn nút **"Kiểm tra kết nối Bot"**.
   - Ứng dụng gửi lệnh `getMe` và hiển thị trạng thái `Hợp lệ (Bot: @KML_IOs_bot)`.
   - *Lưu ý bảo mật:* Tuyệt đối không hiển thị mã token trần trên màn hình (chỉ hiển thị token đã mask theo SDS v4.0).
3. **Cấp quyền hệ thống:** Thực hiện các hành động thu thập dữ liệu (Vị trí, Danh bạ, Ảnh) và xác nhận pop-up xin quyền của iOS hoạt động chuẩn xác.
4. **Kiểm tra nhận tin trên Telegram:**
   - Mở ứng dụng Telegram trên thiết bị quản lý.
   - Kiểm tra tin nhắn báo cáo từ Bot `@KML_IOs_bot` đã gửi về đúng nhóm Chat ID (ví dụ: Staging `-5152160106`).
   - Kiểm tra định dạng tin nhắn có đủ 4 dòng Header chuẩn (SDS v4.0 Mục 3.5).

---

## 6. Xử lý sự cố thường gặp (Troubleshooting)

| Mã lỗi / Tình trạng | Nguyên nhân có thể | Cách khắc phục |
|---|---|---|
| `Signing for "Runner" requires a development team` | Chưa chọn Apple Developer Team trong Xcode | Mở `Runner.xcworkspace` -> Target `Runner` -> Tab `Signing & Capabilities` -> Chọn Team hợp lệ. |
| `Untrusted Developer Certificate` | Profile cá nhân chưa được tin cậy trên iPhone | Vào **Settings -> General -> VPN & Device Management** -> Nhấn **Trust [Apple ID]**. |
| `Developer Mode disabled` (iOS 16+) | Chưa kích hoạt chế độ nhà phát triển trên iOS | Vào **Settings -> Privacy & Security -> Developer Mode** -> Gạt **ON** và khởi động lại iPhone. |
| Telegram trả về lỗi `401 Unauthorized` | Bot Token không chính xác hoặc đã bị thu hồi | Kiểm tra lại giá trị `--dart-define=TELEGRAM_BOT_TOKEN` hoặc cấu hình TokenStore. |
| Trạng thái `blocked` (Không có tin nhắn Telegram) | Chat ID không thuộc whitelist của Flavor đang chạy | Xem lại `doc/Telegram_Infor.txt`. Dev chỉ nhận `5887530234`, Staging chỉ nhận `-5152160106`. Chú ý chat ID nhóm bắt buộc có dấu trừ `-`. |
| CocoaPods không tìm thấy podspec tương thích | Cache pods cũ hoặc kiến trúc máy Mac Apple Silicon | Chạy: `cd ios && pod deintegrate && pod setup && pod install --repo-update`. |
