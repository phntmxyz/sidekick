import 'dart:io';

import 'package:sidekick_test/fake_stdio.dart';
import 'package:test/test.dart';

void main() {
  test('captures stdout and stderr separately', () {
    final streams = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () {
        stdout.writeln('stdout line 1');
        stderr.writeln('stderr line 1');
        stdout.writeln('stdout line 2');
      },
    );

    expect(streams.stdout.lines, ['stdout line 1', 'stdout line 2']);
    expect(streams.stderr.lines, ['stderr line 1']);
  });

  test('captures combined output in correct order', () {
    final streams = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () {
        stdout.writeln('first');
        stderr.writeln('second');
        stdout.writeln('third');
        stderr.writeln('fourth');
      },
    );

    expect(streams.combined, ['first', 'second', 'third', 'fourth']);
  });

  test('works with print() statements', () {
    final streams = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () {
        print('printed to stdout');
        stderr.writeln('written to stderr');
        print('another print');
      },
    );

    expect(streams.stdout.lines, ['printed to stdout', 'another print']);
    expect(streams.stderr.lines, ['written to stderr']);
    expect(
      streams.combined,
      ['printed to stdout', 'written to stderr', 'another print'],
    );
  });

  test('handles different write methods', () {
    final streams = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () {
        stdout.write('write');
        stdout.writeln('ln');
        stdout.writeAll(['a', 'b', 'c'], ',');
        stderr.write('error');
      },
    );

    expect(streams.stdout.lines, ['write', 'ln', 'a,b,c']);
    expect(streams.stderr.lines, ['error']);
    expect(streams.combined, ['write', 'ln', 'a,b,c', 'error']);
  });

  test('captures interleaved writes correctly', () {
    final streams = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () {
        for (int i = 0; i < 5; i++) {
          if (i.isEven) {
            stdout.writeln('out $i');
          } else {
            stderr.writeln('err $i');
          }
        }
      },
    );

    expect(streams.stdout.lines, ['out 0', 'out 2', 'out 4']);
    expect(streams.stderr.lines, ['err 1', 'err 3']);
    expect(
      streams.combined,
      ['out 0', 'err 1', 'out 2', 'err 3', 'out 4'],
    );
  });

  test('works with async code', () async {
    final streams = FakeIoStreams();

    await overrideIoStreams(
      stdout: () => streams.stdout,
      stderr: () => streams.stderr,
      body: () async {
        print('before await');
        await Future.delayed(Duration.zero);
        stderr.writeln('after await');
        await Future.delayed(Duration.zero);
        print('final line');
      },
    );

    expect(streams.stdout.lines, ['before await', 'final line']);
    expect(streams.stderr.lines, ['after await']);
    expect(streams.combined, ['before await', 'after await', 'final line']);
  });

  test('can be used multiple times', () {
    final streams1 = FakeIoStreams();
    final streams2 = FakeIoStreams();

    overrideIoStreams(
      stdout: () => streams1.stdout,
      stderr: () => streams1.stderr,
      body: () {
        print('first');
      },
    );

    overrideIoStreams(
      stdout: () => streams2.stdout,
      stderr: () => streams2.stderr,
      body: () {
        print('second');
      },
    );

    expect(streams1.stdout.lines, ['first']);
    expect(streams1.combined, ['first']);
    expect(streams2.stdout.lines, ['second']);
    expect(streams2.combined, ['second']);
  });
}
