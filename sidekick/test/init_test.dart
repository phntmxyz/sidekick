import 'package:sidekick/src/init/name_suggester.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';
import 'util/local_testing.dart';

void main() {
  group('sidekick init - simple layout', () {
    test(
      'entrypoint executes fine after sidekick init $localOrPubDepsLabel',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/nested_package');
        final nestedPackage = projectRoot.directory('foo/bar/nested');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: nestedPackage,
        );
        await process.shouldExit(0);
        final entrypoint = File("${nestedPackage.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            nestedPackage.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: nestedPackage.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws error when cli name is invalid',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await sidekickCli(
          ['init', '-n', '-42invalidName'],
          workingDirectory: projectRoot,
        );

        await process.shouldExit(255);
        expect(
          await process.stderr.rest.contains(invalidCliNameErrorMessage),
          isTrue,
        );
      },
    );

    test(
      'throws error when cli name collides with an system executable',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await sidekickCli(
          [
            'init',
            '-n',
            'rm',
          ],
          workingDirectory: projectRoot,
        );

        await process.shouldExit(255);
        final stderrText = await process.stderr.rest.toList();
        expect(
          stderrText,
          contains(
            'The CLI name rm is already taken by an executable on your system see [/bin/rm]',
          ),
        );
      },
    );

    test(
      'after sidekick init in dart package, CLI has a working dart command and no flutter command $localOrPubDepsLabel',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: projectRoot,
        );
        await process.shouldExit(0);
        final entrypoint = File("${projectRoot.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            projectRoot.directory('packages/dashi_sidekick'),
          );
        }

        final dartDashProcess = await TestProcess.start(
          entrypoint.path,
          ['dart'],
          workingDirectory: projectRoot.path,
        );
        printOnFailure(await dartDashProcess.stdoutStream().join('\n'));
        printOnFailure(await dartDashProcess.stderrStream().join('\n'));
        dartDashProcess.shouldExit(0);

        final flutterDashProcess = await TestProcess.start(
          entrypoint.path,
          ['flutter'],
          workingDirectory: projectRoot.path,
        );
        printOnFailure(await flutterDashProcess.stdoutStream().join('\n'));
        printOnFailure(await flutterDashProcess.stderrStream().join('\n'));
        flutterDashProcess.shouldExit(64);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'after sidekick init in flutter package, CLI has working dart and flutter commands $localOrPubDepsLabel',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/minimal_flutter_package');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: projectRoot,
        );
        await process.shouldExit(0);
        final entrypoint = File("${projectRoot.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            projectRoot.directory('packages/dashi_sidekick'),
          );
        }

        final dartDashProcess = await TestProcess.start(
          entrypoint.path,
          ['dart'],
          workingDirectory: projectRoot.path,
        );
        printOnFailure(await dartDashProcess.stdoutStream().join('\n'));
        printOnFailure(await dartDashProcess.stderrStream().join('\n'));
        dartDashProcess.shouldExit(0);

        final flutterDashProcess = await TestProcess.start(
          entrypoint.path,
          ['flutter'],
          workingDirectory: projectRoot.path,
        );
        printOnFailure(await flutterDashProcess.stdoutStream().join('\n'));
        printOnFailure(await flutterDashProcess.stderrStream().join('\n'));
        flutterDashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('sidekick init - packages layout', () {
    test(
      'init generates sidekick package + entrypoint',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dashi_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // root is mainProjectPath
        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          isNot(contains("mainProjectPath: 'packages/dashi_sidekick'")),
        );

        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        // The project itself is a DartPackage
        expect(
          projectFile.readAsStringSync(),
          contains('class DashiProject extends DartPackage'),
        );

        // contains references to all packages of template
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'entrypoint executes fine after sidekick init $localOrPubDepsLabel',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );
        await process.shouldExit(0);
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'init with path (absolute) $localOrPubDepsLabel',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await sidekickCli(
          ['init', '-n', 'dashi', project.absolute.path],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('sidekick init - multi package layout', () {
    test(
      'init generates sidekick package + entrypoint',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dashi_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // no mainProjectPath defined, nothing is set
        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          isNot(contains('mainProjectPath')),
        );

        // contains references to all packages of template
        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'entrypoint executes fine after sidekick init $localOrPubDepsLabel',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );
        await process.shouldExit(0);
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'init with path (absolute) $localOrPubDepsLabel',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dashi', project.absolute.path],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with mainProject $localOrPubDepsLabel',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          [
            'init',
            '-n',
            'dashi',
            '--mainProjectPath',
            'packages/package_a',
            project.absolute.path
          ],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          contains("mainProjectPath: 'packages/package_a'"),
        );

        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
