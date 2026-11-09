// Conditional export: use a web-specific implementation when compiling
// for the browser, otherwise use the IO implementation that uses
// `dart:io` and `path_provider`.

export 'banco_dados_io.dart' if (dart.library.html) 'banco_dados_web.dart';
