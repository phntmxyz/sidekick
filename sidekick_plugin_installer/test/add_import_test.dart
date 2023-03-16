import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/src/add_import.dart';
import 'package:test/test.dart';

void main() {
  test('no existing imports', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final file = tempDir.file('test.dart')..createSync();
    file.writeAsStringSync('void main() {}');

    await addImport(file, "import 'package:my_package/my_package.dart';");
    expect(file.readAsStringSync(), """
import 'package:my_package/my_package.dart';
void main() {}""");
  });

  test('add after existing imports', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final file = tempDir.file('test.dart')..createSync();
    file.writeAsStringSync("""
import 'package:a_package/a_package.dart';

void main() {}""");

    await addImport(file, "import 'package:my_package/my_package.dart';");
    expect(file.readAsStringSync(), """
import 'package:a_package/a_package.dart';
import 'package:my_package/my_package.dart';

void main() {}""");
  });

  test('add before existing imports', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final file = tempDir.file('test.dart')..createSync();
    file.writeAsStringSync("""
import 'package:x_package/x_package.dart';

void main() {}""");

    await addImport(file, "import 'package:my_package/my_package.dart';");
    expect(file.readAsStringSync(), """
import 'package:my_package/my_package.dart';
import 'package:x_package/x_package.dart';

void main() {}""");
  });

  test('insert between existing imports', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final file = tempDir.file('test.dart')..createSync();
    file.writeAsStringSync("""
import 'package:a_package/a_package.dart';
import 'package:x_package/x_package.dart';

void main() {}""");

    await addImport(file, "import 'package:my_package/my_package.dart';");
    expect(file.readAsStringSync(), """
import 'package:a_package/a_package.dart';
import 'package:my_package/my_package.dart';
import 'package:x_package/x_package.dart';

void main() {}""");
  });
}
