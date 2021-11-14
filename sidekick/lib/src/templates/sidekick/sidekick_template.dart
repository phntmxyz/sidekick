import 'package:sidekick/src/templates/sidekick/sidekick_bundle.dart';
import 'package:sidekick/src/templates/template.dart';

/// The template to generate the basic Sidekick Structure
class SidekickTemplate extends Template {
  SidekickTemplate()
      : super(
          name: 'Sidekick',
          bundle: sidekickBundle,
          help: 'Generate the basic Sidekick Structure with some starter commands',
        );
}
