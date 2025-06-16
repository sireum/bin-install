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
// @formatter:off

// This file is auto-generated from fmide-cli.sc

import org.sireum._

object Cli {

  @datatype trait FmideTopOption

  @datatype class HelpOption extends FmideTopOption

  @datatype class FmideOption(
    val help: String,
    val args: ISZ[String],
    val awas: Option[String],
    val gumbo: Option[String],
    val hamr: Option[String],
    val agree: Option[String],
    val briefcase: Option[String],
    val jkind: Option[String],
    val resolute: Option[String],
    val osate: Option[String],
    val eclipse: Option[String],
    val existingInstall: Option[String],
    val verbose: B,
    val verbosePlus: B
  ) extends FmideTopOption
}

import Cli._

@record class Cli(val pathSep: C) {

  def parseFmide(args: ISZ[String], i: Z): Option[FmideTopOption] = {
    val help =
      st"""FMIDE Installer
          |
          |Usage: <option>*
          |
          |Available Options:
          |    --awas               AWAS version (expects a string; default is
          |                           "1.2025.06160727.42c86446")
          |    --gumbo              Sireum GUMBO version (expects a string; default is
          |                           "1.2025.06020757.f5a533c1")
          |    --hamr               Sireum HAMR version (expects a string; default is
          |                           "1.2025.06160727.42c86446")
          |    --agree              AGREE version (expects a string; default is "2.11.0")
          |    --briefcase          BriefCASE version (expects a string; default is
          |                           "0.9.0")
          |    --jkind              JKind version (expects a string; default is "4.5.0")
          |    --resolute           Resolute version (expects a string; default is
          |                           "4.1.100")
          |    --osate              OSATE version (expects a string; default is
          |                           "2.13.0-vfinal")
          |    --eclipse            Eclipse release version (expects a string; default is
          |                           "2023-03")
          |-h, --help               Display this information
          |
          |Installation Options:
          |    --existing-install   Path to an existing OSATE installation where the FMIDE
          |                           plugins will be installed/updated. The '--osate'
          |                           option will be ignored if provided (expects a path)
          |-v, --verbose            Verbose output
          |    --verbose+           Increased verbose output""".render

    var awas: Option[String] = Some("1.2025.06160727.42c86446")
    var gumbo: Option[String] = Some("1.2025.06020757.f5a533c1")
    var hamr: Option[String] = Some("1.2025.06160727.42c86446")
    var agree: Option[String] = Some("2.11.0")
    var briefcase: Option[String] = Some("0.9.0")
    var jkind: Option[String] = Some("4.5.0")
    var resolute: Option[String] = Some("4.1.100")
    var osate: Option[String] = Some("2.13.0-vfinal")
    var eclipse: Option[String] = Some("2023-03")
    var existingInstall: Option[String] = None[String]()
    var verbose: B = false
    var verbosePlus: B = false
    var j = i
    var isOption = T
    while (j < args.size && isOption) {
      val arg = args(j)
      if (ops.StringOps(arg).first == '-') {
        if (args(j) == "-h" || args(j) == "--help") {
          println(help)
          return Some(HelpOption())
        } else if (arg == "--awas") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => awas = v
             case _ => return None()
           }
         } else if (arg == "--gumbo") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => gumbo = v
             case _ => return None()
           }
         } else if (arg == "--hamr") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => hamr = v
             case _ => return None()
           }
         } else if (arg == "--agree") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => agree = v
             case _ => return None()
           }
         } else if (arg == "--briefcase") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => briefcase = v
             case _ => return None()
           }
         } else if (arg == "--jkind") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => jkind = v
             case _ => return None()
           }
         } else if (arg == "--resolute") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => resolute = v
             case _ => return None()
           }
         } else if (arg == "--osate") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => osate = v
             case _ => return None()
           }
         } else if (arg == "--eclipse") {
           val o: Option[Option[String]] = parseString(args, j + 1)
           o match {
             case Some(v) => eclipse = v
             case _ => return None()
           }
         } else if (arg == "--existing-install") {
           val o: Option[Option[String]] = parsePath(args, j + 1)
           o match {
             case Some(v) => existingInstall = v
             case _ => return None()
           }
         } else if (arg == "-v" || arg == "--verbose") {
           val o: Option[B] = { j = j - 1; Some(!verbose) }
           o match {
             case Some(v) => verbose = v
             case _ => return None()
           }
         } else if (arg == "--verbose+") {
           val o: Option[B] = { j = j - 1; Some(!verbosePlus) }
           o match {
             case Some(v) => verbosePlus = v
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
    return Some(FmideOption(help, parseArguments(args, j), awas, gumbo, hamr, agree, briefcase, jkind, resolute, osate, eclipse, existingInstall, verbose, verbosePlus))
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
val sireum = homeBin / (if (Os.isWin) "sireum.bat" else "sireum")

def parseCliArgs(): Cli.FmideOption = {
  Cli(Os.pathSepChar).parseFmide(Os.cliArgs, 0) match {
    case Some(o: Cli.FmideOption) =>
      if (o.args.isEmpty) {
        return o
      } else {
        eprintln(s"Unexpected arguments: ${o.args}")
        Os.exit(1)
      }
    case Some(_: Cli.HelpOption) =>
      Os.exit(0)
    case _ =>
  }
  eprintln("Could not recognize arguments")
  Os.exit(-1)
  halt("Infeasible")
}

val option = parseCliArgs()

val eclipseVersion = option.eclipse.get
val osateVersion = option.osate.get

@datatype class Feature(val id: String,
                        val url: String,
                        val defaultVersion: String,
                        val releaseSuffix: Option[String]) {

  def phantomArg: String = {
    return st"$id=$url$releaseSuffix/$defaultVersion".render
  }
}

val agree = Feature(
  "com.rockwellcollins.atc.agree.feature.feature.group",
  "https://raw.githubusercontent.com/loonwerks/AGREE-Updates/master",
  option.agree.get,
  Some("/releases"))

val resolute = Feature(
  "com.rockwellcollins.atc.resolute.feature.feature.group",
  "https://raw.githubusercontent.com/loonwerks/Resolute-Updates/master",
  option.resolute.get,
  Some("/releases"))

val briefcase = Feature(
  "com.collins.trustedsystems.briefcase.feature.feature.group",
  s"https://download.eclipse.org/releases/$eclipseVersion,https://raw.githubusercontent.com/loonwerks/BriefCASE-Updates/master",
  option.briefcase.get,
  Some("/releases"))

val sireumPlugin = Feature(
  "org.sireum.aadl.osate.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/osate-update-site/master",
  option.hamr.get,
  None())

val awas = Feature(
  "org.sireum.aadl.osate.awas.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/osate-update-site/master",
  option.awas.get,
  None())

val cli = Feature(
  "org.sireum.aadl.osate.cli.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/osate-update-site/master",
  option.hamr.get,
  None())

val hamr = Feature(
  "org.sireum.aadl.osate.hamr.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/osate-update-site/master",
  option.hamr.get,
  None())

val gumbo = Feature(
  "org.sireum.aadl.gumbo.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/aadl-gumbo-update-site/master",
  option.gumbo.get,
  None())

val gumbo2Air = Feature(
  "org.sireum.aadl.osate.gumbo2air.feature.feature.group",
  "https://raw.githubusercontent.com/sireum/aadl-gumbo-update-site/master",
  option.gumbo.get,
  None())

val features: ISZ[Feature] = ISZ(
  gumbo2Air,
  cli,
  hamr,
  awas,
  gumbo,
  sireumPlugin,
  briefcase,
  resolute,
  agree)

val fmideDir: Os.Path =
  if(option.existingInstall.nonEmpty) {
    val path = Os.path(option.existingInstall.get)
    val osateIni: Os.Path = if(Os.isMac) path / "Contents"/ "Eclipse" / "osate.ini" else path / "osate.ini"
    if(!path.exists || !path.isDir || !osateIni.exists) {
      eprintln("The provided existing installation directory does not appear to be an valid OSATE installation")
      eprintln(s"  ${osateIni.value} not found")
      Os.exit(-1)
      halt("Infeasible")
    }
    path
  } else {
    Os.kind match {
      case Os.Kind.Mac => homeBin / "mac" / "fmide.app"
      case Os.Kind.Linux => homeBin / "linux" / "fmide"
      case Os.Kind.LinuxArm => homeBin / "linux" / "arm" / "fmide"
      case Os.Kind.Win => homeBin / "win" / "fmide"
      case _ =>
        eprintln("Unsupported operating system")
        Os.exit(-1)
        halt("Infeasible")
    }
  }
var verContent = st"""eclipse=$eclipseVersion
                     |${(for(f <- features) yield st"${f.id}=${f.defaultVersion}", "\n")}"""
if(option.existingInstall.isEmpty) {
  verContent = st"""osate=$osateVersion
                   |$verContent"""
}

val ver: Os.Path = if (Os.isMac) fmideDir / "Contents" / "Eclipse" / "VER"  else fmideDir / "VER"
val installKind: String = if(option.existingInstall.nonEmpty) "FMIDE plugins" else "FMIDE"
if (ver.exists) {
  if (ver.read == verContent.render) {
    println(s"${installKind} up to date")
    Os.exit(0)
  } else {
    println(s"Version differences detected, updating ${installKind} (this will take a while) ...")

    if (option.existingInstall.isEmpty) {
      ver.properties.get("osate") match {
        case Some(o) =>
          if (o != option.osate.get) {
            println(s"Updating FMIDE to an OSATE ${option.osate.get} version ...")
            fmideDir.removeAll()
          }
        case _ =>
          println(s"The following appears to be an older FMIDE installation so replacing it with an OSATE ${option.osate.get} based version")
          println(s"  ${fmideDir.value}")
          fmideDir.removeAll()
      }
    }
  }
} else {
  if (fmideDir.exists && option.existingInstall.isEmpty) {
    println(s"The following appears to be an invalid FMIDE installation so replacing it with an OSATE ${option.osate.get} based version")
    println(s"  ${fmideDir.value}")
    fmideDir.removeAll()
  }
  println(s"Installing ${installKind} (this will take a while) ...")
}
var env = ISZ[(String, String)]()
Os.env("JAVA_HOME") match {
  case Some(v) => env = env :+ (("PATH", s"${Os.path(v) / "bin"}${Os.pathSep}${Os.env("PATH").get}"))
  case _ =>
}
val verbosity: String = if(option.verbosePlus) "--verbose+" else if (option.verbose) "--verbose" else ""
val phantomArgs = st"${(for(f <- features) yield f.phantomArg, ";")}".render
var p = proc"$sireum hamr phantom ${verbosity} --update --osate $fmideDir --version $osateVersion --features $phantomArgs".env(env).console
if(option.verbosePlus) {
  p = p.echo
}
p.runCheck()
if(option.existingInstall.isEmpty) {
  Os.kind match {
    case Os.Kind.Linux if (fmideDir / "osate").exists =>
      // brand as fmide, only needs to be done for fresh installs
      (fmideDir / "osate").moveTo(fmideDir / "fmide")
      (fmideDir / "osate.ini").moveTo(fmideDir / "fmide.ini")
    case Os.Kind.Win if (fmideDir / "osate.exe").exists =>
      // brand as fmide, only needs to be done for fresh installs
      (fmideDir / "osate.exe").moveTo(fmideDir / "fmide.exe")
      (fmideDir / "osate.ini").moveTo(fmideDir / "fmide.ini")
    case Os.Kind.Mac =>
    // the directory is already called fmide.app, and eclipse/mac doesn't
    // allow osate.ini to be moved to fmide.ini
    case _ =>
  }
}
ver.writeOver(verContent.render)
if(option.verbose || option.verbosePlus) {
  println(s"Wrote versions file: ${ver.value}")
}
println(s"${installKind} installed at $fmideDir")
// END USER CODE
