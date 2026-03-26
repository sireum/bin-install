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

val version = "20260311"
val urlPrefix = s"https://github.com/mstorsjo/llvm-mingw/releases/download/$version"

def dropName(): String = {
  if (Os.isMac) {
    return s"llvm-mingw-$version-ucrt-macos-universal.tar.xz"
  }
  if (Os.isLinux) {
    val arch = Os.prop("os.arch").getOrElse("x86_64")
    if (arch == "aarch64" || arch == "arm64") {
      return s"llvm-mingw-$version-ucrt-ubuntu-22.04-aarch64.tar.xz"
    } else {
      return s"llvm-mingw-$version-ucrt-ubuntu-22.04-x86_64.tar.xz"
    }
  }
  if (Os.isWin) {
    return s"llvm-mingw-$version-ucrt-x86_64.zip"
  }
  halt("Unsupported platform")
}

def install(): Unit = {
  val platformDir: String = {
    if (Os.isMac) "mac"
    else if (Os.isLinux) {
      val arch = Os.prop("os.arch").getOrElse("x86_64")
      if (arch == "aarch64" || arch == "arm64") "linux/arm" else "linux"
    }
    else if (Os.isWin) "win"
    else halt("Unsupported platform")
  }
  val llvmMingw = homeBin / platformDir / "llvm-mingw"

  val ver = llvmMingw / "VER"
  if (ver.exists && ver.read == version) {
    return
  }
  llvmMingw.removeAll()
  llvmMingw.mkdirAll()

  val drop = cacheDir / dropName()
  if (!drop.exists) {
    println(s"Downloading llvm-mingw $version ...")
    val url = s"$urlPrefix/${drop.name}"
    drop.downloadFrom(url)
    println()
  }

  println(s"Extracting llvm-mingw $version ...")
  if (ops.StringOps(drop.name).endsWith(".zip")) {
    if (Os.isLinux) {
      proc"unzip -qq $drop".at(llvmMingw).runCheck()
    } else {
      proc"tar xf $drop".at(llvmMingw).runCheck()
    }
  } else {
    proc"tar xf $drop".at(llvmMingw).runCheck()
  }

  // The tarball extracts to a subdirectory — move contents up
  val extracted = ops.ISZOps(llvmMingw.list).filter(p => p.isDir && ops.StringOps(p.name).startsWith("llvm-mingw-"))
  if (extracted.size == z"1") {
    for (f <- extracted(0).list) {
      f.moveTo(llvmMingw / f.name)
    }
    extracted(0).removeAll()
  }
  println()

  ver.writeOver(version)

  println(s"llvm-mingw is available at: $llvmMingw")
  println(s"  x86_64:  ${llvmMingw / "bin" / "x86_64-w64-mingw32-clang"}")
  println(s"  aarch64: ${llvmMingw / "bin" / "aarch64-w64-mingw32-clang"}")
}

install()
