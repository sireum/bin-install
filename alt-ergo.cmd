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
val altErgoVersion = "2.6.1"

val cores: String = Os.cliArgs match {
  case ISZ(n) => Z(n).getOrElse(Os.numOfProcessors).string
  case _ => s"${Os.numOfProcessors}"
}


def altErgo(dir: Os.Path): Unit = {
  val env = ISZ("PATH" ~> s"${dir.up.canon}${Os.pathSep}${Os.env("PATH").get}")
  println(s"Installing Alt-Ergo $altErgoVersion ...")
  Os.proc(ISZ((dir.up / "opam").canon.string, "pin", s"--root=$dir", "remove", "alt-ergo", "-y")).runCheck()
  Os.proc(ISZ((dir.up / "opam").canon.string, "install", s"--root=$dir", "--no-self-upgrade", s"alt-ergo=$altErgoVersion", "-y", "-j", cores)).env(env).console.runCheck()
  Os.proc(ISZ((dir.up / "opam").canon.string, "pin", s"--root=$dir", "add", "alt-ergo", s"$altErgoVersion", "-y")).runCheck()
  println()
}

def install(platformDir: Os.Path): Unit = {
  val opamDir = platformDir / ".opam"
  val ver = platformDir / ".alt-ergo.ver"

  (Os.slashDir / "opam.cmd").slash(ISZ())

  if (ver.exists && ver.read == altErgoVersion) {
    return
  }

  println(
    st"""Note that:
        |  Alt-Ergo $altErgoVersion is not free software.
        |  This public release can only be used for non-commercial purposes.
        |  (see: https://github.com/OCamlPro/alt-ergo/blob/next/LICENSE.md)
        |""".render)

  val opam = opamDir.up / "opam"

  if (opam.exists) {
    Os.proc(ISZ(opam.canon.string, "update", s"--root=$opamDir")).console.runCheck()
  }

  (Os.slashDir / "menhir.cmd").slash(ISZ())

  altErgo(opamDir)

  ver.writeOver(altErgoVersion)

  println(s"Alt-Ergo is installed")
}


Os.kind match {
  case Os.Kind.Mac => install(homeBin / "mac")
  case Os.Kind.Linux => install(homeBin / "linux")
  case Os.Kind.LinuxArm => install(homeBin / "linux" / "arm")
  case _ =>
    eprintln("Unsupported platform")
    Os.exit(-1)
}
