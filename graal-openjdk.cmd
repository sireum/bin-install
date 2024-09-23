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

val graalVersion = "23.0.0"

def usage(): Unit = {
  println("Usage: ( mac | linux | linux/arm | win )*")
}


val homeBin: Os.Path = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def url: String = {
  return  s"https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-$graalVersion"
}

def mac(isArm: B): Unit = {
  val platformDir = homeBin / "mac"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val arch: String = if (isArm) "aarch64" else "x64"
  val bundle = s"graalvm-community-jdk-${graalVersion}_macos-${arch}_bin.tar.gz"
  val cache = cacheDir / bundle
  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    println(s"$url/$bundle")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  for (p <- platformDir.list if ops.StringOps(p.name).startsWith("graalvm-community-openjdk")) {
    (p / "Contents" / "Home").moveTo(graalDir)
    p.removeAll()
  }

  ver.writeOver(version)

  println("... done!")
}

def linux(isArm: B): Unit = {
  val platformDir: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val arch: String = if (isArm) "aarch64" else "x64"
  val bundle = s"graalvm-community-jdk-${graalVersion}_linux-${arch}_bin.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  for (p <- platformDir.list if ops.StringOps(p.name).startsWith("graalvm-community-openjdk")) {
    p.moveTo(graalDir)
  }

  ver.writeOver(version)

  println("... done!")
}

def win(): Unit = {
  val platformDir = homeBin / "win"
  val graalDir = platformDir / "graal"
  val ver = graalDir / "VER"
  val version = s"$graalVersion"

  if (ver.exists && ver.read == version) {
    return
  }

  val arch = "x64"
  val bundle = s"graalvm-community-jdk-${graalVersion}_windows-${arch}_bin.zip"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading Graal $graalVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (graalDir.exists) {
    graalDir.removeAll()
  }
  println(s"Extracting $cache ...")
  cache.unzipTo(platformDir)
  for (p <- platformDir.list if ops.StringOps(p.name).startsWith("graalvm-community-openjdk")) {
    p.moveTo(graalDir)
  }

  ver.writeOver(version)

  println("... done!")
}

def platform(p: String): Unit = {
  p match {
    case string"mac" =>
      val isArm: B = ops.StringOps(proc"uname -m".runCheck().out).trim == "arm64"
      mac(isArm)
    case string"linux" => linux(F)
    case string"linux/arm" => linux(T)
    case string"win" => win()
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
