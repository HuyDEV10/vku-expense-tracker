param([string]$DeviceId = "emulator-5554")

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$log = Join-Path (Get-Location) "docs\kiem-tra-anh.log"
Start-Transcript -Path $log -Force | Out-Null

function Invoke-Flutter {
    param([string[]]$Arguments)
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter lỗi $LASTEXITCODE. Kết quả đã ghi tại $log."
    }
}

try {
    if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Không tìm thấy Flutter trong PATH. Mở PowerShell mới sau khi cài Flutter."
    }
    Read-Host "Tắt giả lập trước khi build. Nhấn Enter để tiếp tục"
    Invoke-Flutter -Arguments @("pub", "get")
    Invoke-Flutter -Arguments @("analyze")
    Invoke-Flutter -Arguments @("build", "apk", "--debug", "--target-platform", "android-x64", "--target", "integration_test/image_codec_test.dart")
    $testApk = Join-Path (Get-Location) "build\app\outputs\flutter-apk\app-debug.apk"
    if (!(Test-Path $testApk)) { throw "Không tìm thấy APK kiểm thử ảnh." }
    Read-Host "Mở giả lập x86_64 trong Android Studio. Khi Android vào màn hình chính, nhấn Enter"
    Invoke-Flutter -Arguments @("devices")
    Invoke-Flutter -Arguments @("drive", "--driver=test_driver/integration_test.dart", "--target=integration_test/image_codec_test.dart", "--use-application-binary=$testApk", "-d", $DeviceId)
    Write-Host "Hai ảnh PNG đã qua kiểm tra. Tiếp tục scripts\kiem-tra-android.ps1 để kiểm tra OCR và Isar."
} finally {
    Stop-Transcript | Out-Null
}
