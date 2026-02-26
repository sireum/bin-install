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

val wasmtimeVersion = "42.0.1"
val wasmedgeVersion = "0.16.1"
val wasmerVersion = "7.0.1"
val wabtVersion = "1.0.39"
val binaryenVersion = "126"
val wasmToolsVersion = "1.245.1"

val homeBin: Os.Path = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

def usage(): Unit = {
  println("Usage: ( mac | linux | linux/arm | win )*")
}

def install(platformDir: Os.Path, name: String, version: String,
            url: String, bundle: String, prefix: String, isZip: B): Unit = {
  val dir = platformDir / name
  val ver = dir / "VER"
  if (ver.exists && ver.read == version) {
    return
  }

  val cache = cacheDir / bundle
  if (!cache.exists) {
    cache.up.mkdirAll()
    println(s"Downloading $name $version ...")
    println(url)
    cache.downloadFrom(url)
  }

  if (dir.exists) {
    dir.removeAll()
  }

  println(s"Extracting $cache ...")
  if (prefix == "") {
    // Flat archive (no top-level directory) — extract into target dir
    dir.mkdirAll()
    if (isZip) {
      cache.unzipTo(dir)
    } else {
      Os.proc(ISZ("tar", "xf", cache.string)).at(dir).console.runCheck()
    }
  } else {
    // Archive with top-level directory — extract at parent, then rename
    if (isZip) {
      cache.unzipTo(platformDir)
    } else {
      Os.proc(ISZ("tar", "xf", cache.string)).at(platformDir).console.runCheck()
    }
    for (p <- platformDir.list if ops.StringOps(p.name).startsWith(prefix)) {
      p.moveTo(dir)
    }
  }

  ver.writeOver(version)
  println(s"$name $version installed!")
}

def mac(isArm: B): Unit = {
  val platformDir = homeBin / "mac"

  // wasmtime
  val wasmtimeArch: String = if (isArm) "aarch64" else "x86_64"
  val wasmtimeBundle = s"wasmtime-v$wasmtimeVersion-$wasmtimeArch-macos.tar.xz"
  install(platformDir = platformDir, name = "wasmtime", version = wasmtimeVersion,
    url = s"https://github.com/bytecodealliance/wasmtime/releases/download/v$wasmtimeVersion/$wasmtimeBundle",
    bundle = wasmtimeBundle, prefix = "wasmtime-v", isZip = F)

  // wasmedge (flat archive — no top-level directory)
  val wasmedgeArch: String = if (isArm) "arm64" else "x86_64"
  val wasmedgeBundle = s"WasmEdge-$wasmedgeVersion-darwin_$wasmedgeArch.tar.gz"
  install(platformDir = platformDir, name = "wasmedge", version = wasmedgeVersion,
    url = s"https://github.com/WasmEdge/WasmEdge/releases/download/$wasmedgeVersion/$wasmedgeBundle",
    bundle = wasmedgeBundle, prefix = "", isZip = F)

  // wasmer
  val wasmerArch: String = if (isArm) "arm64" else "amd64"
  val wasmerBundle = s"wasmer-darwin-$wasmerArch.tar.gz"
  install(platformDir = platformDir, name = "wasmer", version = wasmerVersion,
    url = s"https://github.com/wasmerio/wasmer/releases/download/v$wasmerVersion/$wasmerBundle",
    bundle = wasmerBundle, prefix = "", isZip = F)

  // wabt (arm64 only — no macOS x86_64 binaries since v1.0.37)
  if (isArm) {
    val wabtBundle = s"wabt-$wabtVersion-macos-arm64.tar.gz"
    install(platformDir = platformDir, name = "wabt", version = wabtVersion,
      url = s"https://github.com/WebAssembly/wabt/releases/download/$wabtVersion/$wabtBundle",
      bundle = wabtBundle, prefix = "wabt-", isZip = F)
  } else {
    println("Note: WABT does not provide macOS x86_64 binaries; use Rosetta 2 with arm64 or Homebrew")
  }

  // binaryen
  val binaryenArch: String = if (isArm) "arm64" else "x86_64"
  val binaryenBundle = s"binaryen-version_$binaryenVersion-$binaryenArch-macos.tar.gz"
  install(platformDir = platformDir, name = "binaryen", version = binaryenVersion,
    url = s"https://github.com/WebAssembly/binaryen/releases/download/version_$binaryenVersion/$binaryenBundle",
    bundle = binaryenBundle, prefix = "binaryen-", isZip = F)

  // wasm-tools
  val wasmToolsArch: String = if (isArm) "aarch64" else "x86_64"
  val wasmToolsBundle = s"wasm-tools-$wasmToolsVersion-$wasmToolsArch-macos.tar.gz"
  install(platformDir = platformDir, name = "wasm-tools", version = wasmToolsVersion,
    url = s"https://github.com/bytecodealliance/wasm-tools/releases/download/v$wasmToolsVersion/$wasmToolsBundle",
    bundle = wasmToolsBundle, prefix = s"wasm-tools-$wasmToolsVersion", isZip = F)
}

