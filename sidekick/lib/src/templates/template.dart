import 'package:mason/mason.dart';

/// Represents a Sidekick Template.
/// Each Sidekick template contains a [MasonBundle],
/// a name and a help text which is holding
/// the description of the template.

abstract class Template {
  const Template({
    required this.name,
    required this.bundle,
    required this.help,
  });

  // The name of the template.
  final String name;

  // The bundle of the template.
  final MasonBundle bundle;

  // The help text with the description of the template.
  final String help;
}
