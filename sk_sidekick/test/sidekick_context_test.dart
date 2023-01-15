import 'dart:io';

import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:sk_sidekick/sk_sidekick.dart';
import 'package:sk_sidekick/src/commands/test_sidekick_context_command.dart';
import 'package:test/test.dart';

void main() {
  test('SidekickContext is fully available', () async {
    final fakeStdOut = FakeStdoutStream();
    await overrideIoStreams(
      stdout: () => fakeStdOut,
      // see TestSidekickContextCommand
      body: () => runSk(['test-sidekick-context']),
    );
    expect(fakeStdOut.lines, contains('sidekickPackage: .'));
  });
}
