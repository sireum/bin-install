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

val version = "1.2.5"
val zlibVersion = "1.3.1"

def install(): Unit = {

  val homeBin = Os.slashDir.up.canon

  val binPlatform: Os.Path = Os.kind match {
    case Os.Kind.Linux => homeBin / "linux"
    case Os.Kind.LinuxArm => homeBin / "linux" / "arm"
    case _ =>
      println("musl-libc can only be installed in Linux")
      return
  }

  val musl = binPlatform / "musl"
  val ver = musl / "VER"
  val VER = s"$version-$zlibVersion"

  if (ver.exists && ver.read == VER) {
    return
  }

  val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
    case Some(dir) => Os.path(dir)
    case _ => Os.home / "Downloads" / "sireum"
  }

  val bundle = cacheDir / s"musl-$version.tar.gz"
  val zlibBundle = cacheDir / s"zlib-$zlibVersion.tar.gz"

  if (!bundle.exists) {
    println("Please wait while downloading musl-libc ...")
    bundle.downloadFrom(s"https://github.com/sireum/rolling/releases/download/misc/musl-$version.tar.gz")
    println()
  }

  if (!zlibBundle.exists) {
    println("Please wait while downloading zlib ...")
    zlibBundle.downloadFrom(s"https://github.com/sireum/rolling/releases/download/misc/zlib-$version.tar.gz")
    println()
  }

  musl.removeAll()

  val temp = Os.tempDir()
  println(s"Extracting musl-libc and zlib ...")
  bundle.unTarGzTo(temp)
  zlibBundle.unTarGzTo(temp)
  println()

  musl.mkdirAll()

  val muslDir = temp / s"musl-$version"
  val zlibDir = temp / s"zlib-$zlibVersion"

  println(s"Installing musl-libc to $musl")
  proc"./configure --prefix=$musl".at(muslDir).runCheck()
  proc"make -j4".at(muslDir).runCheck()
  proc"make install".at(muslDir).runCheck()
  println()

  val muslcc = musl / "bin" / "x86_64-linux-musl-gcc"
  muslcc.mklink(muslcc.up.canon / "musl-gcc")

  println(s"Installing zlib to $musl")
  proc"./configure --prefix=$musl --static".env(ISZ("CC" ~> muslcc.string)).at(zlibDir).runCheck()
  proc"make -j4".at(zlibDir).runCheck()
  proc"make install".at(zlibDir).runCheck()
  zlibDir.removeAll()
  println()

  temp.removeAll()

  ver.writeOver(VER)
}

install()