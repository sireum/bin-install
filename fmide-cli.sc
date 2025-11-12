// #Sireum
import org.sireum._
import org.sireum.cli.CliOpt._

// the usage field will be placed inside a ST so to get newlines that don't have large
// indentations we need to nest another ST inside that.
val tqs: String = "\"\"\""
val usage: String ="<option>*"

val fmideTool: Tool = Tool(
  name = "fmide",
  command = "fmide",
  description = "FMIDE Installer",
  header = "FMIDE Installer",
  usage = usage,
  usageDescOpt = None(),
  opts = ISZ(
    Opt(name = "awas", longKey = "awas", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("1.2025.09161533.4336a133")), description = "AWAS version"),
    Opt(name = "gumbo", longKey = "gumbo", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("1.2025.11101714.aaeb57a0")), description = "Sireum GUMBO version"),
    Opt(name = "hamr", longKey = "hamr", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("1.2025.09161533.4336a133")), description = "Sireum HAMR version"),
    Opt(name = "agree", longKey = "agree", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("2.11.2")), description = "AGREE version"),
    Opt(name = "briefcase", longKey = "briefcase", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("0.9.2")), description = "BriefCASE version"),
    Opt(name = "jkind", longKey = "jkind", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("4.5.2")), description = "JKind version"),
    Opt(name = "resolute", longKey = "resolute", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("4.1.100")), description = "Resolute version"),
    Opt(name = "osate", longKey = "osate", shortKey = None(),
      tpe = Type.Str(sep = None(), default = Some("2.14.0-vfinal")), description = "OSATE version"),
    Opt(name = "eclipse", longKey = "eclipse", shortKey = None(),
        tpe = Type.Str(sep = None(), default = Some("2023-12")), description = "Eclipse release version")
  ),
  groups = ISZ(
    OptGroup(name = "Installation", opts = ISZ(
      Opt(name = "existingInstall", longKey = "existing-install", shortKey = None(),
        tpe = Type.Path(multiple = F, default = None()),
        description="Path to an existing OSATE installation where the FMIDE plugins will be installed/updated. The '--osate' option will be ignored if provided"),
      Opt(name = "verbose", longKey = "verbose", shortKey = Some('v'),
        tpe = Type.Flag(F), description = "Verbose output"),
      Opt(name = "verbosePlus", longKey = "verbose+", shortKey = None(),
        tpe = Type.Flag(F), description = "Increased verbose output ")
    ))
  )
)

println(org.sireum.cli.JSON.fromCliOpt(fmideTool, T))
