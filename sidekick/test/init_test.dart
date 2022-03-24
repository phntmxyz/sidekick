import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';
import 'util/local_testing.dart';

void main() {
  group('project type detection', () {
    test(
      'init generates cli files',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await sidekickCli(
          ['init', '-n', 'dash'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dash_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check flutterw exists
        final flutterw = File("${project.path}/flutterw");
        expect(flutterw.existsSync(), isTrue);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'entrypoint executes fine after sidekick init $localOrPubDepsLabel',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await sidekickCli(
          ['init', '-n', 'dash'],
          workingDirectory: project,
        );
        await process.shouldExit(0);
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dash_sidekick'),
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
          ['init', '-n', 'dash', project.absolute.path],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check flutterw exists
        final flutterw = File("${project.path}/flutterw");
        expect(flutterw.existsSync(), isTrue);

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dash_sidekick'),
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

  group('multi package type detection', () {
    test(
      'init generates cli files',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dash'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dash_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check flutterw exists
        final flutterw = File("${project.path}/flutterw");
        expect(flutterw.existsSync(), isTrue);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'entrypoint executes fine after sidekick init',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dash'],
          workingDirectory: project,
        );
        await process.shouldExit(0);
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);

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
      'init with path (absolute)',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await sidekickCli(
          ['init', '-n', 'dash', project.absolute.path],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dash");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check flutterw exists
        final flutterw = File("${project.path}/flutterw");
        expect(flutterw.existsSync(), isTrue);

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
