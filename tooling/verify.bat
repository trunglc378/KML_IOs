@echo off
REM Script tiện dụng cho môi trường Windows: chạy kiểm tra tĩnh + test.
REM Không chứa bí mật. Không gọi mạng.
setlocal

cd /d "%~dp0.."

echo === 1. Flutter/Dart version ===
call flutter --version
if errorlevel 1 (
  echo [LOI] Khong tim thay Flutter SDK trong PATH.
  exit /b 1
)

echo.
echo === 2. flutter pub get ===
call flutter pub get
if errorlevel 1 exit /b 1

echo.
echo === 3. Phan tich tinh (flutter analyze) ===
call flutter analyze
if errorlevel 1 exit /b 1

echo.
echo === 4. Kiem tra tang Domain thuan khiet (TC-IO-NFR-11) ===
call dart run tooling/check_domain_purity.dart
if errorlevel 1 exit /b 1

echo.
echo === 5. Kiem tra bi mat trong repo (TC-IO-SEC-08) ===
call dart run tooling/check_secrets.dart
if errorlevel 1 exit /b 1

echo.
echo === 6. Unit test (khong can thiet bi) ===
call flutter test
if errorlevel 1 exit /b 1

echo.
echo [OK] Tat ca kiem tra deu dat.
endlocal
