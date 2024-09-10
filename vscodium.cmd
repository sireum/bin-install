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
// @formatter:off

// This file is auto-generated from vscodium-cli.sc

import org.sireum._

object Cli {

  @datatype trait VscodiumTopOption

  @datatype class HelpOption extends VscodiumTopOption

  @datatype class VscodiumOption(
    val help: String,
    val args: ISZ[String],
    val existingInstall: Option[String],
    val extensions: ISZ[String],
    val extensionsDir: Option[String]
  ) extends VscodiumTopOption
}

import Cli._

@record class Cli(val pathSep: C) {

  def parseVscodium(args: ISZ[String], i: Z): Option[VscodiumTopOption] = {
    val help =
      st"""VSCodium Installer
          |
          |Usage: <options>*
          |
          |Available Options:
          |    --existing-install   VSCodium/VSCode existing installation path (expects a
          |                           path)
          |    --extensions         List of extensions to be installed (excluding Sireum
          |                           and SysIDE) (expects a string separated by ",";
          |                           default is
          |                           "llvm-vs-code-extensions.vscode-clangd,mike-lischke.vscode-antlr4,mads-hartmann.bash-ide-vscode,dbaeumer.vscode-eslint,mhutchie.git-graph,ecmel.vscode-html-css,kofuk.hugo-utils,redhat.java,langium.langium-vscode,James-Yu.latex-workshop,jebbs.plantuml,esbenp.prettier-vscode,ms-python.python,rust-lang.rust-analyzer,scalameta.metals,mshr-h.veriloghdl,redhat.vscode-xml,redhat.vscode-yaml,adamraichu.zip-viewer")
          |    --extensions-dir     Custom VSCodium/VSCode extensions directory (expects a
          |                           path)
          |-h, --help               Display this information""".render

    var existingInstall: Option[String] = None[String]()
    var extensions: ISZ[String] = ISZ("llvm-vs-code-extensions.vscode-clangd", "mike-lischke.vscode-antlr4", "mads-hartmann.bash-ide-vscode", "dbaeumer.vscode-eslint", "mhutchie.git-graph", "ecmel.vscode-html-css", "kofuk.hugo-utils", "redhat.java", "langium.langium-vscode", "James-Yu.latex-workshop", "jebbs.plantuml", "esbenp.prettier-vscode", "ms-python.python", "rust-lang.rust-analyzer", "scalameta.metals", "mshr-h.veriloghdl", "redhat.vscode-xml", "redhat.vscode-yaml", "adamraichu.zip-viewer")
    var extensionsDir: Option[String] = None[String]()
    var j = i
    var isOption = T
    while (j < args.size && isOption) {
      val arg = args(j)
      if (ops.StringOps(arg).first == '-') {
        if (args(j) == "-h" || args(j) == "--help") {
          println(help)
          return Some(HelpOption())
        } else if (arg == "--existing-install") {
           val o: Option[Option[String]] = parsePath(args, j + 1)
           o match {
             case Some(v) => existingInstall = v
             case _ => return None()
           }
         } else if (arg == "--extensions") {
           val o: Option[ISZ[String]] = parseStrings(args, j + 1, ',')
           o match {
             case Some(v) => extensions = v
             case _ => return None()
           }
         } else if (arg == "--extensions-dir") {
           val o: Option[Option[String]] = parsePath(args, j + 1)
           o match {
             case Some(v) => extensionsDir = v
             case _ => return None()
           }
         } else {
          eprintln(s"Unrecognized option '$arg'.")
          return None()
        }
        j = j + 2
      } else {
        isOption = F
      }
    }
    return Some(VscodiumOption(help, parseArguments(args, j), existingInstall, extensions, extensionsDir))
  }

  def parseArguments(args: ISZ[String], i: Z): ISZ[String] = {
    var r = ISZ[String]()
    var j = i
    while (j < args.size) {
      r = r :+ args(j)
      j = j + 1
    }
    return r
  }

  def parsePaths(args: ISZ[String], i: Z): Option[ISZ[String]] = {
    return tokenize(args, i, "path", pathSep, F)
  }

  def parsePath(args: ISZ[String], i: Z): Option[Option[String]] = {
    if (i >= args.size) {
      eprintln("Expecting a path, but none found.")
    }
    return Some(Some(args(i)))
  }

  def parseStrings(args: ISZ[String], i: Z, sep: C): Option[ISZ[String]] = {
    tokenize(args, i, "string", sep, F) match {
      case r@Some(_) => return r
      case _ => return None()
    }
  }

