import 'package:actions_toolkit_dart/core.dart' as gha;
import 'package:sidekick_core/sidekick_core.dart';

/// Hides the secret on GitHub Actions, replaces it with '***'
void maskSecret(String secret) {
  if (env['GITHUB_ACTIONS'] == 'true') {
    // hide secret on github actions
    gha.setSecret(secret: secret);
  }
}
