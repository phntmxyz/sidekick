import 'package:sidekick_core/sidekick_core.dart' hide isEmpty;
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => exitCode = 0);

  for (final filtered in [false, true]) {
    test('awaits hooks with project context (filtered: $filtered)', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
          mainProjectPath: '.',
        );
        var calls = 0;
        addTearDown(addDepsHook((context) async {
          expect(SidekickContext.projectRoot.path, dir.path);
          expect(entryWorkingDirectory.path, dir.path);
          expect(mainProject?.name, 'main_project');
          expect(context.results.map((r) => r.package.name), ['main_project']);
          expect(context.isSuccess, isTrue);
          expect(context.results.single.error, isNull);
          expect(context.results.single.stackTrace, isNull);
          expect(() => context.results.clear(), throwsUnsupportedError);
          await Future<void>.delayed(Duration.zero);
          calls++;
        }));
        runner.addCommand(DepsCommand());
        await runner.run([
          'deps',
          if (filtered) ...['-p', 'main_project']
        ]);
        expect(calls, 1);
      });
    });

    test('reports dependency failures to hooks (filtered: $filtered)',
        () async {
      await insideFakeProjectWithSidekick((_) async {
        final runner =
            initializeSidekick(dartSdkPath: fakeFailingDartSdk().path);
        var called = false;
        addTearDown(addDepsHook((context) async {
          expect(context.isSuccess, isFalse);
          expect(context.results.single.package.name, 'main_project');
          expect(context.results.single.error,
              contains('Failed to get dependencies'));
          expect(context.results.single.stackTrace, isNotNull);
          await Future<void>.value();
          called = true;
          // A successful hook cannot turn a failed deps run into success.
          exitCode = 0;
        }));
        runner.addCommand(DepsCommand());
        if (filtered) {
          await expectLater(
              runner.run(['deps', '-p', 'main_project']), throwsA(anything));
        } else {
          await runner.run(['deps']);
          expect(exitCode, 1);
        }
        expect(called, isTrue);
      });
    });
  }

  test('reports mixed outcomes after attempting all packages', () async {
    await insideFakeProjectWithSidekick((dir) async {
      dir.file('broken/pubspec.yaml')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('name: broken\nenvironment:\n  sdk: ^3.6.0\n');
      final sdk = fakeDartSdk();
      sdk.file('bin/dart').writeAsStringSync(r'''
#!/bin/sh
case "$PWD" in */broken) exit 1;; esac
'''
          .trimLeft());
      final runner = initializeSidekick(dartSdkPath: sdk.path);
      DepsContext? captured;
      addTearDown(addDepsHook((context) async {
        captured = context;
        expect(context.isSuccess, isFalse);
        expect(context.results.map((r) => r.package.name),
            containsAll(['main_project', 'broken']));
        expect(
            context.results
                .singleWhere((r) => r.package.name == 'main_project')
                .isSuccess,
            isTrue);
        expect(
            context.results
                .singleWhere((r) => r.package.name == 'broken')
                .isSuccess,
            isFalse);
        await Future<void>.value();
      }));
      runner.addCommand(DepsCommand());
      await runner.run(['deps']);
      expect(exitCode, 1);
      expect(captured, isNotNull);
    });
  });

  test('filtered dependency failure stays primary when a hook throws',
      () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeFailingDartSdk().path);
      final hookError = StateError('secondary hook failure');
      final diagnostics = FakeStdoutStream();
      DepsPackageResult? attempted;
      addTearDown(addDepsHook((context) async {
        attempted = context.results.single;
        expect(attempted!.isSuccess, isFalse);
        await Future<void>.value();
        throw hookError;
      }));
      runner.addCommand(DepsCommand());
      Object? reportedError;
      StackTrace? reportedStack;
      await overrideIoStreams(
        stderr: () => diagnostics,
        body: () async {
          try {
            await runner.run(['deps', '-p', 'main_project']);
          } catch (error, stackTrace) {
            reportedError = error;
            reportedStack = stackTrace;
          }
        },
      );
      expect(attempted, isNotNull);
      expect(attempted!.error, isNotNull);
      expect(reportedError, same(attempted!.error));
      expect(reportedStack.toString(), attempted!.stackTrace.toString());
      expect(diagnostics.lines.join('\n'),
          contains('Error in deps hook: $hookError'));
    });
  });

  test('filtered successful dependencies propagate the hook error', () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeDartSdk().path);
      final hookError = StateError('hook failed after successful deps');
      DepsContext? captured;
      addTearDown(addDepsHook((context) async {
        captured = context;
        await Future<void>.value();
        throw hookError;
      }));
      runner.addCommand(DepsCommand());
      await expectLater(
          runner.run(['deps', '-p', 'main_project']), throwsA(same(hookError)));
      expect(captured, isNotNull);
      expect(captured!.isSuccess, isTrue);
      expect(captured!.results.single.package.name, 'main_project');
    });
  });

  test('unfiltered dependency failure stays nonzero when a hook throws',
      () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeFailingDartSdk().path);
      final hookError = StateError('hook resets status then fails');
      DepsContext? captured;
      addTearDown(addDepsHook((context) async {
        captured = context;
        exitCode = 0;
        await Future<void>.value();
        throw hookError;
      }));
      runner.addCommand(DepsCommand());
      await expectLater(runner.run(['deps']), throwsA(same(hookError)));
      expect(captured, isNotNull);
      expect(captured!.isSuccess, isFalse);
      expect(exitCode, 1);
    });
  });

  test('invalid package selection does not dispatch hooks', () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeDartSdk().path);
      final invocations = <DepsContext>[];
      addTearDown(addDepsHook((context) {
        invocations.add(context);
        return Future<void>.value();
      }));
      runner.addCommand(DepsCommand());
      await expectLater(runner.run(['deps', '-p', 'missing_package']),
          throwsA(contains('Package with name missing_package not found')));
      expect(invocations, isEmpty);
    });
  });

  test('hook failure propagates and stops later hooks, even with no packages',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(dartSdkPath: fakeDartSdk().path);
      final failure = StateError('setup failed');
      addTearDown(addDepsHook((context) async {
        expect(context.results, isEmpty);
        expect(context.isSuccess, isTrue);
        await Future<void>.error(failure);
      }));
      addTearDown(addDepsHook((_) => Future<void>.error('must not run')));
      runner
          .addCommand(DepsCommand(exclude: [DartPackage.fromDirectory(dir)!]));
      await expectLater(runner.run(['deps']), throwsA(same(failure)));
    });
  });

  test('multiple subscribers run sequentially across command instances',
      () async {
    await insideFakeProjectWithSidekick((_) async {
      final events = <String>[];
      addTearDown(addDepsHook((_) async {
        await Future<void>.delayed(Duration.zero);
        events.add('first');
      }));
      addTearDown(addDepsHook((_) async {
        expect(events.last, 'first');
        await Future<void>.value();
        events.add('second');
      }));
      final sdk = fakeDartSdk();
      for (var i = 0; i < 2; i++) {
        final runner = initializeSidekick(dartSdkPath: sdk.path);
        runner.addCommand(DepsCommand());
        await runner.run(['deps']);
      }
      expect(events, ['first', 'second', 'first', 'second']);
    });
  });

  test(
      'deduplicates registrations and stale removers leave new registrations alone',
      () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeDartSdk().path);
      runner.addCommand(DepsCommand());
      var calls = 0;
      Future<void> hook(DepsContext _) async {
        await Future<void>.value();
        calls++;
      }

      final remove = addDepsHook(hook);
      addTearDown(remove);
      final duplicateRemove = addDepsHook(hook);
      addTearDown(duplicateRemove);
      await runner.run(['deps']);
      expect(calls, 1);
      remove();
      await runner.run(['deps']);
      expect(calls, 1);
      addTearDown(addDepsHook(hook));
      duplicateRemove();
      await runner.run(['deps']);
      expect(calls, 2);
    });
  });

  test('registration changes during dispatch take effect on the next run',
      () async {
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick(dartSdkPath: fakeDartSdk().path);
      runner.addCommand(DepsCommand());
      final events = <String>[];
      Future<void> third(DepsContext _) async {
        await Future<void>.value();
        events.add('third');
      }

      late Removable removeSecond;
      addTearDown(addDepsHook((_) async {
        await Future<void>.value();
        events.add('first');
        removeSecond();
        addTearDown(addDepsHook(third));
      }));
      removeSecond = addDepsHook((_) async {
        await Future<void>.value();
        events.add('second');
      });
      addTearDown(removeSecond);
      await runner.run(['deps']);
      await runner.run(['deps']);
      expect(events, ['first', 'second', 'first', 'third']);
    });
  });
}
