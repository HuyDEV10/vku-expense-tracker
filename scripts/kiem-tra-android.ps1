param([string]$DeviceId = "emulator-5554")

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Invoke-Flutter {
    param([string[]]$Arguments)
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter lỗi $LASTEXITCODE. Dừng kiểm tra để xử lý lỗi trên."
    }
}

# Build trước khi mở giả lập để giảm bộ nhớ sử dụng.
Read-Host "Tắt giả lập trước khi build. Nhấn Enter để tiếp tục"
Invoke-Flutter -Arguments @("pub", "get")
Invoke-Flutter -Arguments @("analyze")
Invoke-Flutter -Arguments @("test", "--reporter", "expanded")
Invoke-Flutter -Arguments @("build", "apk", "--debug", "--target-platform", "android-x64", "--target", "integration_test/receipt_flow_test.dart", "--dart-define=CAPTURE_SCREENSHOTS=true")

$testApk = Join-Path (Get-Location) "build\app\outputs\flutter-apk\app-debug.apk"
if (!(Test-Path $testApk)) { throw "Chưa tạo được APK kiểm thử." }

Read-Host "Mở giả lập trong Android Studio. Khi Android vào màn hình chính, nhấn Enter"
Invoke-Flutter -Arguments @("devices")
Invoke-Flutter -Arguments @("drive", "--no-pub", "--driver=test_driver/integration_test.dart", "--target=integration_test/receipt_flow_test.dart", "--use-application-binary=$testApk", "-d", $DeviceId)

Write-Host "Kiểm thử Android đã qua. Lấy số đo LAB3_OCR_MS từ kết quả ở trên."
