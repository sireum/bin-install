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
val menhirVersion = "20231231"

val cores: String = Os.cliArgs match {
  case ISZ(n) => Z(n).getOrElse(Os.numOfProcessors).string
  case _ => s"${Os.numOfProcessors}"
}


def menhir(dir: Os.Path): Unit = {
  println(s"Installing Menhir $menhirVersion ...")
  Os.proc(ISZ((dir.up / "opam").canon.string, "pin", s"--root=$dir", "remove", "menhir", "-y")).runCheck()
  Os.proc(ISZ((dir.up / "opam").canon.string, "install", s"--root=$dir", "--no-self-upgrade", s"menhir=$menhirVersion", "-y", "-j", cores)).console.runCheck()
  Os.proc(ISZ((dir.up / "opam").canon.string, "pin", s"--root=$dir", "add", "menhir", s"$menhirVersion", "-y")).runCheck()
  println()
}

def install(platformDir: Os.Path): Unit = {
  val opamDir = platformDir / ".opam"
  val ver = platformDir / ".menhir.ver"

  (Os.slashDir / "opam.cmd").slash(ISZ())

  if (ver.exists && ver.read == menhirVersion) {
    return
  }

  menhir(opamDir)

  ver.writeOver(menhirVersion)

  (platformDir / ".alt-ergo.ver").removeAll()
  (platformDir / ".compcert.ver").removeAll()

  println(s"Menhir is installed")
}


Os.kind match {
  case Os.Kind.Mac => install(homeBin / "mac")
  case Os.Kind.Linux => install(homeBin / "linux")
  case Os.Kind.LinuxArm => install(homeBin / "linux" / "arm")
  case _ =>
    eprintln("Unsupported platform")
    Os.exit(-1)
}
