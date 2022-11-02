import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'fake_sdk.dart';
import 'init_test.dart';

void main() {
  test('flutter command works when flutterSdkPath is set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        flutterSdkPath: fakeFlutterSdk().path,
      );
      runner.addCommand(FlutterCommand());
      await runner.run(['flutter']);
    });
  });

  test('flutter command fails when flutterSdkPath is not set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        // ignore: avoid_redundant_argument_values
        flutterSdkPath: null,
      );
      runner.addCommand(FlutterCommand());
      try {
        await runner.run(['flutter']);
        fail('did not throw');
      } catch (e) {
        expect(e, isA<FlutterSdkNotSetException>());
      }
    });
  });

  group('addFlutterSdkInitializer()', () {
    test('initializer is executed before executing the flutter command',
        () async {
      await insideFakeProjectWithSidekick((dir) async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: tempDir.path,
        );
        runner.addCommand(FlutterCommand());

        bool called = false;
        addFlutterSdkInitializer((sdkDir) {
          fakeFlutterSdk(directory: tempDir);
          return Future.sync(() {
            called = true;
          });
        });
        await runner.run(['flutter']);
        expect(called, isTrue);
      });
    });

    test(
        'multiple initializers are executed before executing the flutter command',
        () async {
      await insideFakeProjectWithSidekick((dir) async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: tempDir.path,
        );
        runner.addCommand(FlutterCommand());

        bool called1 = false;
        addFlutterSdkInitializer((sdkDir) {
          // async
          fakeFlutterSdk(directory: tempDir);
          return Future.sync(() {
            called1 = true;
          });
        });

        bool called2 = false;
        addFlutterSdkInitializer((sdkDir) {
          // sync
          called2 = true;
        });

        await runner.run(['flutter']);
        expect(called1, isTrue);
        expect(called2, isTrue);
      });
    });

    test('The same initializer is only added once', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: tempDir.path,
        );
        runner.addCommand(FlutterCommand());

        int called = 0;
        void initializer(Directory path) {
          called++;
        }

        addFlutterSdkInitializer(initializer);
        addFlutterSdkInitializer(initializer);

        await runner.run(['flutter']).onError((error, stackTrace) {
          // ignore
        });
        expect(called, 1);
      });
    });

    test('Removing an initializer, prevents execution', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: tempDir.path,
        );
        runner.addCommand(FlutterCommand());

        int called = 0;
        void initializer(Directory path) {
          called++;
        }

        final remove = addFlutterSdkInitializer(initializer);

        await runner.run(['flutter']).onError((error, stackTrace) {
          // ignore
        });
        expect(called, 1);

        await runner.run(['flutter']).onError((error, stackTrace) {
          // ignore
        });
        expect(called, 2);

        remove();
        await runner.run(['flutter']).onError((error, stackTrace) {
          // ignore
        });
        expect(called, 2);
      });
    });
  });
}
