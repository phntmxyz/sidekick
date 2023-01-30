import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'util/cli_runner.dart';

void main() {
  test(
    'init generates cli files',
    () async {
      await withSidekickCli((cli) async {
        // check entrypoint is executable
        final entrypoint = File("${cli.root.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // check install.sh is executable
        final installSh =
            File("${cli.root.path}/dashi_sidekick/tool/install.sh");
        expect(installSh.existsSync(), isTrue);
        expect(installSh.statSync().modeString(), 'rwxr-xr-x');

        // runs the main executable fine
        await cli.run([]);

        // recompile works
        final updateProcess = await TestProcess.start(
          entrypoint.path,
          ['sidekick', 'recompile'],
          workingDirectory: cli.root.path,
        );
        final stdout = await updateProcess.stdoutStream().join('\n');
        printOnFailure(stdout);
        final stderr = await updateProcess.stderrStream().join('\n');
        printOnFailure(stderr);
        updateProcess.shouldExit(0);
        expect(stderr, contains('Installing dashi command line application'));
        expect(stderr, contains('Getting dependencies'));
        expect(stderr, contains('Bundling assets'));
        expect(stderr, contains('Compiling sidekick cli'));
        expect(stderr, contains('Success!'));
      });
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
