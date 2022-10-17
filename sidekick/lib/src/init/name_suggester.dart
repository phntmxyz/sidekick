import 'dart:io';

import 'package:acronym/acronym.dart';
import 'package:dartx/dartx.dart';
import 'package:dcli/dcli.dart' as dcli;
import 'package:path/path.dart' as p;

/// Helps users to find a short, pregnant name for their CLI
class NameSuggester {
  NameSuggester({required this.projectDir});

  final Directory projectDir;

  /// Ask the user for a cli name via stdin.
  ///
  /// It first suggests names in a menu, but also allows free text input
  String? askUserForName() {
    final suggestions = suggestCliNames()
        .map((it) => it.toLowerCase())
        .sortedBy((it) => it.length);
    final names = [
      ...suggestions,
      'Enter your own',
    ];

    final String answer = dcli.menu(
      options: names,
      prompt: 'Type the number of the fitting acronym or choose Enter your own',
    );
    if (answer == '') {
      // no name provided, default in terminal without stdin
      return null;
    }
    if (answer == names.last) {
      return dcli.ask(
        'Enter your CLI name',
        validator: const CliNameValidator(),
      );
    } else {
      return answer;
    }
  }

  /// Creates a list of acronyms based on the [projectDir] name
  Set<String> suggestCliNames() {
    // valid cli names should not contain spaces or dashes
    final normalizedName = p.normalize(
      projectDir.absolute.path.replaceAll('-', '_').replaceAll(' ', '_'),
    );
    // reverse to make accessing of the elements easier
    final parts = p
        .split(normalizedName)
        .where((element) => element.isNotEmpty)
        .toList()
        .reversed
        .toList(growable: false);

    if (parts.isEmpty) {
      return {};
    }
    final Set<String> suggestions = {};

    try {
      final dirName = parts[0];
      suggestions.add(dirName.toAcronym());
      suggestions.add(dirName.toAcronym(splitSyllables: true));
      if (parts.length >= 2) {
        // include parent dir
        final parentDirName = parts[1];
        final name = '$parentDirName/$dirName';
        suggestions.add(name.toAcronym());
        suggestions.add(name.toAcronym(splitSyllables: true));
      }

      // first last character variant
      final chars = dirName.characters.where((it) => it.isAscii);
      if (chars.length >= 2) {
        suggestions.add('${chars.first}${chars.last}');
      }
    } catch (_) {
      // `toAcronym` throws an ArgumentError if the input only contains
      // punctuation symbols. However, '_' is a valid dart package name.
    }

    // TODO acronym should return the filtered syllableWords. We could suggest all of them on their own

    return suggestions
        .map((e) => e.toLowerCase())
        .where(isValidCliName)
        .toSet();
  }
}

class CliNameValidator extends dcli.AskValidator {
  const CliNameValidator();

  @override
  String validate(String line) {
    if (!isValidCliName(line)) {
      throw dcli.AskValidatorException(dcli.red(invalidCliNameErrorMessage));
    }

    return line;
  }
}

const invalidCliNameErrorMessage = 'The CLI name must be valid: '
    'at least one lower case letter or underscore '
    'followed by zero or more lower case letters, digits, or underscores.';

// TODO replace with sidekick_core isValidPubPackageName once published
// https://github.com/phntmxyz/sidekick/pull/62
bool isValidCliName(String name) => _cliNameRegExp.hasMatch(name);

// See https://dart.dev/tools/pub/pubspec#name and https://github.com/dart-lang/sdk/blob/8d262e294400d2f7e41f05579c088a6409a7b2bb/pkg/dartdev/lib/src/utils.dart#L95
final RegExp _cliNameRegExp = RegExp(r'^[a-z_][a-z\d_]*$');
