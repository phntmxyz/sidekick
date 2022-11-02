import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
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

/// Creates a fake Dart SDK with a `dart` executable that does nothing
Directory fakeDartSdk() {
  final temp = Directory.systemTemp.createTempSync('fake_dart');
  addTearDown(() => temp.deleteSync(recursive: true));

  final exe = temp.file('bin/dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('#!/bin/bash\necho "fake Dart executable"');
  dcli.run('chmod 755 ${exe.path}');

  return temp;
}