def linux(isArm: B): Unit = {
  val platformDir: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"

  // wasmtime
  val wasmtimeArch: String = if (isArm) "aarch64" else "x86_64"
  val wasmtimeBundle = s"wasmtime-v$wasmtimeVersion-$wasmtimeArch-linux.tar.xz"
  install(platformDir = platformDir, name = "wasmtime", version = wasmtimeVersion,
    url = s"https://github.com/bytecodealliance/wasmtime/releases/download/v$wasmtimeVersion/$wasmtimeBundle",
    bundle = wasmtimeBundle, prefix = "wasmtime-v", isZip = F)

  // wasmedge (flat archive — no top-level directory)
  val wasmedgeArch: String = if (isArm) "aarch64" else "x86_64"
  val wasmedgeBundle = s"WasmEdge-$wasmedgeVersion-manylinux_2_28_$wasmedgeArch.tar.gz"
  install(platformDir = platformDir, name = "wasmedge", version = wasmedgeVersion,
    url = s"https://github.com/WasmEdge/WasmEdge/releases/download/$wasmedgeVersion/$wasmedgeBundle",
    bundle = wasmedgeBundle, prefix = "", isZip = F)

  // wasmer
  val wasmerSuffix: String = if (isArm) "linux-aarch64" else "linux-amd64"
  val wasmerBundle = s"wasmer-$wasmerSuffix.tar.gz"
  install(platformDir = platformDir, name = "wasmer", version = wasmerVersion,
    url = s"https://github.com/wasmerio/wasmer/releases/download/v$wasmerVersion/$wasmerBundle",
    bundle = wasmerBundle, prefix = "", isZip = F)

  // wabt
  val wabtArch: String = if (isArm) "arm64" else "x64"
  val wabtBundle = s"wabt-$wabtVersion-linux-$wabtArch.tar.gz"
  install(platformDir = platformDir, name = "wabt", version = wabtVersion,
    url = s"https://github.com/WebAssembly/wabt/releases/download/$wabtVersion/$wabtBundle",
    bundle = wabtBundle, prefix = "wabt-", isZip = F)

  // binaryen
  val binaryenArch: String = if (isArm) "aarch64" else "x86_64"
  val binaryenBundle = s"binaryen-version_$binaryenVersion-$binaryenArch-linux.tar.gz"
  install(platformDir = platformDir, name = "binaryen", version = binaryenVersion,
    url = s"https://github.com/WebAssembly/binaryen/releases/download/version_$binaryenVersion/$binaryenBundle",
    bundle = binaryenBundle, prefix = "binaryen-", isZip = F)

  // wasm-tools
  val wasmToolsArch: String = if (isArm) "aarch64" else "x86_64"
  val wasmToolsBundle = s"wasm-tools-$wasmToolsVersion-$wasmToolsArch-linux.tar.gz"
  install(platformDir = platformDir, name = "wasm-tools", version = wasmToolsVersion,
    url = s"https://github.com/bytecodealliance/wasm-tools/releases/download/v$wasmToolsVersion/$wasmToolsBundle",
    bundle = wasmToolsBundle, prefix = s"wasm-tools-$wasmToolsVersion", isZip = F)
}

def win(): Unit = {
  val platformDir = homeBin / "win"

  // wasmtime
  val wasmtimeBundle = s"wasmtime-v$wasmtimeVersion-x86_64-windows.zip"
  install(platformDir = platformDir, name = "wasmtime", version = wasmtimeVersion,
    url = s"https://github.com/bytecodealliance/wasmtime/releases/download/v$wasmtimeVersion/$wasmtimeBundle",
    bundle = wasmtimeBundle, prefix = "wasmtime-v", isZip = T)

  // wasmedge (flat archive — no top-level directory)
  val wasmedgeBundle = s"WasmEdge-$wasmedgeVersion-windows.zip"
  install(platformDir = platformDir, name = "wasmedge", version = wasmedgeVersion,
    url = s"https://github.com/WasmEdge/WasmEdge/releases/download/$wasmedgeVersion/$wasmedgeBundle",
    bundle = wasmedgeBundle, prefix = "", isZip = T)

  // wasmer
  val wasmerBundle = "wasmer-windows-amd64.tar.gz"
  install(platformDir = platformDir, name = "wasmer", version = wasmerVersion,
    url = s"https://github.com/wasmerio/wasmer/releases/download/v$wasmerVersion/$wasmerBundle",
    bundle = wasmerBundle, prefix = "", isZip = F)

  // wabt
  val wabtBundle = s"wabt-$wabtVersion-windows-x64.tar.gz"
  install(platformDir = platformDir, name = "wabt", version = wabtVersion,
    url = s"https://github.com/WebAssembly/wabt/releases/download/$wabtVersion/$wabtBundle",
    bundle = wabtBundle, prefix = "wabt-", isZip = F)

  // binaryen
  val binaryenBundle = s"binaryen-version_$binaryenVersion-x86_64-windows.tar.gz"
  install(platformDir = platformDir, name = "binaryen", version = binaryenVersion,
    url = s"https://github.com/WebAssembly/binaryen/releases/download/version_$binaryenVersion/$binaryenBundle",
    bundle = binaryenBundle, prefix = "binaryen-", isZip = F)

  // wasm-tools
  val wasmToolsBundle = s"wasm-tools-$wasmToolsVersion-x86_64-windows.zip"
  install(platformDir = platformDir, name = "wasm-tools", version = wasmToolsVersion,
    url = s"https://github.com/bytecodealliance/wasm-tools/releases/download/v$wasmToolsVersion/$wasmToolsBundle",
    bundle = wasmToolsBundle, prefix = s"wasm-tools-$wasmToolsVersion", isZip = T)
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