  def parseString(args: ISZ[String], i: Z): Option[Option[String]] = {
    if (i >= args.size) {
      eprintln("Expecting a string, but none found.")
      return None()
    }
    return Some(Some(args(i)))
  }

  def parseNums(args: ISZ[String], i: Z, sep: C, minOpt: Option[Z], maxOpt: Option[Z]): Option[ISZ[Z]] = {
    tokenize(args, i, "integer", sep, T) match {
      case Some(sargs) =>
        var r = ISZ[Z]()
        for (arg <- sargs) {
          parseNumH(F, arg, minOpt, maxOpt)._2 match {
            case Some(n) => r = r :+ n
            case _ => return None()
          }
        }
        return Some(r)
      case _ => return None()
    }
  }

  def tokenize(args: ISZ[String], i: Z, tpe: String, sep: C, removeWhitespace: B): Option[ISZ[String]] = {
    if (i >= args.size) {
      eprintln(s"Expecting a sequence of $tpe separated by '$sep', but none found.")
      return None()
    }
    val arg = args(i)
    return Some(tokenizeH(arg, sep, removeWhitespace))
  }

  def tokenizeH(arg: String, sep: C, removeWhitespace: B): ISZ[String] = {
    val argCis = conversions.String.toCis(arg)
    var r = ISZ[String]()
    var cis = ISZ[C]()
    var j = 0
    while (j < argCis.size) {
      val c = argCis(j)
      if (c == sep) {
        r = r :+ conversions.String.fromCis(cis)
        cis = ISZ[C]()
      } else {
        val allowed: B = c match {
          case c"\n" => !removeWhitespace
          case c" " => !removeWhitespace
          case c"\r" => !removeWhitespace
          case c"\t" => !removeWhitespace
          case _ => T
        }
        if (allowed) {
          cis = cis :+ c
        }
      }
      j = j + 1
    }
    if (cis.size > 0) {
      r = r :+ conversions.String.fromCis(cis)
    }
    return r
  }

  def parseNumChoice(args: ISZ[String], i: Z, choices: ISZ[Z]): Option[Z] = {
    val set = HashSet.empty[Z] ++ choices
    parseNum(args, i, None(), None()) match {
      case r@Some(n) =>
        if (set.contains(n)) {
          return r
        } else {
          eprintln(s"Expecting one of the following: $set, but found $n.")
          return None()
        }
      case r => return r
    }
  }

  def parseNum(args: ISZ[String], i: Z, minOpt: Option[Z], maxOpt: Option[Z]): Option[Z] = {
    if (i >= args.size) {
      eprintln(s"Expecting an integer, but none found.")
      return None()
    }
    return parseNumH(F, args(i), minOpt, maxOpt)._2
  }

  def parseNumFlag(args: ISZ[String], i: Z, minOpt: Option[Z], maxOpt: Option[Z]): Option[Option[Z]] = {
    if (i >= args.size) {
      return Some(None())
    }
    parseNumH(T, args(i), minOpt, maxOpt) match {
      case (T, vOpt) => return Some(vOpt)
      case _ => return None()
    }
  }

  def parseNumH(optArg: B, arg: String, minOpt: Option[Z], maxOpt: Option[Z]): (B, Option[Z]) = {
    Z(arg) match {
      case Some(n) =>
        minOpt match {
          case Some(min) =>
            if (n < min) {
              eprintln(s"Expecting an integer at least $min, but found $n.")
              return (F, None())
            }
          case _ =>
        }
        maxOpt match {
          case Some(max) =>
            if (n > max) {
              eprintln(s"Expecting an integer at most $max, but found $n.")
              return (F, None())
            }
          case _ =>
        }
        return (T, Some(n))
      case _ =>
        if (!optArg) {
          eprintln(s"Expecting an integer, but found '$arg'.")
          return (F, None())
        } else {
          return (T, None())
       }
    }
  }

  def select(mode: String, args: ISZ[String], i: Z, choices: ISZ[String]): Option[String] = {
    val arg = args(i)
    var cs = ISZ[String]()
    for (c <- choices) {
      if (ops.StringOps(c).startsWith(arg)) {
        cs = cs :+ c
      }
    }
    cs.size match {
      case z"0" =>
        eprintln(s"$arg is not a mode of $mode.")
        return None()
      case z"1" => return Some(cs(0))
      case _ =>
        eprintln(
          st"""Which one of the following modes did you mean by '$arg'?
              |${(cs, "\n")}""".render)
        return None()
    }
  }
}
// @formatter:on

