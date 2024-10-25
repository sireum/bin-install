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

val version = Sireum.versions.get("org.sireum.version.cosmocc").get
val urlPrefix = s"https://github.com/jart/cosmopolitan/releases/download/$version"
val cosmoccDropName = s"cosmocc-$version.zip"

def install(): Unit = {
  val cosmocc = homeBin / "cosmocc"

  val ver = cosmocc / "VER"
  if (ver.exists && ver.read == version) {
    return
  }
  cosmocc.removeAll()
  cosmocc.mkdirAll()

  val cosmoccDrop = cacheDir / cosmoccDropName
  if (!cosmoccDrop.exists) {
    println(s"Downloading cosmocc $version ...")
    val url = s"$urlPrefix/${cosmoccDrop.name}"
    cosmoccDrop.downloadFrom(url)
    println()
  }

  println(s"Extracting cosmocc $version ...")
  if (Os.isLinux || Os.isLinuxArm) {
    proc"unzip -qq $cosmoccDrop".at(cosmocc).runCheck()
  } else {
    proc"tar xf $cosmoccDrop".at(cosmocc).runCheck()
  }
  println()

  ver.writeOver(version)
  
  println(s"cosmocc is available at: $cosmocc")
}

install()