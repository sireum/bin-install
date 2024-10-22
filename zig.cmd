::/*#! 2> /dev/null                                            #
@ 2>/dev/null # 2>nul & echo off & goto BOF                    #
export SIREUM_HOME=$(cd -P "$(dirname "$0")/../.." && pwd -P)  #
exec "${SIREUM_HOME}/bin/sireum" slang run "$0" "$@"           #
:BOF
setlocal
set SIREUM_HOME=%~dp0..\..
"%SIREUM_HOME%\bin\sireum.bat" slang run %0 %*
exit /B %errorlevel%
::!#*/
// #Sireum
import org.sireum._


val homeBin = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

val version = "0.14.0-dev.1952+9f84f7f92"
val urlPrefix = s"https://ziglang.org/builds"
val (os, arch, binPlatform): (String, String, Os.Path) = Os.kind match {
  case Os.Kind.Mac => if (Os.isMacArm) ("macos", "aarch64", homeBin / "mac") else ("macos", "x86_64", homeBin / "mac")
  case Os.Kind.Win => if (Os.isWinArm) ("windows", "aarch64", homeBin / "win") else ("windows", "x86_64", homeBin / "win")
  case Os.Kind.Linux => if (Os.isWinArm) ("linux", "aarch64", homeBin / "linux" / "arm") else ("linux", "x86_64", homeBin / "linux")
  case _ =>
    halt("Unsupported platform")
}
val zigDropName = s"zig-$os-$arch-$version.${if (Os.isWin) "zip" else "tar.xz"}"

def install(): Unit = {
  val zig = binPlatform / "zig"

  val ver = zig / "VER"
  if (ver.exists && ver.read == version) {
    return
  }
  zig.removeAll()
  zig.mkdirAll()

  val zigDrop = cacheDir / zigDropName
  if (!zigDrop.exists) {
    println(s"Downloading Zig $version ...")
    val url = s"$urlPrefix/${zigDrop.name}"
    zigDrop.downloadFrom(url)
    println()
  }

  println(s"Extracting Zig $version ...")
  val d = Os.tempDir()
  proc"tar xf $zigDrop".at(d).runCheck()
  d.list(0).moveTo(zig)
  println()

  ver.writeOver(version)
  
  println(s"Zig is available at: $zig")
}

install()