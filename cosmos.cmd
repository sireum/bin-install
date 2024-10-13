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

val version = "3.9.2"
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
  val ver = cosmos / "VER"
  if (ver.exists && ver.read == version) {
    return
  }
  cosmos.removeAll()
  cosmos.mkdirAll()

  println("Downloading Cosmos ...")
  download(cosmosDropName, cacheDir / cosmosDropName)
  download("web.zip", cacheDir / cosmosWebDropName)
  println()

  println("Extracting Cosmos ...")
  (cacheDir / cosmosDropName).unzipTo(cosmos)

  proc"${cosmos / "bin" / "unzip"} -n ${cacheDir / cosmosWebDropName}".script.at(cosmos).runCheck()

  for (p <- (cosmos / "bin").list if p.ext != "elf" && p.ext != "macho" && p.ext != "c") {
    if (Os.isWin) {
      val name: String = if (p.ext == "ape") ops.StringOps(p.name).substring(0, p.name.size - 4) else p.name
      p.moveTo(p.up / s"$name.exe")
    } else {
      p.chmod("+x")
    }
  }
  println()

  ver.writeOver(version)
  
  println(s"Cosmos is available at: $cosmos")
}

install()