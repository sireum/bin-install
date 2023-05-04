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


def usage(): Unit = {
  println("Usage: ( mac | linux | linux/arm | win )*")
}


val homeBin: Os.Path = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

@strictpure def url(graalVersion: String) = s"https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$graalVersion"

def mac(isArm: B, javaVersion: String, graalVersion: String): Unit = {
  val platformDir = homeBin / "mac"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$javaVersion-$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val arch: String = if (isArm) "aarch64" else "amd64"
  val bundle = s"graalvm-ce-java$javaVersion-darwin-$arch-$graalVersion.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    cache.downloadFrom(s"${url(graalVersion)}/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  (platformDir / s"graalvm-ce-java$javaVersion-$graalVersion" / "Contents" / "Home").moveTo(graalDir)
  (platformDir / s"graalvm-ce-java$javaVersion-$graalVersion").removeAll()

  val nativeBundle = s"native-image-installable-svm-java$javaVersion-darwin-$arch-$graalVersion.jar"
  val nativeCache = cacheDir / nativeBundle
  if (!nativeCache.exists) {
    println(s"Downloading Graal's native-image ...")
    nativeCache.downloadFrom(s"${url(graalVersion)}/$nativeBundle")
  }

  Os.proc(ISZ((graalDir / "bin" / "gu").string, "install", "--file", nativeCache.string)).console.runCheck()

  ver.writeOver(version)

  println("... done!")
}

def linux(isArm: B, javaVersion: String, graalVersion: String): Unit = {
  val platformDir: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$javaVersion-$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val arch: String = if (isArm) "aarch64" else "amd64"
  val bundle = s"graalvm-ce-java$javaVersion-linux-$arch-$graalVersion.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    cache.downloadFrom(s"${url(graalVersion)}/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  (platformDir / s"graalvm-ce-java$javaVersion-$graalVersion").moveTo(graalDir)

  val nativeBundle = s"native-image-installable-svm-java$javaVersion-linux-$arch-$graalVersion.jar"
  val nativeCache = cacheDir / nativeBundle
  if (!nativeCache.exists) {
    println(s"Downloading Graal's native-image ...")
    nativeCache.downloadFrom(s"${url(graalVersion)}/$nativeBundle")
  }

  Os.proc(ISZ((graalDir / "bin" / "gu").string, "install", "--file", nativeCache.string)).console.runCheck()

  ver.writeOver(version)

  println("... done!")
}

def win(javaVersion: String, graalVersion: String): Unit = {
  val platformDir = homeBin / "win"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$javaVersion-$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val bundle = s"graalvm-ce-java$javaVersion-windows-amd64-$graalVersion.zip"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    cache.downloadFrom(s"${url(graalVersion)}/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  cache.unzipTo(platformDir)
  (platformDir / s"graalvm-ce-java$javaVersion-$graalVersion").moveTo(graalDir)

  val nativeBundle = s"native-image-installable-svm-java$javaVersion-windows-amd64-$graalVersion.jar"
  val nativeCache = cacheDir / nativeBundle
  if (!nativeCache.exists) {
    println(s"Downloading Graal's native-image ...")
    nativeCache.downloadFrom(s"${url(graalVersion)}/$nativeBundle")
  }

  Os.proc(ISZ((graalDir / "bin" / "gu.cmd").string, "install", "--file", nativeCache.string)).console.runCheck()

  ver.writeOver(version)

  println("... done!")
}

def platform(p: String): Unit = {
  val graalVersion = "22.3.2"
  val javaVersion = "17"
  p match {
    case string"mac" =>
      val isArm: B = ops.StringOps(proc"uname -m".runCheck().out).trim == "arm64"
      if (isArm) {
        mac(T, "19", "22.3.1")
      } else {
        mac(F, javaVersion, graalVersion)
      }
      mac(F, javaVersion, graalVersion)
    case string"linux" => linux(F, javaVersion, graalVersion)
    case string"linux/arm" => linux(T, javaVersion, graalVersion)
    case string"win" => win(javaVersion, graalVersion)
    case string"-h" => usage()
    case _ =>
      eprintln("Unsupported platform")
      usage()
      Os.exit(-1)
  }
}

if (Os.cliArgs.isEmpty) {
  Os.kind match {
    case Os.Kind.Mac => platform("mac")
    case Os.Kind.Linux => platform("linux")
    case Os.Kind.LinuxArm => platform("linux/arm")
    case Os.Kind.Win => platform("win")
    case _ => platform("???")
  }
} else {
  for (p <- (HashSSet.empty[String] ++ Os.cliArgs).elements) {
    platform(p)
  }
}

