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

val version = Sireum.versions.get("org.sireum.version.cosmos").get
val urlPrefix = s"https://cosmo.zip/pub/cosmos/zip/"
val cosmosDropName = s"cosmos-$version.zip"
val cosmosWebDropName = s"cosmos-web-$version.zip"

def download(name: String, drop: Os.Path): Unit = {
  val url = s"$urlPrefix/$name"
  if (!drop.exists) {
    drop.downloadFrom(url)
    println()
  }
}

def install(): Unit = {
  val cosmos = homeBin / "cosmos"

  def updateBin(): Unit = {
    if (Os.isWin) {
      (cosmos / "bin" / "curl").removeAll()
      (cosmos / "bin" / "curl").mklink(Os.path("C:\\Windows\\System32\\curl.exe"))
      (cosmos / "bin" / "bash").moveTo(cosmos / "bin" / "bash.exe")
      (cosmos / "bin" / "bash").mklink(cosmos / "bin" / "bash.exe")
      (cosmos / "bin" / "zsh").moveTo(cosmos / "bin" / "zsh.exe")
      (cosmos / "bin" / "zsh").mklink(cosmos / "bin" / "zsh.exe")
    } else {
      for (p <- (cosmos / "bin").list) {
        p.chmod("+x")
      }
    }
  }

  val ver = cosmos / "VER"
  if (ver.exists && ver.read == version) {
    return
  }
  cosmos.removeAll()
  cosmos.mkdirAll()

  if (!(cacheDir / cosmosDropName).exists) {
    println("Downloading Cosmos ...")
    download(cosmosDropName, cacheDir / cosmosDropName)
    download("web.zip", cacheDir / cosmosWebDropName)
    println()
  }

  println("Extracting Cosmos ...")
  (cacheDir / cosmosDropName).unzipTo(cosmos)
  updateBin()

  proc"${cosmos / "bin" / (if (Os.isWin) "unzip.exe" else "unzip")} -n ${cacheDir / cosmosWebDropName}".script.at(cosmos).runCheck()
  updateBin()

  println()

  ver.writeOver(version)
  
  println(s"Cosmos is available at: $cosmos")
}

install()