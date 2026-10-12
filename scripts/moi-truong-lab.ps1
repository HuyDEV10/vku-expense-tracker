param(
    [string]$FlutterRoot = $env:FLUTTER_ROOT,
    [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$Jdk = 'C:\Program Files\Android\Android Studio\jbr',
    [string]$TrustStore = ''
)
$ErrorActionPreference = 'Stop'
if (!$FlutterRoot) {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($command) { $FlutterRoot = Split-Path (Split-Path $command.Source -Parent) -Parent }
}
if (!$FlutterRoot -or !(Test-Path "$FlutterRoot\bin\flutter.bat")) {
    throw 'Nhập -FlutterRoot là thư mục Flutter đã cài hoặc thêm Flutter vào PATH.'
}
if (!(Test-Path "$Jdk\bin\javac.exe")) { throw 'Không tìm thấy JDK có javac. Nhập -Jdk đúng đường dẫn.' }
if (!(Test-Path "$AndroidSdk\platform-tools\adb.exe")) { throw 'Không tìm thấy Android SDK. Nhập -AndroidSdk đúng đường dẫn.' }
$env:FLUTTER_ROOT = $FlutterRoot
$env:ANDROID_HOME = $AndroidSdk
$env:JAVA_HOME = $Jdk
$entries = @("$FlutterRoot\bin", "$AndroidSdk\platform-tools", "$AndroidSdk\emulator", "$AndroidSdk\cmdline-tools\latest\bin", "$Jdk\bin")
$env:Path = ($entries -join ';') + ';' + $env:Path
if ($TrustStore) {
    if (!(Test-Path -LiteralPath $TrustStore)) { throw 'Không tìm thấy TrustStore.' }
    $env:JAVA_TOOL_OPTIONS = "$env:JAVA_TOOL_OPTIONS -Djavax.net.ssl.trustStore=`"$TrustStore`"".Trim()
}
