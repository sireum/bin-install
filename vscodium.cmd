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


val homeBin = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

val isInUserHome = ops.StringOps(s"${homeBin.up.canon}${Os.fileSep}").startsWith(Os.home.string)

val version = "1.92.2.24228"
val sireumExtVersion = "4.20240826.046a3a4"
val sysIdeVersion = "0.6.2"
val urlPrefix = s"https://github.com/VSCodium/vscodium/releases/download/$version"
val sireumExtUrl = s"https://github.com/sireum/vscode-extension/releases/download/$sireumExtVersion/sireum-vscode-extension.vsix"
val sireumExtDrop = s"sireum-vscode-extension-$sireumExtVersion.vsix"
val extensions = ISZ(
  "llvm-vs-code-extensions.vscode-clangd",
  "mike-lischke.vscode-antlr4",
  "mads-hartmann.bash-ide-vscode",
  "dbaeumer.vscode-eslint",
  "mhutchie.git-graph",
  "ecmel.vscode-html-css",
  "kofuk.hugo-utils",
  "redhat.java",
  "langium.langium-vscode",
  "James-Yu.latex-workshop",
  "jebbs.plantuml",
  "esbenp.prettier-vscode",
  "ms-python.python",
  "rust-lang.rust-analyzer",
  "scalameta.metals",
  s"sensmetry.sysml-2ls@$sysIdeVersion",
  "mshr-h.veriloghdl",
  "redhat.vscode-xml",
  "redhat.vscode-yaml",
  "adamraichu.zip-viewer"
)

def gumboTokens(existingKeywords: HashSet[String]): ISZ[String] = {
  val f = Os.tempFix("GUMBO", ".tokens")
  f.removeAll()
  f.downloadFrom("https://raw.githubusercontent.com/sireum/hamr-sysml-parser/master/src/org/sireum/hamr/sysml/parser/GUMBO.tokens")
  var r = ISZ[String]()
  for (key <- f.properties.keys) {
    val cis = conversions.String.toCis(key)
    if (cis(0) == '\'' && cis(cis.size - 1) == '\'' && ops.ISZOps(
      for (i <- 1 until cis.size - 1) yield
        ('a' <= cis(i) && cis(i) <= 'z') || ('A' <= cis(i) && cis(i) <= 'Z')).forall((b: B) => b)) {
      ops.StringOps.substring(cis, 1, cis.size - 1) match {
        case string"T" =>
        case string"F" =>
        case string"" =>
        case keyword if !existingKeywords.contains(keyword) => r = r :+ keyword
        case _ =>
      }
    }
  }
  return r
}

