import 'package:sidekick_test/fake_stdio.dart';
import 'package:sk_sidekick/sk_sidekick.dart';
import 'package:sk_sidekick/src/commands/test_sidekick_context_command.dart';
import 'package:test/test.dart';

/// See [TestSidekickContextCommand]
void main() {
  test('SidekickContext provides all information', () async {
    final fakeStdOut = FakeStdoutStream();
    await overrideIoStreams(
      stdout: () => fakeStdOut,
      body: () => runSk(['test-sidekick-context']),
    );
    expect(fakeStdOut.lines, contains('sidekickPackage: .'));
    expect(fakeStdOut.lines, contains('entryPoint: ../sk'));
    expect(fakeStdOut.lines, contains('repository: ..'));
    expect(fakeStdOut.lines.length, 3);
  });
}
