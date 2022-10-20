import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';
import 'util/local_testing.dart';

void main() {
  group('project type detection', () {
    test(
      'init generates cli files $localOrPubDepsLabel',
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

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check install.sh is executable
        final installSh =
            File("${project.path}/packages/dashi_sidekick/tool/install.sh");
        expect(installSh.existsSync(), isTrue);
        expect(installSh.statSync().modeString(), 'rwxr-xr-x');

        if (shouldUseLocalDevs) {
          overrideSidekickCoreWithLocalPath(
            project.directory('packages/dashi_sidekick'),
          );
        }

        // runs the main executable fine
        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);

        // recompile works
        final updateProcess = await TestProcess.start(
          entrypoint.path,
          ['recompile'],
          workingDirectory: project.path,
        );
        final stdout = await updateProcess.stdoutStream().join('\n');
        printOnFailure(stdout);
        printOnFailure(await updateProcess.stderrStream().join('\n'));
        updateProcess.shouldExit(0);
        expect(stdout, contains('Installing dashi command line application'));
        expect(stdout, contains('Getting dependencies'));
        expect(stdout, contains('Bundling assets'));
        expect(stdout, contains('Compiling sidekick cli'));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