def patchSysIDE(d: Os.Path): Unit = {
  val tmlf = d / "syntaxes" / "sysml.tmLanguage.json"
  var content = tmlf.read
  val contentOps = ops.StringOps(content)
  if (contentOps.stringIndexOf(""""/\\*\\*/"""") >= 0) {
    return
  }
  def patchTml(): Unit = {
    val existingKeywords: HashSet[String] = {
      val i = contentOps.stringIndexOf("\\\\b(about|")
      val j = contentOps.stringIndexOfFrom(")\\\\b", i)
      HashSet ++ ops.StringOps(contentOps.substring(i, j)).split((c: C) => c == '|') + "about"
    }
    content = {
      val patterns: String = """"patterns": ["""
      val i = contentOps.stringIndexOf(patterns) + patterns.size
      val ins =
        st"""    {
            |      "match": "/\\*\\*/",
            |      "name": "string.quoted.other.sysml"
            |    },"""
      s"${contentOps.substring(0, i)}${Os.lineSep}${ins.render}${contentOps.substring(i, content.size)}"
    }
    content = ops.StringOps(content).replaceAllLiterally("\\\\b(about|", st"\\\\b(${(gumboTokens(existingKeywords), "|")}|about|".render)
    content = ops.StringOps(content).replaceAllLiterally("\"/\\\\*\"", "\"/\\\\*[^{]\"")
    tmlf.writeOver(content)
  }
  def patchJs(f: Os.Path): Unit = {
    def patchPrefix(text: String, prefix: String): String = {
      val cis = conversions.String.toCis(text)
      var i = ops.StringOps.stringIndexOfFrom(cis, conversions.String.toCis(prefix), 0)
      i = ops.StringOps.indexOfFrom(cis, '{', i + 1) + 1
      val j = ops.StringOps.indexOfFrom(cis, '}', i) + 3
      if (cis(j - 1) != ',') {
        return text
      }
      val s = ops.StringOps.substring(cis, i, j)
      if (!ops.StringOps(s).contains(".SysMLSemanticTokenTypes.annotationBody")) {
        return text
      }
      return conversions.String.fromCis(ops.ISZOps(cis).slice(0, i) ++ ops.ISZOps(cis).slice(j, cis.size))
    }
    f.writeOver(patchPrefix(patchPrefix(f.read, "comment("), "textualRep("))
  }
  println("Patching SysIDE ...")
  patchTml()
  for (f <- Os.Path.walk(d / "dist", F, F, (p: Os.Path) => p.ext == "js")) {
    patchJs(f)
  }
  println()
}

def downloadVSCodium(drop: Os.Path): Unit = {
  val url = s"$urlPrefix/${drop.name}"
  if (!drop.exists) {
    println(s"Downloading VSCodium ...")
    drop.downloadFrom(url)
    println()
  }
}

def installExtensions(codium: Os.Path, extensionsDir: Os.Path): String = {
  val extDirArg: String = if (isInUserHome) "" else s" --extensions-dir $extensionsDir"
  val drop = cacheDir / sireumExtDrop
  if (!drop.exists) {
    println("Downloading Sireum VSCode Extension ...")
    drop.downloadFrom(sireumExtUrl)
    println()
  }
  proc"$codium --force$extDirArg --install-extension $drop".console.runCheck()
  println()
  for (ext <- extensions) {
    proc"$codium --force$extDirArg --install-extension $ext".console.runCheck()
    println()
  }
  for (f <- extensionsDir.list if ops.StringOps(f.name).startsWith("sensmetry.sysml-")) {
    patchSysIDE(f)
  }
  return extDirArg
}

def mac(): Unit = {
  val drop = cacheDir / s"VSCodium-darwin-${if (Os.isMacArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "mac"
  val vscodium = platform / "VSCodium.app"
  val ver = vscodium / "Contents" / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    downloadVSCodium(drop)
    vscodium.removeAll()
    println("Extracting VSCodium ...")
    drop.unzipTo(platform)
    proc"codesign --force --deep --sign - $vscodium".run()
    ver.write(version)
    println()
    updated = T
  }
  val codium = vscodium / "Contents"/ "Resources" / "app" / "bin" / "codium"
  val extensionsDir: Os.Path = if (isInUserHome) {
    val d = platform / "codium-portable-data" / "extensions"
    d.mkdirAll()
    d
  } else {
    val d = vscodium.up.canon / "VSCodium-extensions"
    d.mkdirAll()
    d
  }
  val extDirArg = installExtensions(codium, extensionsDir)
  if (updated) {
    if (isInUserHome) {
      println(s"To launch VSCodium: open $vscodium")
    } else {
      println(s"To launch VSCodium: $codium$extDirArg")
    }
  }
}

def linux(isArm: B): Unit = {
  val drop = cacheDir / s"VSCodium-linux-${if (isArm) "arm64" else "x64"}-$version.tar.gz"
  val platform: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  val vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    downloadVSCodium(drop)
    println("Extracting VSCodium ...")
    val vscodiumNew = platform / "vscodium.new"
    drop.unTarGzTo(vscodiumNew)
    if ((vscodium / "data").exists) {
      (vscodium / "data").moveTo(vscodiumNew / "data")
    }
    vscodium.removeAll()
    vscodiumNew.moveTo(vscodium)
    ver.write(version)
    println()
    updated = T
  }
  val codium = vscodium / "bin" / "codium"
  val extensionsDir: Os.Path = if (isInUserHome) {
    val d = vscodium / "data" / "extensions"
    d.mkdirAll()
    d
  } else {
    val d = vscodium / "extensions"
    d.mkdirAll()
    d
  }
  val extDirArg = installExtensions(codium, extensionsDir)
  if (updated) {
    println(s"To launch VSCodium: $codium$extDirArg")
  }
}

def win(): Unit = {
  val drop = cacheDir / s"VSCodium-win32-${if (Os.isWinArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "win"
  val vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  if (!ver.exists || ver.read != version) {
    downloadVSCodium(drop)
    val vscodiumNew = platform / "vscodium.new"
    println("Extracting VSCodium ...")
    drop.unzipTo(vscodiumNew)
    if ((vscodium / "data").exists) {
      (vscodium / "data").moveTo(vscodiumNew / "data")
    }
    vscodium.removeAll()
    vscodiumNew.moveTo(vscodium)
    ver.write(version)
    println()
    updated = T
  }
  val codium = vscodium / "bin" / "codium.cmd"
  val extensionsDir: Os.Path = if (isInUserHome) {
    val d = vscodium / "data" / "extensions"
    d.mkdirAll()
    d
  } else {
    val d = vscodium / "extensions"
    d.mkdirAll()
    d
  }
  val extDirArg = installExtensions(codium, extensionsDir)
  if (updated) {
    println(s"To launch VSCodium: $codium$extDirArg")
  }
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