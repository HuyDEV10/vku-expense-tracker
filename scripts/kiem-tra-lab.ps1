param([string]$DeviceId = "emulator-5554")

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$environmentScript = Join-Path $PSScriptRoot 'moi-truong-lab.ps1'
if (!(Get-Command flutter -ErrorAction SilentlyContinue) -and (Test-Path $environmentScript)) {
    . $environmentScript
}
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Chưa có Flutter trong PATH. Làm phần 1 của HUONG_DAN_LAB_3.md rồi mở PowerShell mới."
}

$log = Join-Path (Get-Location) "docs\kiem-tra-lab.log"
Start-Transcript -Path $log -Force | Out-Null
try {
$flutterBin = Split-Path (Get-Command flutter).Source -Parent
$dartExe = Join-Path $flutterBin 'cache\dart-sdk\bin\dart.exe'
if (Test-Path $dartExe) {
    & $dartExe --help
    if ($LASTEXITCODE -ne 0) {
        throw 'Dart CLI không khởi động được. Xem docs\kiem-tra-lab.log; nếu có Access denied hoặc resolvedExecutable null trong sandbox, chạy scripts\cau-hinh-may.ps1 từ PowerShell thường.'
    }
}
foreach ($script in @("kiem-tra-anh.ps1", "kiem-tra-android.ps1")) {
    $path = Join-Path $PSScriptRoot $script
    & powershell -NoProfile -ExecutionPolicy Bypass -File $path -DeviceId $DeviceId
    if ($LASTEXITCODE -ne 0) {
        throw "Dừng tại $script. Giữ log trong docs để xử lý lỗi; chưa build APK nộp bài."
    }
}

Read-Host "Kiểm thử đã qua. Tắt giả lập rồi nhấn Enter để build APK release"
& flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "Build APK release thất bại." }
$apk = Join-Path (Get-Location) "build\app\outputs\flutter-apk\app-release.apk"
if (!(Test-Path $apk)) { throw "Không tìm thấy APK release." }
Get-Item $apk | Select-Object FullName, Length
Get-FileHash $apk -Algorithm SHA256
Write-Host "APK đã build. Tiếp tục thử APK release, quay video và cập nhật báo cáo theo HUONG_DAN_LAB_3.md."
} finally {
    Stop-Transcript | Out-Null
}



