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


val homeBin = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

val version = "1.69.162"
val urlPrefix = s"https://github.com/brave/brave-browser/releases/download/v$version/"

def download(drop: Os.Path): Unit = {
  val url = s"$urlPrefix/${drop.name}"
  if (!drop.exists) {
    println(s"Downloading Brave Browser ...")
    drop.downloadFrom(url)
    println()
  }
}

def mac(): Unit = {
  val drop = cacheDir / s"brave-v$version-darwin-${if (Os.isMacArm) "arm" else "x"}64.zip"
  val platform = homeBin / "mac"
  val brave = platform / "Brave Browser.app"
  val ver = brave / "Contents" / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    brave.removeAll()
    println("Extracting Brave Browser ...")
    drop.unzipTo(platform)
    ver.write(version)
    proc"xattr -rd com.apple.quarantine $brave".run()
    proc"codesign --force --deep --sign - $brave".run()
    println()
    updated = T
  }
  if (updated) {
    println(s"To launch Brave Browser: open \"$brave\"")
  }
}

def linux(isArm: B): Unit = {
  val drop = cacheDir / s"brave-browser-$version-linux-${if (isArm) "arm" else "amd"}64.zip"
  val platform: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val brave = platform / "brave"
  val ver = brave / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    println("Extracting Brave Browser ...")
    val braveNew = platform / "brave.new"
    drop.unTarGzTo(braveNew)
    brave.removeAll()
    braveNew.moveTo(brave)
    ver.write(version)
    println()
    updated = T
  }
  if (updated) {
    println(s"To launch Brave Browser: ${brave / "bin" / "brave"}")
  }
}

def win(): Unit = {
  val drop = cacheDir / s"brave-v$version-win32-${if (Os.isWinArm) "arm" else "x"}64.zip"
  val platform = homeBin / "win"
  val brave = platform / "brave"
  val ver = brave / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    val braveNew = platform / "brave.new"
    println("Extracting Brave Browser ...")
    drop.unzipTo(braveNew)
    brave.removeAll()
    braveNew.moveTo(brave)
    ver.write(version)
    println()
    updated = T
  }
  val codium = brave / "bin" / "codium.cmd"
  if (updated) {
    println(s"To launch Brave Browser: ${brave / "bin" / "brave.exe"}")
  }
}

Os.kind match {
  case Os.Kind.Mac => mac()
  case Os.Kind.Linux => linux(F)
  case Os.Kind.LinuxArm => linux(T)
  case Os.Kind.Win => win()
  case _ =>
    eprintln("Unsupported platform")
    Os.exit(-1)
}
