import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('version is correct', () {
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue);

    final yaml = loadYaml(pubspec.readAsStringSync());

    // ignore: avoid_dynamic_calls, yaml is [YamlMap] now but will be [HashMap] in future versions
    final packageName = yaml['name'];
    // ignore: avoid_dynamic_calls, yaml is [YamlMap] now but will be [HashMap] in future versions
    final packageVersion = Version.parse(yaml['version'] as String);

    expect(packageName, 'sidekick_core');
    expect(packageVersion, version);
  });

  test('--version flag prints version and does not execute command', () async {
    final printLog = <String>[];
    // override print to verify output
    final spec = ZoneSpecification(
      print: (_, __, ___, line) => printLog.add(line),
    );

    await runZoned(
      () async {
        await insideFakeProjectWithSidekick((dir) async {
          final runner = initializeSidekick(name: 'dash');
          bool called = false;
          runner.addCommand(
            DelegatedCommand(name: 'inside', block: () => called = true),
          );
          await runner.run(['inside', '--version']);
          expect(called, isFalse);
          expect(printLog, contains('dash is using sidekick version $version'));
        });
      },
      zoneSpecification: spec,
    );
  });

  group('mainProject', () {
    test('mainProject only works in SidekickCommandRunner scope', () {
      expect(
        () => mainProject,
        throwsA(
          isA<OutOfCommandRunnerScopeException>()
              .having((it) => it.property, 'property', 'mainProject')
              .having(
                (it) => it.toString(),
                'toString()',
                contains('mainProject'),
              ),
        ),
      );
    });

    test('mainProject can not be resolved', () async {
      await insideFakeProjectWithSidekick((dir) async {
        expect(
          () => initializeSidekick(
            name: 'dash',
            mainProjectPath: 'bielefeld',
          ),
          throwsA(
            isA<String>()
                .having((it) => it, 'toString()', contains('mainProjectPath'))
                .having((it) => it, 'toString()', contains('bielefeld')),
          ),
        );
      });
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

    test('mainProject is detected in repo non root', () async {
      await insideFakeProjectWithSidekick(
        (dir) async {
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
        },
        insideGitRepo: true,
      );
    });

    test('mainProject is detected in repo root', () async {
      await insideFakeProjectWithSidekick(
        (dir) async {
          'git init -q ${dir.path}'.run;
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
        },
      );
    });
  });

  group('repository', () {
    test('repository requires initialization', () {
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => repository,
        throwsA(
          isA<OutOfCommandRunnerScopeException>()
              .having((it) => it.property, 'property', 'repository')
              .having(
                (it) => it.toString(),
                'toString()',
                contains('repository'),
              ),
        ),
      );
    });

    test('repository returns while running run', () async {
      await insideFakeProjectWithSidekick((projectRoot) async {
        'git init -q ${projectRoot.path}'.run;
        final runner = initializeSidekick(name: 'dash');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              // ignore: deprecated_member_use_from_same_package
              expect(repository.root.path, projectRoot.path);
            },
          ),
        );
        await runner.run(['inside']);
        expect(called, isTrue);
      });
    });

    test('repository is null when not in git repo', () async {
      await insideFakeProjectWithSidekick((projectRoot) async {
        final runner = initializeSidekick(name: 'dash');
        bool called = false;
        runner.addCommand(
          DelegatedCommand(
            name: 'inside',
            block: () {
              called = true;
              expect(SidekickContext.repository, isNull);
              // ignore: deprecated_member_use_from_same_package
              expect(() => repository.root.path, throwsA(isA<String>()));
            },
          ),
        );
        await runner.run(['inside']);
        expect(called, isTrue);
      });
    });
  });

  group('cliName', () {
    test('cliName requires initialization', () {
      expect(
        () => cliName,
        throwsA(
          isA<OutOfCommandRunnerScopeException>()
              .having((it) => it.property, 'property', 'cliName')
              .having((it) => it.toString(), 'toString()', contains('cliName')),
        ),
      );
    });
    test('cliName returns while running run', () async {
      await insideFakeProjectWithSidekick((dir) async {
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
        await runner.run(['inside']);
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

            // ignore: deprecated_member_use_from_same_package
            void verifyOuter(Directory dir) {
              expect(cliName, 'dash');
              expect(mainProject!.root.path, dir.path);
              expect(mainProject!.name, 'main_project');
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

  group('flutterSdk', () {
    test('requires initialization', () {
      expect(
        () => flutterSdk,
        throwsA(
          isA<OutOfCommandRunnerScopeException>()
              .having((it) => it.property, 'property', 'flutterSdk')
              .having(
                (it) => it.toString(),
                'toString()',
                contains('flutterSdk'),
              ),
        ),
      );
    });
  });

  group('dartSdk', () {
    test('requires initialization', () {
      expect(
        () => dartSdk,
        throwsA(
          isA<OutOfCommandRunnerScopeException>()
              .having((it) => it.property, 'property', 'dartSdk')
              .having((it) => it.toString(), 'toString()', contains('dartSdk')),
        ),
      );
    });
  });

  group('sdk paths', () {
    test('Throws when dartSdkPath does not exist - no repo', () {
      insideFakeProjectWithSidekick((projectRoot) {
        expect(
          () => initializeSidekick(
            name: 'dash',
            dartSdkPath: 'unknown-dart-sdk-path',
          ),
          throwsA(isA<SdkNotFoundException>()),
        );
      });
    });

    test('Throws when dartSdkPath does not exist - with repo', () {
      insideFakeProjectWithSidekick(
        (projectRoot) {
          expect(
            () => initializeSidekick(
              name: 'dash',
              dartSdkPath: 'unknown-dart-sdk-path',
            ),
            throwsA(isA<SdkNotFoundException>()),
          );
        },
        insideGitRepo: true,
      );
    });

    test('Throws when flutterSdkPath does not exist - no repo', () {
      insideFakeProjectWithSidekick((projectRoot) {
        expect(
          () => initializeSidekick(
            name: 'dash',
            flutterSdkPath: 'unknown-flutter-sdk-path',
          ),
          throwsA(isA<SdkNotFoundException>()),
        );
      });
    });

    test('Throws when flutterSdkPath does not exist - with repo', () {
      insideFakeProjectWithSidekick(
        (projectRoot) {
          expect(
            () => initializeSidekick(
              name: 'dash',
              flutterSdkPath: 'unknown-flutter-sdk-path',
            ),
            throwsA(isA<SdkNotFoundException>()),
          );
        },
        insideGitRepo: true,
      );
    });
    group('are set correctly given a', () {
      test('absolute sdk path', () {
        insideFakeProjectWithSidekick((projectRoot) {
          final fakeDartSdk = projectRoot.directory('my-dart-sdk')
            ..createSync();
          final fakeFlutterSdk = projectRoot.directory('my-flutter-sdk')
            ..createSync();

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
        insideFakeProjectWithSidekick((projectRoot) {
          final fakeDartSdk = projectRoot.directory('my-dart-sdk')
            ..createSync();
          final fakeFlutterSdk = projectRoot.directory('my-flutter-sdk')
            ..createSync();

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

        insideFakeProjectWithSidekick((projectRoot) {
          outsideProject(() {
            final fakeDartSdk = projectRoot.directory('my-dart-sdk')
              ..createSync();
            final fakeFlutterSdk = projectRoot.directory('my-flutter-sdk')
              ..createSync();

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

      test('relative to projectRoot', () {
        insideFakeProjectWithSidekick((projectRoot) {
          final fakeDartSdk = projectRoot.directory('sdks/my-dart-sdk')
            ..createSync(recursive: true);
          final fakeFlutterSdk = projectRoot.directory('sdks/my-flutter-sdk')
            ..createSync(recursive: true);

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: 'sdks/my-dart-sdk',
            flutterSdkPath: 'sdks/my-flutter-sdk',
          );

          expect(runner.flutterSdk?.path, fakeFlutterSdk.absolute.path);
          expect(runner.dartSdk?.path, fakeDartSdk.absolute.path);
        });
      });

      test('relative to repository root (legacy)', () async {
        final stderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => stderr,
          body: () async {
            await insideFakeProjectWithSidekick(
              (projectRoot) async {
                final fakeDartSdk = projectRoot.directory('sdks/my-dart-sdk')
                  ..createSync(recursive: true);
                final fakeFlutterSdk = projectRoot
                    .directory('sdks/my-flutter-sdk')
                  ..createSync(recursive: true);

                final runner = initializeSidekick(
                  name: 'dash',
                  dartSdkPath:
                      '${projectRoot.nameWithoutExtension}/sdks/my-dart-sdk',
                  flutterSdkPath:
                      '${projectRoot.nameWithoutExtension}/sdks/my-flutter-sdk',
                );

                expect(runner.flutterSdk?.path, fakeFlutterSdk.absolute.path);
                expect(runner.dartSdk?.path, fakeDartSdk.absolute.path);
              },
              insideGitRepo: true,
            );
          },
        );
        final stderrOutput = stderr.lines.join('\n');
        expect(
          stderrOutput,
          contains('flutterSdkPath is defined relative to your git repository. '
              'Please migrate it to be relative to the dash entryPoint'),
        );
        expect(
          stderrOutput,
          contains('dartSdkPath is defined relative to your git repository. '
              'Please migrate it to be relative to the dash entryPoint'),
        );
      });

      test(
          'Conflict, both paths exist: relative to projectRoot and repository (legacy). '
          'Fallback to projectRoot', () async {
        final stderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => stderr,
          body: () async {
            await insideFakeProjectWithSidekick(
              (projectRoot) async {
                final projectDartSdk = projectRoot.directory('sdks/my-dart-sdk')
                  ..createSync(recursive: true);
                final projectFlutterSdk = projectRoot
                    .directory('sdks/my-flutter-sdk')
                  ..createSync(recursive: true);

                final repoDartSdk = SidekickContext.repository!
                    .directory('sdks/my-dart-sdk')
                  ..createSync(recursive: true);
                final repoFlutterSdk = SidekickContext.repository!
                    .directory('sdks/my-flutter-sdk')
                  ..createSync(recursive: true);

                final runner = initializeSidekick(
                  name: 'dash',
                  dartSdkPath: 'sdks/my-dart-sdk',
                  flutterSdkPath: 'sdks/my-flutter-sdk',
                );

                // they folders also exist in the repo root, those are ignored
                expect(repoDartSdk.existsSync(), isTrue);
                expect(repoFlutterSdk.existsSync(), isTrue);
                // fallback to project folders
                expect(
                  runner.flutterSdk?.path,
                  projectFlutterSdk.absolute.path,
                );
                expect(runner.dartSdk?.path, projectDartSdk.absolute.path);
              },
              insideGitRepo: true,
            );
          },
        );
        final stderrOutput = stderr.lines.join('\n');
        expect(stderrOutput, contains('Found flutterSdkPath at both'));
        expect(
          stderrOutput,
          contains('Using the latter which is relative to the dash entryPoint'),
        );
        expect(stderrOutput, contains('Found dartSdkPath at both'));
        expect(
          stderrOutput,
          contains('Using the latter which is relative to the dash entryPoint'),
        );
      });
    });

    test('error is thrown when invalid sdkPaths are given', () {
      insideFakeProjectWithSidekick((dir) {
        const doesntExist = 'bielefeld';

        expect(
          () => initializeSidekick(name: 'dash', dartSdkPath: doesntExist),
          throwsA(
            isA<SdkNotFoundException>().having(
              (it) => it.toString(),
              'toString()',
              allOf(
                contains('Dart or Flutter SDK'),
                contains('bielefeld'),
                contains(dir.absolute.path),
              ),
            ),
          ),
        );
        expect(
          () => initializeSidekick(name: 'dash', flutterSdkPath: doesntExist),
          throwsA(
            isA<SdkNotFoundException>().having(
              (it) => it.toString(),
              'toString()',
              allOf(
                contains('Flutter SDK'),
                contains('bielefeld'),
                contains(dir.absolute.path),
              ),
            ),
          ),
        );
      });
    });
  });
}
