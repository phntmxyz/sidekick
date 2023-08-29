import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'util/cli_completion.dart';
import 'util/cli_runner.dart';

void main() {
  /// Tests in this file install a sidekick CLI named 'dashi' globally.
  /// To make sure this doesn't interfere with other tests, delete the symlink
  void uninstallGlobalCli() {
    // TODO use GlobalSidekickRoot.binDir when made available through updated sidekick_core dependency
    final userHome = Platform.environment['HOME']!;
    final sidekickBinDir = Directory('$userHome/.sidekick/bin');
    if (!sidekickBinDir.existsSync()) {
      return;
    }
    // beware: sidekickBinDir.file('dashi').existsSync() always returns false because it's a link, not a file
    final dashiSymLink = sidekickBinDir
        .listSync()
        .firstOrNullWhere((element) => element.name == 'dashi');

    if (dashiSymLink != null) {
      dashiSymLink.deleteSync();
    }
  }

  setUp(uninstallGlobalCli);
  tearDown(uninstallGlobalCli);

  test('Prints info when tab completions are not installed', () async {
    await withSidekickCli((cli) async {
      final p = await cli.run([]);

      final command = yellow('dashi sidekick install-global');
      final expectedMessage =
          '${cyan('Run')} $command ${cyan('to enable tab completion.')}';

      final stdout = await p.stdoutStream().toList();
      expect(stdout, contains(expectedMessage));
    });
  });

  test('Tab prints completions', () async {
    await withSidekickCli(
      (cli) async {
        await expectLater(
          'dashi',
          cli.suggests({
            'dart': 'Calls dart',
            'deps': 'Gets dependencies for all packages',
            'clean': 'Cleans the project',
            'analyze': 'Dart analyzes the whole project',
            'format': 'Formats all Dart files in the repository.',
            'sidekick': 'Manages the sidekick CLI',
            '--help': 'Print this usage information.',
            '--version': 'Print the sidekick version of this CLI.',
          }),
        );
      },
    );
  });
}