// BEGIN USER CODE
val homeBin = Os.slashDir.up.canon

val cacheDir: Os.Path = Os.env("SIREUM_CACHE") match {
  case Some(dir) => Os.path(dir)
  case _ => Os.home / "Downloads" / "sireum"
}

val isInUserHome = ops.StringOps(s"${homeBin.up.canon}${Os.fileSep}").startsWith(Os.home.string)

val version = "1.93.0.24253"
val sireumExtVersion = "4.20240910.a8e20d5"
val sysIdeVersion = "0.6.2"
val urlPrefix = s"https://github.com/VSCodium/vscodium/releases/download/$version"
val sireumExtUrl = s"https://github.com/sireum/vscode-extension/releases/download/$sireumExtVersion/sireum-vscode-extension.vsix"
val sireumExtDrop = s"sireum-vscode-extension-$sireumExtVersion.vsix"

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

def installExtensions(codium: Os.Path, extensionsDir: Os.Path, extensions: ISZ[String]): String = {
  val extDirArg: String = if (isInUserHome) "" else s" --extensions-dir $extensionsDir"
  val drop = cacheDir / sireumExtDrop
  if (!drop.exists) {
    println("Downloading Sireum VSCode Extension ...")
    drop.downloadFrom(sireumExtUrl)
    println()
  }
  for (ext <- extensions) {
    proc"$codium --force$extDirArg --install-extension $ext".console.runCheck()
    println()
  }
  proc"$codium --force$extDirArg --install-extension $drop".console.runCheck()
  println()
  for (f <- extensionsDir.list if ops.StringOps(f.name).startsWith("sensmetry.sysml-")) {
    patchSysIDE(f)
  }
  return extDirArg
}

def patchCodium(codium: Os.Path, anchor: String, sireumHome: String, isWin: B): Unit = {
  var codiumContent = codium.read
  val cis = conversions.String.toCis(codiumContent)
  if (ops.StringOps.stringIndexOfFrom(cis, conversions.String.toCis("SIREUM_HOME"), 0) >= 0) {
    return
  }
  println(s"Patching $codium ...")
  val i = ops.StringOps.stringIndexOfFrom(cis, conversions.String.toCis(anchor), 0)
  codiumContent = s"${ops.StringOps.substring(cis, 0, i)}${if (isWin) "set" else "export"} SIREUM_HOME=$sireumHome${Os.lineSep}${ops.StringOps.substring(cis, i, cis.size)}"
  codium.writeOver(codiumContent)
  if (!isWin) {
    codium.chmod("+x")
  }
  println()
}

def mac(existingInstallOpt: Option[Os.Path], extensionsDirOpt: Option[Os.Path], extensions: ISZ[String]): Unit = {
  val drop = cacheDir / s"VSCodium-darwin-${if (Os.isMacArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "mac"
  var vscodium = platform / "VSCodium.app"
  val ver = vscodium / "Contents" / "VER"
  var updated = F
  val codium: Os.Path = existingInstallOpt match {
    case Some(p) =>
      vscodium = p.up.up.up.up.up.canon
      p
    case _ =>
      val c = vscodium / "Contents"/ "Resources" / "app" / "bin" / "codium"
      if (!ver.exists || ver.read != version) {
        downloadVSCodium(drop)
        vscodium.removeAll()
        println("Extracting VSCodium ...")
        drop.unzipTo(platform)
        ver.write(version)
        println()
        updated = T
      }
      c
  }
  patchCodium(codium, "ELECTRON_RUN_AS_NODE=", "$(readlink -f `dirname $0`/../../../../../../..)", F)
  proc"xattr -rd com.apple.quarantine $vscodium".run()
  proc"codesign --force --deep --sign - $vscodium".run()
  val extensionsDir: Os.Path = extensionsDirOpt match {
    case Some(ed) => ed
    case _ =>
      if (isInUserHome) {
        val d = platform / "codium-portable-data" / "extensions"
        d.mkdirAll()
        d
      } else {
        val d = vscodium.up.canon / "VSCodium-extensions"
        d.mkdirAll()
        d
      }
  }
  val extDirArg = installExtensions(codium, extensionsDir, extensions)
  if (updated) {
    if (isInUserHome) {
      println(s"To launch VSCodium: open $vscodium")
    } else {
      println(s"To launch VSCodium: $codium$extDirArg")
    }
  }
}

