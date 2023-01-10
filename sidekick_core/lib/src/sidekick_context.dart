import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/sidekick_package.dart';

class SidekickContext {
  SidekickContext._();

  // The Plan

  // Called via entrypoint (bash)
  // - repo root (search up)
  // - entrypoint (env var)
  // - sidekick package

  // Executed for debugging
  // - repo root (search up)
  // - entrypoint !!! missing !!! TODO dumb search in repo
  // - sidekick package !!! missing !!! TODO dart vm Script location?
}
