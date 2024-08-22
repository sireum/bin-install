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

val version = "1.92.2.24228"
val urlPrefix = s"https://github.com/VSCodium/vscodium/releases/download/$version"
val extensions = ISZ(
  "llvm-vs-code-extensions.vscode-clangd",
  "mads-hartmann.bash-ide-vscode",
  "mhutchie.git-graph",
  "ecmel.vscode-html-css",
  "kofuk.hugo-utils",
  "redhat.java",
  "James-Yu.latex-workshop",
  "ms-python.python",
  "rust-lang.rust-analyzer",
  "scalameta.metals",
  "sensmetry.sysml-2ls",
  "mshr-h.veriloghdl",
  "redhat.vscode-xml",
  "redhat.vscode-yaml",
  "adamraichu.zip-viewer"
)

def download(drop: Os.Path): Unit = {
  val url = s"$urlPrefix/${drop.name}"
  if (!drop.exists) {
    println(s"Downloading VSCodium ...")
    drop.downloadFrom(url)
    println()
  }
}

def mac(): Unit = {
  val drop = cacheDir / s"VSCodium-darwin-${if (Os.isMacArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "mac"
  val vscodium = platform / "VSCodium.app"
  val ver = vscodium / "Contents" / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    vscodium.removeAll()
    println("Extracting VSCodium ...")
    drop.unzipTo(platform)
    ver.write(version)
    proc"xattr -rd com.apple.quarantine $vscodium".run()
    proc"codesign --force --deep --sign - $vscodium".run()
    println()
    updated = T
  }
  (platform / "codium-portable-data").mkdirAll()
  val codium = vscodium / "Contents"/ "Resources" / "app" / "bin" / "codium"
  for (ext <- extensions) {
    proc"$codium --force --install-extension $ext".console.runCheck()
    println()
  }
  if (updated) {
    println(s"To launch VSCodium: open $vscodium")
  }
}

def linux(isArm: B): Unit = {
  val drop = cacheDir / s"VSCodium-linux-${if (isArm) "arm64" else "x64"}-$version.tar.gz"
  val platform: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    println("Extracting VSCodium ...")
    val vscodiumNew = platform / "vscodium.new"
    drop.unTarGzTo(vscodiumNew)
    if ((vscodium / "data").exists) {
      (vscodium / "data").moveTo(vscodiumNew / "data")
    } else {
      (vscodiumNew / "data").mkdirAll()
    }
    vscodium.removeAll()
    vscodiumNew.moveTo(vscodium)
    ver.write(version)
    println()
    updated = T
  }
  val codium = vscodium / "bin" / "codium"
  for (ext <- extensions) {
    proc"$codium --force --install-extension $ext".console.runCheck()
    println()
  }
  if (updated) {
    println(s"To launch VSCodium: $codium")
  }
}

def win(): Unit = {
  val drop = cacheDir / s"VSCodium-win32-${if (Os.isWinArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "win"
  val vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    download(drop)
    val vscodiumNew = platform / "vscodium.new"
    println("Extracting VSCodium ...")
    drop.unzipTo(vscodiumNew)
    if ((vscodium / "data").exists) {
      (vscodium / "data").moveTo(vscodiumNew / "data")
    } else {
      (vscodiumNew / "data").mkdirAll()
    }
    vscodium.removeAll()
    vscodiumNew.moveTo(vscodium)
    ver.write(version)
    println()
    updated = T
  }
  val codium = vscodium / "bin" / "codium.cmd"
  for (ext <- extensions) {
    proc"$codium --force --install-extension $ext".console.runCheck()
    println()
  }
  if (updated) {
    println(s"To launch VSCodium: $codium")
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