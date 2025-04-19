import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart' as dcli;
import 'package:test/test.dart';

/// Creates a fake Flutter SDK in temp with a `flutter` executable that does
/// nothing besides "downloading" a fake Dart executable that does also nothing
Directory fakeFlutterSdk({Directory? directory}) {
  final Directory dir = directory ??
      () {
        final temp = Directory.systemTemp.createTempSync('fake_flutter');
        addTearDown(() => temp.deleteSync(recursive: true));
        return temp;
      }();

  final flutterExe = dir.file('bin/flutter')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
#!/bin/bash
echo "fake Flutter executable"

# Download dart SDK on execution
mkdir -p ${dir.absolute.path}/bin/cache/dart-sdk/bin
# write into file
printf "#!/bin/bash\\necho \\"fake embedded Dart executable\\"\\n" > ${dir.absolute.path}/bin/cache/dart-sdk/bin/dart
chmod 755 ${dir.absolute.path}/bin/cache/dart-sdk/bin/dart
''');
  dcli.run('chmod 755 ${flutterExe.path}');
  return dir;
}

/// Creates a fake Flutter SDK in temp with a `flutter` executable that
/// always fails
Directory fakeFailingFlutterSdk({Directory? directory}) {
  final Directory dir = directory ??
      () {
        final temp = Directory.systemTemp.createTempSync('fake_flutter');
        addTearDown(() => temp.deleteSync(recursive: true));
        return temp;
      }();

  final flutterExe = dir.file('bin/flutter')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
#!/bin/bash
echo "fake failing Flutter executable"
exit 1
''');
  dcli.run('chmod 755 ${flutterExe.path}');
  return dir;
}

/// Creates a fake Dart SDK with a `dart` executable that does nothing
Directory fakeDartSdk() {
  final temp = Directory.systemTemp.createTempSync('fake_dart');
  addTearDown(() => temp.deleteSync(recursive: true));

  final exe = temp.file('bin/dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '#!/bin/bash\necho "fake Dart executable"',
      flush: true,
    );
  dcli.run('chmod 755 ${exe.path}');

  return temp;
}

/// Creates a fake Dart SDK with a `dart` executable that always fails
Directory fakeFailingDartSdk() {
  final temp = Directory.systemTemp.createTempSync('fake_dart');
  addTearDown(() => temp.deleteSync(recursive: true));

  final exe = temp.file('bin/dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '''
#!/bin/bash
echo "fake throwing Dart executable"
exit 1''',
      flush: true,
    );
  dcli.run('chmod 755 ${exe.path}');

  return temp;
}

/// Creates a fake Dart SDK with a `dart` executable that prints the given text
Directory fakePrintingDartSdk(String text) {
  final temp = Directory.systemTemp.createTempSync('fake_dart');
  addTearDown(() => temp.deleteSync(recursive: true));

  final textFile = temp.file('text')..writeAsStringSync(text);
  final exe = temp.file('bin/dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '''
#!/bin/bash
cat ${textFile.path}
''',
      flush: true,
    );
  dcli.run('chmod 755 ${exe.path}');

  return temp;
}
