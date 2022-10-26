import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:test/test.dart';

// TODO this already exists in sidekick_core/test; maybe we should create
// a sidekick_test package to share these utility functions

/// Creates a fake Flutter SDK in temp with a `flutter` executable that does
/// nothing besides "downloading" a fake Dart executable that does also nothing
Directory fakeFlutterSdk() {
  final temp = Directory.systemTemp.createTempSync('fake_flutter');
  print('fakeFlutterSdk in ${temp.path}');
  addTearDown(() => temp.deleteSync(recursive: true));

  final flutterExe = temp.file('bin/flutter')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
#!/bin/bash
echo "fake Flutter executable"

# Download dart SDK on execution
mkdir -p ${temp.absolute.path}/bin/cache/dart-sdk/bin
# write into file
printf "#!/bin/bash\\necho \\"fake embedded Dart executable\\"\\n" > ${temp.absolute.path}/bin/cache/dart-sdk/bin/dart
chmod 755 ${temp.absolute.path}/bin/cache/dart-sdk/bin/dart
''');
  run('chmod 755 ${flutterExe.path}');
  return temp;
}
