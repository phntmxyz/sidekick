import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';

void main() {
  group('project type detection', () {
    test('init generates cli files', () async {
      final project = setupTemplateProject('test/templates/root_with_packages');
      final process =
          await sidekickCli(['init', '-n', 'dash'], workingDirectory: project);

      await expectLater(
          process.stdout, emitsThrough('Generating dash_sidekick'));
      printOnFailure(await process.stdoutStream().join('\n'));
      printOnFailure(await process.stderrStream().join('\n'));
      await process.shouldExit(0);

      // check entrypoint is executable
      final entrypoint = File("${project.path}/dash");
      expect(entrypoint.existsSync(), isTrue);
      expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

      // check install.sh is executable
      final installSh =
          File("${project.path}/packages/dash_sidekick/tool/install_global.sh");
      expect(installSh.existsSync(), isTrue);
      expect(installSh.statSync().modeString(), 'rwxr-xr-x');

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
        ['update-sidekick'],
        workingDirectory: project.path,
      );
      final stdout = await updateProcess.stdoutStream().join('\n');
      printOnFailure(stdout);
      printOnFailure(await updateProcess.stderrStream().join('\n'));
      updateProcess.shouldExit(0);
      expect(stdout, contains('Installing dash command line application'));
      expect(stdout, contains('Getting dependencies'));
      expect(stdout, contains('Bundling assets'));
      expect(stdout, contains('Compiling dash sidekick'));
    });
  });
}
