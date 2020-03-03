# drtimport

A command line application that allow helps refactor dart libraries.

You can use it to move a library (or directory of libraries) and drtimport will update import statements across your whole package to reflect the new location of files.

```
Dart import management, version: 1.0.2

Usage: drtimport <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  help    Display help information for drtimport.
  move    Moves a dart library and updates all import statements to reflect its new location.
  patch   Patches import statements by doing a string replace.

Run "drtimport help <command>" for more information about a command.


move:

move <from path> <to path>
e.g. move apps/string.dart  util/string.dart
-h, --help           Print this usage information.
    --root=<path>    The path to the root of your project.
                     (defaults to ".")

    --debug          Turns on debug ouput
-v, --version        Outputs the version of drtimport and exits.


patch:

Patches import statements by doing a string replace within every import statement.
<from string> <to string>
e.g. AppClass app_class
-h, --help    Print this usage information.
```




