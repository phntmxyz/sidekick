import 'dart:async';

import 'package:args/command_runner.dart';

/// Command which only executes the given [block]
class DelegatedCommand extends Command {
  DelegatedCommand({
    required this.name,
    required this.block,
  });

  @override
  String get description => 'delegated';

  @override
  final String name;

  // ignore: avoid_futureor_void
  final FutureOr<void> Function() block;

  @override
  Future<void> run() async {
    await block();
  }
}