def linux(isArm: B, existingInstallOpt: Option[Os.Path], extensionsDirOpt: Option[Os.Path], extensions: ISZ[String]): Unit = {
  val drop = cacheDir / s"VSCodium-linux-${if (isArm) "arm64" else "x64"}-$version.tar.gz"
  val platform: Os.Path = if (isArm) homeBin / "linux" / "arm" else homeBin / "linux"
  var vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  val codium: Os.Path = existingInstallOpt match {
    case Some(p) =>
      vscodium = p.up.up.canon
      p
    case _ =>
      val c = vscodium / "bin" / "codium"
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
      c
  }
  patchCodium(codium, "ELECTRON_RUN_AS_NODE=",
    s"$$(readlink -f `dirname $$0`/../../../..${if (isArm) "/.." else ""})", F)
  val extensionsDir: Os.Path = extensionsDirOpt match {
    case Some(ed) => ed
    case _ =>
      if (isInUserHome) {
        val d = vscodium / "data" / "extensions"
        d.mkdirAll()
        d
      } else {
        val d = vscodium / "extensions"
        d.mkdirAll()
        d
      }
  }
  val extDirArg = installExtensions(codium, extensionsDir, extensions)
  if (updated) {
    println(s"To launch VSCodium: $codium$extDirArg")
  }
}

def win(existingInstallOpt: Option[Os.Path], extensionsDirOpt: Option[Os.Path], extensions: ISZ[String]): Unit = {
  val drop = cacheDir / s"VSCodium-win32-${if (Os.isWinArm) "arm64" else "x64"}-$version.zip"
  val platform = homeBin / "win"
  var vscodium = platform / "vscodium"
  val ver = vscodium / "VER"
  var updated = F
  val codium: Os.Path = existingInstallOpt match {
    case Some(p) =>
      vscodium = p.up.up.canon
      p
    case _ =>
      val c =  vscodium / "bin" / "codium.cmd"
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
      c
  }
  patchCodium(codium, "\"%~dp0..",
    s"""set SIREUM_HOME="%~dp0../../../..${Os.lineSep}pushd %SIREUM_HOME%${Os.lineSep}set SIREUM_HOME=%CD%${Os.lineSep}popd""".stripMargin, T)
  val extensionsDir: Os.Path = extensionsDirOpt match {
    case Some(ed) => ed
    case _ =>
      if (isInUserHome) {
        val d = vscodium / "data" / "extensions"
        d.mkdirAll()
        d
      } else {
        val d = vscodium / "extensions"
        d.mkdirAll()
        d
      }
  }
  val extDirArg = installExtensions(codium, extensionsDir, extensions)
  if (updated) {
    println(s"To launch VSCodium: $codium$extDirArg")
  }
}

Cli(Os.pathSepChar).parseVscodium(Os.cliArgs, 0) match {
  case Some(o: Cli.VscodiumOption) =>
    var codiumOpt = Option.none[Os.Path]()
    var extDirOpt = Option.none[Os.Path]()
    o.existingInstall match {
      case Some(path) =>
        val p = Os.path(path)
        if (!p.exists) {
          eprintln(s"$p does not exist")
          Os.exit(-1)
        }
        val scripts: HashSSet[String] = HashSSet ++ (if (Os.isWin) ISZ[String]("code.cmd", "codium.cmd") else ISZ[String]("code", "codium"))
        for (codium <- Os.Path.walk(p, F, F, (f: Os.Path) => scripts.contains(f.name)) if codiumOpt.isEmpty) {
          codiumOpt = Some(codium)
          extDirOpt = Some(Os.home / (if (ops.StringOps(codium.name).startsWith("code")) ".vscode" else ".vscode-oss") / "extensions")
        }
        if (codiumOpt.isEmpty) {
          eprintln(st"Could not find ${(scripts, "/")} in $p".render)
          Os.exit(-2)
        }
      case _ =>
    }
    o.extensionsDir match {
      case Some(ed) =>
        val ped = Os.path(ed)
        ped.mkdirAll()
        extDirOpt = Some(ped)
      case _ =>
    }
    val extensions = o.extensions :+ s"Sensmetry.sysml-2ls@$sysIdeVersion"
    Os.kind match {
      case Os.Kind.Mac => mac(codiumOpt, extDirOpt, extensions)
      case Os.Kind.Linux => linux(F, codiumOpt, extDirOpt, extensions)
      case Os.Kind.LinuxArm => linux(T, codiumOpt, extDirOpt, extensions)
      case Os.Kind.Win => win(codiumOpt, extDirOpt, extensions)
      case _ =>
        eprintln("Unsupported platform")
        Os.exit(-1)
    }
  case Some(_: Cli.HelpOption) =>
  case _ =>
}
// END USER CODE
