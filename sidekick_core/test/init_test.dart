import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    deinitializeSidekick();
  });

  group('mainProject', () {
    test('mainProject requires initialization', () {
      expect(
        () => mainProject,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('initializeSidekick()')),
        ),
      );
    });

    test('mainProject throw when not set', () {
      insideFakeSidekickProject((dir) {
        initializeSidekick(name: 'dash');
        expect(
          () => mainProject,
          throwsA(
            isA<String>().having(
              (it) => it,
              'String',
              stringContainsInOrder(
                ['mainProjectPath', 'initializeSidekick()'],
              ),
            ),
          ),
        );
      });
    });

    test('mainProject returns when set in initializeSidekick', () {
      insideFakeSidekickProject((dir) {
        initializeSidekick(name: 'dash', mainProjectPath: '.');
        expect(mainProject.root.path, '${dir.path}/.');
        expect(mainProject.name, 'dash_sdk');
      });
    });
  });

  group('repository', () {
    test('repository requires initialization', () {
      expect(
        () => repository,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('initializeSidekick()')),
        ),
      );
    });
    test('repository returns after calling initializeSidekick()', () {
      insideFakeSidekickProject((dir) {
        initializeSidekick(name: 'dash');
        expect(repository.root.path, dir.path);
      });
    });
  });

  group('cliName', () {
    test('cliName requires initialization', () {
      expect(
        () => cliName,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('initializeSidekick()')),
        ),
      );
    });
    test('cliName returns after calling initializeSidekick()', () {
      insideFakeSidekickProject((dir) {
        initializeSidekick(name: 'dash');
        expect(cliName, 'dash');
      });
    });
  });
}

void insideFakeSidekickProject(void Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
  'git init ${tempDir.path}'.run;

  tempDir.file('dash').createSync();
  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: dash_sdk\n');
  tempDir.directory('lib').createSync();

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  IOOverrides.runZoned(
    () => block(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}
