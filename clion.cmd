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


val url = s"https://download.jetbrains.com/cpp"

val homeBin = Os.slashDir.up.canon
val home = homeBin.up.canon
val clionVersion = "2023.3.2"
val plugins = HashSSet.empty[String] ++ ISZ[String]("rust", "toml")
val init = Init(home, Os.kind, Sireum.versions)
val clionInstallVersion: String = st"$clionVersion-${(for (pid <- plugins.elements) yield init.distroPlugins.get(pid).get.ver, "-")}".render
val isLocal: B = ops.StringOps(home.string).startsWith(Os.home.canon.string) && (homeBin / "clean.sh").exists
val settingsDir: String = if (isLocal) if (Os.isWin) ops.StringOps((home / ".settings").string).replaceAllChars('\\', '/') else (home / ".settings").string else "${user.home}"
val delPlugins = ISZ[String]("ml-llm")

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def installPlugins(pluginDir: Os.Path): Unit = {
  val pluginFilter = (p: Init.Plugin) => plugins.contains(p.id)
  init.downloadPlugins(F, pluginFilter)
  init.extractPlugins(F, pluginDir, pluginFilter)
}

def deletePlugins(pluginDir: Os.Path): Unit = {
  for (p <- delPlugins) {
    println(s"Removing $p plugin ...")
    (pluginDir / p).removeAll()
  }
}

def patchIdeaProperties(platform: String, p: Os.Path): Unit = {
  print(s"Patching $p ... ")
  val content = p.read
  val newContent: String = platform match {
    case "mac" =>
      val contentOps = ops.StringOps(content)
      val i = contentOps.stringIndexOf("idea.paths.selector")
      val j = contentOps.stringIndexOfFrom("<string>", i)
      val k = contentOps.stringIndexOfFrom("</string>", j)
      if (isLocal) s"${contentOps.substring(0, j)}<string>.CLion</string>\n        <key>idea.config.path</key>\n        <string>$settingsDir/.CLion/config</string>\n        <key>idea.system.path</key>\n        <string>$settingsDir/.CLion/system</string>\n        <key>idea.log.path</key>\n        <string>$settingsDir/.CLion/log</string>\n        <key>idea.plugins.path</key>\n        <string>$settingsDir/.CLion/plugins${contentOps.substring(k, content.size)}"
      else s"${contentOps.substring(0, j)}<string>CLion${contentOps.substring(k, content.size)}"
    case "win" =>
      s"idea.config.path=$settingsDir/.CLion/config\r\nidea.system.path=$settingsDir/.CLion/system\r\nidea.log.path=$settingsDir/.CLion/log\r\nidea.plugins.path=$settingsDir/.CLion/plugins\r\n$content"
    case "linux" =>
      s"idea.config.path=$settingsDir/.CLion/config\nidea.system.path=$settingsDir/.CLion/system\nidea.log.path=$settingsDir/.CLion/log\nidea.plugins.path=$settingsDir/.CLion/plugins\n$content"
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
  val clionDir = platformDir / "clion"
  val clionAppDir = clionDir / "CLion.app"
  val ver = clionDir / "VER"

  if (ver.exists && ver.read == clionInstallVersion) {
    return
  }

  val bundle = s"CLion-$clionVersion${if (ops.StringOps(proc"uname -m".redirectErr.run().out).trim == "arm64") "-aarch64" else ""}.dmg"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading CLion $clionVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (clionDir.exists) {
    clionDir.removeAll()
  }

  println(s"Extracting $cache ...")
  Os.proc(ISZ("hdiutil", "attach", cache.string)).runCheck()
  val dirPath = Os.path("/Volumes/CLion")
  val appPath = dirPath / "CLion.app"
  clionDir.mkdirAll()
  appPath.copyTo(clionAppDir)
  Os.proc(ISZ("hdiutil", "eject", dirPath.string)).runCheck()

  deleteSources(clionDir)

  installPlugins(clionAppDir / "Contents" / "plugins")
  deletePlugins(clionDir / "plugins")

  println()

  patchIdeaProperties("mac", clionAppDir / "Contents" / "Info.plist")

  proc"codesign --force --deep --sign - $clionAppDir".run()

  ver.writeOver(clionInstallVersion)

  println()
  println(s"CLion is installed at $clionDir")
}

def linux(isArm: B): Unit = {
  val platformDir: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val clionDir = platformDir / "clion"
  val ver = clionDir / "VER"

  if (ver.exists && ver.read == clionInstallVersion) {
    return
  }

  val bundle = s"CLion-$clionVersion.tar.gz"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading CLion $clionVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (clionDir.exists) {
    clionDir.removeAll()
  }
  println(s"Extracting $cache ...")
  Os.proc(ISZ("tar", "xfz", cache.string)).at(platformDir).console.runCheck()
  (platformDir / s"clion-$clionVersion").moveTo(clionDir)

  deleteSources(clionDir)

  installPlugins(clionDir / "plugins")
  deletePlugins(clionDir / "plugins")

  println()

  patchIdeaProperties("linux", clionDir / "bin" / "idea.properties")

  ver.writeOver(clionInstallVersion)

  println()
  println(s"CLion is installed at $clionDir")
}

def win(): Unit = {
  val platformDir = homeBin / "win"
  val clionDir = platformDir / "clion"
  val ver = clionDir / "VER"

  if (ver.exists && ver.read == clionInstallVersion) {
    return
  }

  val bundle: String = if (Os.isWinArm) s"CLion-$clionVersion-aarch64.exe" else s"CLion-$clionVersion.win.zip"
  val cache = cacheDir / bundle

  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading CLion $clionVersion ...")
    cache.downloadFrom(s"$url/$bundle")
  }
  if (clionDir.exists) {
    clionDir.removeAll()
  }
  println(s"Extracting $cache ...")
  clionDir.mkdirAll()

  if (Os.isWinArm) {
    init.install7z()
    proc"${homeBin / "win" / "7z" / "7z.exe"} x $cache".at(clionDir).runCheck()
  } else {
    cache.unzipTo(clionDir)
  }

  deleteSources(clionDir)

  installPlugins(clionDir / "plugins")
  deletePlugins(clionDir / "plugins")

  println()

  patchIdeaProperties("win", clionDir / "bin" / "idea.properties")

  ver.writeOver(clionInstallVersion)

  println()
  println(s"CLion is installed at $clionDir")
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
