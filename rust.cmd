::/*#! 2> /dev/null                                                                                         #
@ 2>/dev/null # 2>nul & echo off & goto BOF                                                                 #
export SIREUM_HOME=$(cd -P $(dirname "$0")/../.. && pwd -P)                                                 #
if [ -f "$0.com" ] && [ "$0.com" -nt "$0" ]; then                                                           #
  exec "$0.com" "$@"                                                                                        #
else                                                                                                        #
  rm -fR "$0.com"                                                                                           #
  exec "${SIREUM_HOME}/bin/sireum" slang run "$0" "$@"                                                      #
fi                                                                                                          #
:BOF
setlocal
set NEWER=False
if exist %~dpnx0.com for /f %%i in ('powershell -noprofile -executionpolicy bypass -command "(Get-Item %~dpnx0.com).LastWriteTime -gt (Get-Item %~dpnx0).LastWriteTime"') do @set NEWER=%%i
if "%NEWER%" == "True" goto native
del "%~dpnx0.com" > nul 2>&1
if not exist "%~dp0..\sireum.jar" call "%~dp0..\init.bat"
"%~dp0..\sireum.bat" slang run "%0" %*
exit /B %errorlevel%
:native
%~dpnx0.com %*
exit /B %errorlevel%
::!#*/
// #Sireum
import org.sireum._

val version = "1.74.1"

val homeBin: Os.Path = Os.slashDir.up.canon
val (homeBinPlatform, rustupInitUrl): (Os.Path, String) = Os.kind match {
  case Os.Kind.Mac =>
    val isArm: B = ops.StringOps(proc"uname -m".runCheck().out).trim == "arm64"
    val arch: String = if (isArm) "aarch64" else "x86_64"
    (homeBin / "mac", s"https://static.rust-lang.org/rustup/dist/$arch-apple-darwin/rustup-init")
  case Os.Kind.Linux =>
    (homeBin / "linux", "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init")
  case Os.Kind.LinuxArm =>
    (homeBin / "linux" / "arm", "https://static.rust-lang.org/rustup/dist/aarch64-unknown-linux-gnu/rustup-init")
  case Os.Kind.Win =>
    (homeBin / "win", "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe")
  case Os.Kind.Unsupported => halt("Unsupported platform")
}
val rustDir: Os.Path = homeBinPlatform / "rust"
val ver = rustDir / "VER"

if (ver.exists && ver.read == version) {
  Os.exit(0)
}

println(s"Installing Rust $version ...")
val rustupInit: Os.Path = rustDir / (if (Os.isWin) "rustup-init.exe" else "rustup-init")

rustDir.removeAll()
rustDir.mkdirAll()

println(s"Downloading ${rustupInit.name} ...")
rustupInit.downloadFrom(rustupInitUrl)
rustupInit.chmod("+x")
println()

proc"$rustupInit --default-toolchain=$version -y".env(ISZ(
  "CARGO_HOME" ~> (rustDir / "cargo").string,
  "RUSTUP_HOME" ~> (rustDir / "rustup").string)
).console.runCheck()

val rustupDir = Os.home / ".rustup"
val cargoDir = Os.home / ".cargo"
rustupDir.removeAll()
cargoDir.removeAll()
rustupDir.mklink(rustDir / "rustup")
cargoDir.mklink(rustDir / "cargo")

ver.writeOver(version)

println()