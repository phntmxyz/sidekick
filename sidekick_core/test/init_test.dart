import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('mainProject', () {
    test('mainProject only works in SidekickCommandRunner scope', () {
      expect(
        () => mainProject,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('SidekickCommandRunner')),
        ),
      );
    });

    test('mainProject returns null when not set', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final runner = initializeSidekick(
          name: 'dash',
          // ignore: avoid_redundant_argument_values
          mainProjectPath: null, // explicitly null
        );
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(mainProject, isNull);
            },
          ),
        );
        await runner.run(['inside']);
        expect(called, isTrue);
      });
    });

    test('mainProject returns while running run', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final runner = initializeSidekick(name: 'dash', mainProjectPath: '.');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(mainProject!.root.path, dir.path);
              expect(mainProject!.name, 'main_project');
            },
          ),
        );
        await runner.run(['inside']);
        expect(called, isTrue);
      });
    });
  });

  group('repository', () {
    test('repository requires initialization', () {
      expect(
        () => repository,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('SidekickCommandRunner')),
        ),
      );
    });

    test('repository returns while running run', () {
      insideFakeProjectWithSidekick((dir) {
        final runner = initializeSidekick(name: 'dash');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(repository.root.path, dir.path);
            },
          ),
        );
        runner.run(['inside']);
        expect(called, isTrue);
      });
    });
  });

  group('cliName', () {
    test('cliName requires initialization', () {
      expect(
        () => cliName,
        throwsA(
          isA<String>()
              .having((it) => it, 'String', contains('SidekickCommandRunner')),
        ),
      );
    });
    test('cliName returns while running run', () {
      insideFakeProjectWithSidekick((dir) {
        final runner = initializeSidekick(name: 'dash');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(cliName, 'dash');
            },
          ),
        );
        runner.run(['inside']);
        expect(called, isTrue);
      });
    });
  });

  test('nested initializeSidekick() restores old static members', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final outerRunner =
          initializeSidekick(name: 'dash', mainProjectPath: '.');
      bool outerCalled = false;
      bool innerCalled = false;
      outerRunner.addCommand(
        DelegatedCommand(
          name: 'outer',
          block: () async {
            outerCalled = true;

            final outerRepository = repository;
            void verifyOuter(Directory dir) {
              expect(cliName, 'dash');
              expect(mainProject!.root.path, dir.path);
              expect(mainProject!.name, 'main_project');
              expect(repository.root.path, dir.path);
            }

            verifyOuter(dir);

            final innerRunner = initializeSidekick(name: 'innerdash');
            innerRunner.addCommand(
              DelegatedCommand(
                name: 'inner',
                block: () {
                  innerCalled = true;
                  // inner values are set
                  expect(cliName, 'innerdash');
                  expect(mainProject, isNull);
                  expect(repository, isNot(outerRepository));
                },
              ),
            );
            await innerRunner.run(['inner']);

            // outer values are restored
            verifyOuter(dir);
          },
        ),
      );
      await outerRunner.run(['outer']);
      expect(outerCalled, isTrue);
      expect(innerCalled, isTrue);
    });
  });

  group('sdk paths are set correctly given a', () {
    test('absolute sdk path', () {
      insideFakeProjectWithSidekick((dir) {
        final fakeDartSdk = dir.directory('my-dart-sdk')..createSync();
        final fakeFlutterSdk = dir.directory('my-flutter-sdk')..createSync();

        final runner = initializeSidekick(
          name: 'dash',
          dartSdkPath: fakeDartSdk.absolute.path,
          flutterSdkPath: fakeFlutterSdk.absolute.path,
        );

        expect(runner.flutterSdk?.path, fakeFlutterSdk.absolute.path);
        expect(runner.dartSdk?.path, fakeDartSdk.absolute.path);
      });
    });

    test('relative sdk path when initializing inside of project', () {
      insideFakeProjectWithSidekick((dir) {
        final fakeDartSdk = dir.directory('my-dart-sdk')..createSync();
        final fakeFlutterSdk = dir.directory('my-flutter-sdk')..createSync();

        final runner = initializeSidekick(
          name: 'dash',
          dartSdkPath: 'my-dart-sdk',
          flutterSdkPath: 'my-flutter-sdk',
        );

        expect(runner.flutterSdk?.path, fakeFlutterSdk.absolute.path);
        expect(runner.dartSdk?.path, fakeDartSdk.absolute.path);
      });
    });

    test('relative sdk path when initializing outside of project', () {
      void outsideProject(void Function() callback) {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        IOOverrides.runZoned(callback, getCurrentDirectory: () => tempDir);
      }

      insideFakeProjectWithSidekick((dir) {
        outsideProject(() {
          final fakeDartSdk = dir.directory('my-dart-sdk')..createSync();
          final fakeFlutterSdk = dir.directory('my-flutter-sdk')..createSync();

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: 'my-dart-sdk',
            flutterSdkPath: 'my-flutter-sdk',
          );

          expect(runner.flutterSdk?.path, fakeFlutterSdk.absolute.path);
          expect(runner.dartSdk?.path, fakeDartSdk.absolute.path);
        });
      });
    });
  });
}

R insideFakeProjectWithSidekick<R>(R Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
  'git init ${tempDir.path}'.run;

  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: main_project\n');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash_sdk')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: dash_sdk\n');
  fakeSidekickDir.directory('lib').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
  });

  return IOOverrides.runZoned(
    () => block(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}

class DelegatedCommand extends Command {
  DelegatedCommand({
    required this.name,
    required this.block,
  });

  @override
  String get description => 'delegated';

  @override
  final String name;

  final FutureOr<void> Function() block;

  @override
  Future<void> run() async {
    await block();
  }
}
