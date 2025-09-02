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
val rocqVersion = "9.0.0"

val (cores, isIde): (String, B) = Os.cliArgs match {
  case ISZ(string"ide") => (Os.numOfProcessors.string, T)
  case ISZ(n) => (Z(n).getOrElse(Os.numOfProcessors).string, F)
  case ISZ(n, string"ide") => (Z(n).getOrElse(Os.numOfProcessors).string, T)
  case ISZ(string"ide", n) => (Z(n).getOrElse(Os.numOfProcessors).string, T)
  case _ => (Os.numOfProcessors.string, F)
}

def rocq(dir: Os.Path): Unit = {
  println(s"Installing Rocq${if (isIde) " IDE" else ""} $rocqVersion ...")
  val opam = (dir.up / "opam").canon.string
  val variant: String = if (isIde) "ide" else "-prover"
  if (isIde) {
    Os.proc(ISZ(opam, "pin", s"--root=$dir", "remove", s"rocqide", "-y")).runCheck()
  }
  Os.proc(ISZ(opam, "pin", s"--root=$dir", "remove", s"rocq-prover", "-y")).runCheck()
  Os.proc(ISZ(opam, "install", s"--root=$dir", "--no-self-upgrade", "--confirm-level=unsafe-yes", s"rocq$variant=$rocqVersion", "-y", "-j", cores)).console.runCheck()
  Os.proc(ISZ(opam, "pin", s"--root=$dir", "add", s"rocq-prover", s"$rocqVersion", "-y")).runCheck()
  if (isIde) {
    Os.proc(ISZ(opam, "pin", s"--root=$dir", "add", s"rocqide", s"$rocqVersion", "-y")).runCheck()
  }
  println()
}

def install(platformDir: Os.Path): Unit = {
  val opamDir = platformDir / ".opam"
  val ver = platformDir / ".rocq.ver"
  val ideVer = platformDir / ".rocqide.ver"

  (Os.slashDir / "opam.cmd").slash(ISZ())

  if (isIde && ideVer.exists && ideVer.read == rocqVersion) {
    return
  }

  val rocqExists = ver.exists && ver.read == rocqVersion
  if (!isIde && rocqExists) {
    return
  }

  rocq(opamDir)

  if (isIde) {
    ideVer.writeOver(rocqVersion)
  }

  if (!rocqExists) {
    (platformDir / ".compcert.ver").removeAll()
  }

  ver.writeOver(rocqVersion)

  println(s"Rocq${if (isIde) " IDE" else ""} is installed")
}


Os.kind match {
  case Os.Kind.Mac => install(homeBin / "mac")
  case Os.Kind.Linux => install(homeBin / "linux")
  case Os.Kind.LinuxArm => install(homeBin / "linux" / "arm")
  case _ =>
    eprintln("Unsupported platform")
    Os.exit(-1)
}
