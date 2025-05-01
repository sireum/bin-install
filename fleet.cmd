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


val url = s"https://download.jetbrains.com/fleet/installers"
val homeBin = Os.slashDir.up.canon
val fleetVersion = "1.48.236"

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def mac(): Unit = {
  val platformDir = homeBin / "mac"
  val fleetDir = platformDir / "fleet"
  val fleetAppDir = fleetDir / "Fleet.app"
  val ver = fleetDir / "VER"

  if (ver.exists && ver.read == fleetVersion) {
    return
  }

  val bundle = s"Fleet-$fleetVersion${if (Os.isMacArm) "-aarch64" else ""}.dmg"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    val bundleUrl = s"$url/macos_${if (Os.isMacArm) "aarch64" else "x64"}/$bundle"
    println(s"Downloading Fleet $fleetVersion ...")
    cache.downloadFrom(bundleUrl)
  }
  if (fleetDir.exists) {
    fleetDir.removeAll()
  }
  fleetDir.mkdirAll()

  println(s"Extracting $cache ...")
  Os.proc(ISZ("hdiutil", "attach", cache.string)).runCheck()
  for (dirPath <- Os.path("/Volumes").list if ops.StringOps(dirPath.name).startsWith("Fleet")) {
    for (p <- dirPath.list if ops.StringOps(p.name).startsWith("Fleet")) {
      p.copyTo(fleetAppDir)
    }
    Os.proc(ISZ("hdiutil", "eject", dirPath.string)).runCheck()
  }

  println()

  proc"codesign --force --deep --sign - $fleetAppDir".run()

  ver.writeOver(fleetVersion)

  println()
  println(s"Fleet is installed at $fleetDir")
}

Os.kind match {
  case Os.Kind.Mac => mac()
  case _ =>
    eprintln("Unsupported platform")
    Os.exit(-1)
}
