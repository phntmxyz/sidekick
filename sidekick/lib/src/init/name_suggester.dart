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
      return dcli.ask('Enter your CLI name').toLowerCase();
    } else {
      return answer.toLowerCase();
    }
  }

  /// Creates a list of acronyms based on the [projectDir] name
  Set<String> suggestCliNames() {
    // reverse to make accessing of the elements easier
    final parts = p
        .split(p.normalize(projectDir.absolute.path))
        .where((element) => element.isNotEmpty)
        .toList()
        .reversed
        .toList(growable: false);

    if (parts.isEmpty) {
      return {};
    }
    final Set<String> suggestions = {};

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

    // TODO acronym should return the filtered syllableWords. We could suggest all of them on their own

    return suggestions;
  }
}
