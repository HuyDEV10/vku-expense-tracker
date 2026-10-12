param([string]$FlutterRoot = $env:FLUTTER_ROOT, [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk", [string]$Jdk = 'C:\Program Files\Android\Android Studio\jbr', [string]$TrustStore = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'moi-truong-lab.ps1') -FlutterRoot $FlutterRoot -AndroidSdk $AndroidSdk -Jdk $Jdk -TrustStore $TrustStore
# Cấu hình PATH cho người dùng hiện tại.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (!$userPath) { $userPath = '' }
$entries = @("$env:FLUTTER_ROOT\bin", "$env:ANDROID_HOME\platform-tools", "$env:ANDROID_HOME\emulator", "$env:ANDROID_HOME\cmdline-tools\latest\bin")
foreach ($entry in $entries) {
    if (($userPath -split ';') -notcontains $entry) {
        $userPath = $userPath.TrimEnd(';') + ';' + $entry
    }
}
[Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', $env:ANDROID_HOME, 'User')
& flutter config --jdk-dir "$env:JAVA_HOME" --android-sdk "$env:ANDROID_HOME"
if ($LASTEXITCODE -ne 0) { throw 'Flutter config thất bại.' }
& flutter doctor -v
if ($LASTEXITCODE -ne 0) { Write-Warning 'Xem các mục còn thiếu trong flutter doctor.' }
& flutter doctor --android-licenses
if ($LASTEXITCODE -ne 0) { throw 'Chưa hoàn tất Android licenses.' }
& (Join-Path $PSScriptRoot 'kiem-tra-lab.ps1')

