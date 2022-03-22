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

    test('mainProject throws when not set', () async {
      await insideFakeSidekickProject((dir) async {
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
            },
          ),
        );
        await runner.run(['inside']);
        expect(called, isTrue);
      });
    });

    test('mainProject returns while running run', () async {
      await insideFakeSidekickProject((dir) async {
        final runner = initializeSidekick(name: 'dash', mainProjectPath: '.');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(mainProject.root.path, dir.path);
              expect(mainProject.name, 'dash_sdk');
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
      insideFakeSidekickProject((dir) {
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
      insideFakeSidekickProject((dir) {
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
    await insideFakeSidekickProject((dir) async {
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
              expect(mainProject.root.path, dir.path);
              expect(mainProject.name, 'dash_sdk');
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
                  expect(
                    () => mainProject,
                    throwsA(
                      isA<String>().having(
                        (it) => it,
                        'errorMessage',
                        contains('mainProject is not initialized'),
                      ),
                    ),
                  );
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
}

R insideFakeSidekickProject<R>(R Function(Directory projectDir) block) {
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
