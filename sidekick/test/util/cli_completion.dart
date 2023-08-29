// Copied and adapted from package:cli_completion, file https://github.com/VeryGoodOpenSource/cli_completion/blob/a5b3571c03d964c08c6ce52b1cc907b2f93c0861/example/test/integration/utils.dart

import 'dart:async';

import 'package:test/test.dart';

import 'cli_runner.dart';

extension RunCompletionCommandExtension on SidekickCli {
  /// Returns a matcher that matches if the tab completion of this CLI returns the given suggestions
  ///
  /// This is done by running the hidden 'completion' command of the CLI and checking its result
  Matcher suggests(Map<String, String?> suggestions, {int? whenCursorIsAt}) =>
      _CliCompletionMatcher(
        suggestions,
        cursorIndex: whenCursorIsAt,
        cli: this,
      );

  Future<Map<String, String?>> _runCompletionCommand(
    String line, {
    int? cursorIndex,
  }) async {
    final environmentOverride = {
      'SHELL': '/foo/bar/zsh',
      ..._prepareEnvForLineInput(line, cursorIndex: cursorIndex),
    };
    final process = await run(['completion'], environment: environmentOverride);
    final completions = await process.stdoutStream().toList();
    final map = <String, String?>{};

    for (final completionString in completions) {
      // A regex that finds all colons, except the ones preceded by backslash
      final res = completionString.split(RegExp(r'(?<!\\):'));

      final description = res.length > 1 ? res[1] : null;

      map[res.first] = description;
    }

    return map;
  }
}

class _CliCompletionMatcher extends CustomMatcher {
  final SidekickCli cli;

  _CliCompletionMatcher(
    Map<String, String?> suggestions, {
    required this.cli,
    this.cursorIndex,
  }) : super(
          'Completes with the expected suggestions',
          'suggestions',
          completion(suggestions),
        );

  final int? cursorIndex;

  @override
  Object? featureValueOf(dynamic line) {
    if (line is! String) {
      throw ArgumentError.value(line, 'line', 'must be a String');
    }

    return cli._runCompletionCommand(line, cursorIndex: cursorIndex);
  }
}

/// Simulate the shell behavior of completing a command line.
Map<String, String> _prepareEnvForLineInput(String line, {int? cursorIndex}) {
  final cpoint = cursorIndex ?? line.length;
  var cword = 0;
  line.split(' ').fold(0, (value, element) {
    final total = value + 1 + element.length;
    if (total < cpoint) {
      cword++;
      return total;
    }
    return value;
  });
  return {
    'COMP_LINE': line,
    'COMP_POINT': '$cpoint',
    'COMP_CWORD': '$cword',
  };
}
