// #Sireum
import org.sireum._
import org.sireum.cli.CliOpt._

val usage: String = "<options>*"
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
  "mshr-h.veriloghdl",
  "redhat.vscode-xml",
  "redhat.vscode-yaml",
  "adamraichu.zip-viewer"
)

val vscodiumTool: Tool = Tool(
  name = "vscodium",
  command = "vscodium",
  description = "VSCodium Installer",
  header = "VSCodium Installer",
  usage = usage,
  usageDescOpt = None(),
  opts = ISZ(
    Opt(name = "existingInstall", longKey = "existing-install", shortKey = None(),
      tpe = Type.Path(multiple = F, default = None()),
      description = "VSCodium/VSCode existing installation path"),
    Opt(name = "extensions", longKey = "extensions", shortKey = None(),
      tpe = Type.Str(sep = Some(','), default = Some(st"${(extensions, ",")}".render)),
      description = "List of extensions to be installed (excluding Sireum and SysIDE)"),
    Opt(name = "extensionsDir", longKey = "extensions-dir", shortKey = None(),
      tpe = Type.Path(multiple = F, default = None()),
      description = "Custom VSCodium/VSCode extensions directory")
  ),
  groups = ISZ()
)

println(org.sireum.cli.JSON.fromCliOpt(vscodiumTool, T))
