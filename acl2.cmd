::/*#! 2> /dev/null                                            #
@ 2>/dev/null # 2>nul & echo off & goto BOF                    #
export SIREUM_HOME=$(cd -P "$(dirname "$0")/../.." && pwd -P)  #
exec "${SIREUM_HOME}/bin/sireum" slang run "$0" "$@"           #
:BOF
setlocal
set SIREUM_HOME=%~dp0..\..
"%SIREUM_HOME%\sireum.bat" slang run %0 %*
exit /B %errorlevel%
::!#*/
// #Sireum
import org.sireum._


def usage(): Unit = {
  println("Usage: [<num-of-cores>]")
}

val homeBin: Os.Path = Os.slashDir.up.canon
var cores: Z = 4

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def ccl(p: String): Unit = {
  val cclVersion = "1.12.1"
  val cclUrlPrefix = s"https://github.com/Clozure/ccl/releases/download/v$cclVersion/"
  val cclBundleMap: Map[String, String] = Map.empty[String, String] ++ ISZ(
    "linux" ~> s"ccl-$cclVersion-linuxx86.tar.gz",
    "mac" ~> s"ccl-$cclVersion-darwinx86.tar.gz"
  )

  val appDir = Os.home / "Applications"
  val cclDir = appDir / "ccl"
  val platformDir = homeBin / p
  val ver = platformDir / "ccl" / "VER"

  if (ver.exists && ver.read == cclVersion) {
    return
  }

  appDir.mkdirAll()

  val bundle = cclBundleMap.get(p).get

  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Clozure Common Lisp $cclVersion ...")
    cache.downloadFrom(s"$cclUrlPrefix/$bundle")
  }
  if (cclDir.exists) {
    cclDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(appDir).console.runCheck()
  platformDir.mkdirAll()
  (platformDir / "ccl").removeAll()
  proc"ln -s $cclDir .".at(platformDir).runCheck()

  ver.writeOver(cclVersion)
}

def acl2(p: String): Unit = {
  ccl(p)

  val acl2Version = "8.5"

  val acl2UrlPrefix = s"https://github.com/acl2-devel/acl2-devel/releases/download/$acl2Version/"

  val appDir = Os.home / "Applications"
  val acl2Dir = appDir / "acl2"
  val cclExe = appDir / "ccl" / (if (p == "linux") "lx86cl64" else "dx86cl64")
  val platformDir = homeBin / p
  val ver = platformDir / "acl2" / "VER"

  if (ver.exists && ver.read == acl2Version) {
    return
  }

  val bundle = s"acl2-$acl2Version.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading acl2 $acl2Version ...")
    cache.downloadFrom(s"$acl2UrlPrefix/$bundle")
  }
  if (acl2Dir.exists) {
    acl2Dir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(appDir).console.runCheck()
  (appDir / s"acl2-$acl2Version").moveTo(acl2Dir)
  platformDir.mkdirAll()
  (platformDir / "acl2").removeAll()
  proc"ln -s $acl2Dir .".at(platformDir).runCheck()

  val acl2 = acl2Dir / "saved_acl2"
  println(s"Creating $acl2 ...")
  Os.proc(ISZ("make", s"LISP=$cclExe")).at(acl2Dir).console.runCheck()

  println(s"Certifying acl2 books ...")
  Os.proc(ISZ("make", s"ACL2=$acl2", "-j", cores.string, "all")).at(acl2Dir / "books").console.runCheck()

  ver.writeOver(acl2Version)

  println(s"... done! ACL2 is installed at $acl2Dir")
}

def platform(p: String): Unit = {
  p match {
    case string"mac" =>
    case string"linux" =>
    case string"-h" =>
      usage()
      return
    case _ =>
      eprintln("Unsupported platform")
      usage()
      Os.exit(-1)
  }
  acl2(p)
}

if (Os.cliArgs.nonEmpty) {
  Z(Os.cliArgs(0)) match {
    case Some(n) => cores = n
    case _ =>
  }
}

Os.kind match {
  case Os.Kind.Mac =>
    val isArm: B = ops.StringOps(proc"uname -m".runCheck().out).trim == "arm64"
    platform(if (isArm) "???" else "mac")
  case Os.Kind.Linux => platform("linux")
  case Os.Kind.Win => platform("win")
  case _ => platform("???")
}