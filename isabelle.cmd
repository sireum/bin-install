::/*#! 2> /dev/null                                            #
@ 2>/dev/null # 2>nul & echo off & goto BOF                    #
export SIREUM_HOME=$(cd -P "$(dirname "$0")/../.." && pwd -P)  #
exec "${SIREUM_HOME}/bin/sireum" slang run "$0" "$@"           #
:BOF
setlocal
set SIREUM_HOME=%~dp0../../
"%SIREUM_HOME%\sireum.bat" slang run %0 %*
exit /B %errorlevel%
::!#*/
// #Sireum
import org.sireum._


val version = "2024"
val homeBin: Os.Path = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def platform(kind: Os.Kind.Type): Unit = {
  val (bundle, binPlatform): (String, Os.Path) = kind match {
    case Os.Kind.Mac => (s"Isabelle${version}_macos.tar.gz", homeBin / "mac")
    case Os.Kind.Linux => (s"Isabelle${version}_linux.tar.gz", homeBin / "linux")
    case Os.Kind.LinuxArm => (s"Isabelle${version}_linux_arm.tar.gz", homeBin / "linux" / "arm")
    case Os.Kind.Win => (s"Isabelle${version}.exe", homeBin / "win")
    case _ =>
      println("Unsupported platform")
      Os.exit(-1)
      return
  }

  val isabelle = binPlatform / (if (kind == Os.Kind.Mac) "Isabelle.app" else "isabelle")
  val ver = isabelle / "VER"
  if (ver.exists && ver.read == version) {
    return
  }

  (binPlatform / (if (kind == Os.Kind.Mac) s"Isabelle$version.app" else s"Isabelle$version")).removeAll()
  isabelle.removeAll()

  val cachedBundle = cacheDir / bundle
  if (!cachedBundle.exists) {
    println(s"Please wait while downloading Isabelle $version ...")
    cachedBundle.downloadFrom(s"https://isabelle.in.tum.de/dist/$bundle")
    println()
  }

  println(s"Extracting Isabelle $version ...")
  if (kind == Os.Kind.Win) {
    val p7za: Os.Path = Os.kind match {
      case Os.Kind.Mac => homeBin / "mac" / "7za"
      case Os.Kind.Linux => homeBin / "linux" / "7za"
      case Os.Kind.LinuxArm => homeBin / "linux" / "arm" / "7za"
      case Os.Kind.Win => homeBin / "win" / "7za.exe"
      case _ => halt("Infeasible")
    }
    proc"$p7za x $cachedBundle".at(binPlatform).runCheck()
  } else {
    proc"tar xfz $cachedBundle".at(binPlatform).runCheck()
  }

  if (kind == Os.Kind.Mac) {
    (binPlatform / s"Isabelle$version.app").moveTo(isabelle)
    (isabelle / s"Isabelle$version").moveTo(isabelle / "Isabelle")
    ver.writeOver(version)
    proc"codesign --force --deep --sign - ${isabelle}".run()
  } else {
    (binPlatform / s"Isabelle$version").moveTo(isabelle)
    if (kind == Os.Kind.Win) {
      (isabelle / s"Isabelle$version.exe").moveTo(isabelle / "Isabelle.exe")
      (isabelle / s"Isabelle$version.exe.manifest").moveTo(isabelle / "Isabelle.exe.manifest")
      (isabelle / s"Isabelle$version.l4j.ini").moveTo(isabelle / "Isabelle.l4j.ini")
    } else {
      (isabelle / s"Isabelle$version").moveTo(isabelle / "Isabelle")
    }
    ver.writeOver(version)
  }
  println()
  println(s"Isabelle is available at $isabelle")
}

platform(Os.kind)
