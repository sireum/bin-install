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


val url = s"https://download.jetbrains.com/rustrover"

val homeBin = Os.slashDir.up.canon
val home = homeBin.up.canon
val rustRoverVersion = "2025.2.1"
val plugins = HashSSet.empty[String] ++ ISZ[String]("github", "gitlab", "rust", "toml")
val init = Init(home, Os.kind, Sireum.versions)
val rustRoverInstallVersion: String = st"$rustRoverVersion-${(for (pid <- plugins.elements) yield init.distroPlugins.get(pid).get.version, "-")}".render
val settingsDir: String = if (Os.isWin) ops.StringOps((home / ".settings").string).replaceAllChars('\\', '/') else (home / ".settings").string
val delPlugins = ISZ[String]("ml-llm")

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def installPlugins(pluginDir: Os.Path): Unit = {
  val pluginFilter = (p: Init.Plugin) => plugins.contains(p.id)
  init.downloadPlugins(F, pluginFilter)
  init.extractPlugins(pluginDir, pluginFilter)
}

def deletePlugins(pluginDir: Os.Path): Unit = {
  for (p <- delPlugins) {
    println(s"Removing $p plugin ...")
    println(pluginDir / p)
    (pluginDir / p).removeAll()
  }
}

def patchIdeaProperties(platform: String, p: Os.Path): Unit = {
  print(s"Patching $p ... ")
  val content = p.read
  val newContent: String = platform match {
    case "mac" =>
      s"idea.config.path=$settingsDir/.RustRover/config\nidea.system.path=$settingsDir/.RustRover/system\nidea.log.path=$settingsDir/.RustRover/log\nidea.plugins.path=$settingsDir/.RustRover/plugins\n$content"
    case "win" =>
      s"idea.config.path=$settingsDir/.RustRover/config\r\nidea.system.path=$settingsDir/.RustRover/system\r\nidea.log.path=$settingsDir/.RustRover/log\r\nidea.plugins.path=$settingsDir/.RustRover/plugins\r\n$content"
    case "linux" =>
      s"idea.config.path=$settingsDir/.RustRover/config\nidea.system.path=$settingsDir/.RustRover/system\nidea.log.path=$settingsDir/.RustRover/log\nidea.plugins.path=$settingsDir/.RustRover/plugins\n$content"
  }
  p.writeOver(newContent)
  println("done!")
}

def deleteSources(dir: Os.Path): Unit = {
  for (f <- Os.Path.walk(dir, F, F, (p: Os.Path) => ops.StringOps(p.name).endsWith(".java") || ops.StringOps(p.name).endsWith(".scala"))) {
    f.removeAll()
  }
}

def mac(): Unit = {
  val platformDir = homeBin / "mac"
  val rustRoverDir = platformDir / "rustrover"
  val rustRoverAppDir = rustRoverDir / "RustRover.app"
  val ver = rustRoverDir / "VER"

  if (ver.exists && ver.read == rustRoverInstallVersion) {
    return
  }

  val bundle = s"RustRover-$rustRoverVersion${if (ops.StringOps(proc"uname -m".redirectErr.run().out).trim == "arm64") "-aarch64" else ""}.dmg"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading RustRover $rustRoverVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (rustRoverDir.exists) {
    rustRoverDir.removeAll()
  }
  rustRoverDir.mkdirAll()

  println(s"Extracting $cache ...")
  Os.proc(ISZ("hdiutil", "attach", cache.string)).runCheck()
  for (dirPath <- Os.path("/Volumes").list if ops.StringOps(dirPath.name).startsWith("RustRover")) {
    for (p <- dirPath.list if ops.StringOps(p.name).startsWith("RustRover")) {
      p.copyTo(rustRoverAppDir)
    }
    Os.proc(ISZ("hdiutil", "eject", dirPath.string)).runCheck()
  }

  deleteSources(rustRoverDir)

  deletePlugins(rustRoverAppDir / "Contents" / "plugins")
  val pluginsDir = Os.path(settingsDir) / ".RustRover" / "plugins"
  pluginsDir.mkdirAll()
  installPlugins(pluginsDir)

  println()

  patchIdeaProperties("mac", rustRoverAppDir / "Contents" / "bin" / "idea.properties")

  proc"codesign --force --deep --sign - $rustRoverAppDir".run()

  ver.writeOver(rustRoverInstallVersion)

  println()
  println(s"RustRover is installed at $rustRoverDir")
}

def linux(isArm: B): Unit = {
  val platformDir: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val rustRoverDir = platformDir / "rustrover"
  val ver = rustRoverDir / "VER"

  if (ver.exists && ver.read == rustRoverInstallVersion) {
    return
  }

  val bundle = s"RustRover-$rustRoverVersion.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading RustRover $rustRoverVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (rustRoverDir.exists) {
    rustRoverDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  (platformDir / s"RustRover-$rustRoverVersion").moveTo(rustRoverDir)

  deleteSources(rustRoverDir)

  installPlugins(rustRoverDir / "plugins")
  deletePlugins(rustRoverDir / "plugins")

  println()

  patchIdeaProperties("linux", rustRoverDir / "bin" / "idea.properties")

  ver.writeOver(rustRoverInstallVersion)

  println()
  println(s"RustRover is installed at $rustRoverDir")
}

def win(): Unit = {
  val platformDir = homeBin / "win"
  val rustRoverDir = platformDir / "rustrover"
  val ver = rustRoverDir / "VER"

  if (ver.exists && ver.read == rustRoverInstallVersion) {
    return
  }

  val bundle: String = if (Os.isWinArm) s"RustRover-$rustRoverVersion-aarch64.exe" else s"RustRover-$rustRoverVersion.win.zip"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading RustRover $rustRoverVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (rustRoverDir.exists) {
    rustRoverDir.removeAll()
  }
  println(s"Extracting $cache ...")
  rustRoverDir.mkdirAll()

  cache.unzipTo(rustRoverDir)

  deleteSources(rustRoverDir)

  installPlugins(rustRoverDir / "plugins")
  deletePlugins(rustRoverDir / "plugins")

  println()

  patchIdeaProperties("win", rustRoverDir / "bin" / "idea.properties")

  ver.writeOver(rustRoverInstallVersion)

  println()
  println(s"RustRover is installed at $rustRoverDir")
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
