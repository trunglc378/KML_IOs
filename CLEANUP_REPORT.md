# BÁO CÁO DỌN DẸP VÀ TỐI ƯU HÓA REPO (CLEANUP_REPORT.md)
**Dự án:** KML_iOS v4.0  
**Ngày thực hiện:** 29/09/2026  
**Nhánh thực hiện:** `chore/cleanup-unused-files`  
**Snapshot commit an toàn:** `201bf18` (`chore: snapshot before cleanup`)

---

## 1. Mục đích và Quy trình An toàn
Nhằm đảm bảo repository sạch sẽ, tinh gọn theo yêu cầu kỹ thuật và kế hoạch quản lý dự án (PMP v4.0), quá trình dọn dẹp được thực hiện tuân thủ quy trình kiểm soát rủi ro nghiêm ngặt:
1. **Tạo nhánh riêng biệt:** Không thao tác trực tiếp trên nhánh chính (`chore/cleanup-unused-files`).
2. **Snapshot commit an toàn:** Lưu trạng thái ban đầu trước khi can thiệp vào commit `201bf18`.
3. **Phân tích tham chiếu (No Broken Reference):** Sử dụng ripgrep và static analyzer kiểm tra toàn bộ mã nguồn (`*.dart`, `*.bat`, `*.ps1`, `*.yaml`, `*.json`) để đảm bảo không có bất kỳ file nào được dọn dẹp là phụ thuộc của mã nguồn hay tài liệu v4.0.
4. **Cô lập tạm thời (`_trash_20260929/`):** Di chuyển các file ứng viên vào thư mục rác tạm thời.
5. **Chạy kiểm thử toàn diện:** Chạy `flutter test`, `check_secrets.dart`, `check_domain_purity.dart`, và `tooling\verify.bat`.
6. **Xác nhận kết quả:** Khi 100% kiểm tra đạt `[OK]`, mới tiến hành xóa vĩnh viễn và tạo commit dọn dẹp.

---

## 2. Danh sách các tệp được dọn dẹp

| STT | Tên tệp / Đường dẫn | Lý do dọn dẹp | Tình trạng nguồn chuẩn thay thế |
|---|---|---|---|
| 1 | `01-Tai-lieu-Gioi-thieu-du-an-KML-iOS.docx` (ở root) | Tệp trùng lặp ở thư mục gốc | Đã có bản lưu chuẩn trong thư mục `doc/` |
| 2 | `02-Ke-hoach-quan-ly-du-an-KML-iOS.docx` (ở root) | Tệp trùng lặp ở thư mục gốc | Đã có bản lưu chuẩn trong thư mục `doc/` |
| 3 | `03-SRS-Dac-ta-yeu-cau-phan-mem-KML-iOS.docx` (ở root) | Bản nháp cũ chưa cập nhật v4.0 | Bản chuẩn chính thức: `doc/03-SRS-Dac-ta-yeu-cau-phan-mem-KML-iOS-v4.0.docx` |
| 4 | `04-SDS-Dac-ta-thiet-ke-phan-mem-KML-iOS.docx` (ở root) | Bản nháp cũ chưa cập nhật v4.0 | Bản chuẩn chính thức: `doc/04-SDS-Dac-ta-thiet-ke-phan-mem-KML-iOS-v4.0.docx` |
| 5 | `05-Tai-lieu-Kiem-thu-KML-iOS.docx` (ở root) | Bản nháp cũ chưa cập nhật v4.0 | Bản chuẩn chính thức: `doc/05-Tai-lieu-Kiem-thu-KML-iOS-v4.0.docx` |
| 6 | `_fin.txt` (ở root) | Tệp log tạm thời sinh ra trong quá trình kiểm thử | Không còn giá trị sử dụng |
| 7 | `_sec.txt` (ở root) | Tệp output tạm thời quét secret | Không còn giá trị sử dụng |

---

## 3. Nhật ký kiểm tra sau khi dọn dẹp

Sau khi di chuyển các file trên vào `_trash_20260929/`, hệ thống kiểm thử tự động đã được kích hoạt:

```text
E:\Project\KML_IOs>dart run tooling/check_secrets.dart
Đã quét 55 file văn bản.
[ĐẠT] Không tìm thấy bí mật nào trong repo (TC-IO-SEC-08).

E:\Project\KML_IOs>dart run tooling/check_domain_purity.dart
Đã kiểm tra 20 file trong các thư mục domain/.
[ĐẠT] Tầng Domain thuần khiết (TC-IO-NFR-11).

E:\Project\KML_IOs>flutter analyze
Analyzing KML_IOs...
No issues found! (ran in 4.8s)

E:\Project\KML_IOs>flutter test
00:04 +99: All tests passed!

[OK] Tat ca kiem tra deu dat.
```

## 4. Kết luận
- Toàn bộ 7 tệp thừa và trùng lặp đã được xóa an toàn khỏi root repository.
- Toàn bộ tài liệu chuẩn dự án v4.0 được lưu trữ tập trung, rõ ràng trong thư mục `doc/`.
- Không có bất kỳ liên kết, đường dẫn tương đối hoặc kịch bản tự động nào bị hỏng hóc.
