import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:sidekick_core/sidekick_core.dart';

class BumpVersionCommand extends Command {
  @override
  final String description = 'Bumps the version of a package';

  @override
  final String name = 'bump-version';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        '[package-path] [--minor|patch|major] --[no-]commit',
      );

  BumpVersionCommand() {
    argParser.addFlag(
      'major',
      help: 'Bumps to the next major version. e.g. 1.2.6 => 2.0.0',
    );
    argParser.addFlag(
      'minor',
      help: 'Bumps to the next minor version (default). e.g. 1.2.6 => 1.3.0',
    );
    argParser.addFlag(
      'patch',
      help: 'Bumps to the next patch version. e.g. 1.2.6 => 1.2.7',
    );
    argParser.addOption(
      'exact',
      help: 'Sets an exact version. e.g. 1.2.6-dev.1',
    );
    argParser.addFlag(
      'commit',
      help:
          'Automatically commits the version bump. Precondition, no local changes in pubspec.yaml',
    );
    addModification(bumpPubspecVersion);
  }

  final List<FileModification> _modifications = [];

  void addModification(FileModification modification) {
    _modifications.add(modification);
  }

  @override
  Future<void> run() async {
    final bool bumpMajor = argResults?['major'] as bool? ?? false;
    bool bumpMinor = argResults?['minor'] as bool? ?? false; // default
    final bool bumpPatch = argResults?['patch'] as bool? ?? false;
    final exact = argResults?['exact'] as String?;
    final exactVersion = exact != null ? Version.parse(exact) : null;

    final bool commit = argResults?['commit'] as bool? ?? false;

    if (exact != null && (bumpMajor || bumpMinor || bumpPatch)) {
      error('Either bump major, minor or patch or set an exact version');
    }

    if (bumpMinor && bumpPatch) {
      error('Either bump minor or patch');
    }
    if (!bumpMinor && !bumpPatch && exact == null) {
      // default to minor bump
      bumpMinor = true;
    }

    final package = DartPackage.fromArgResults(argResults!);
    final pubspecFile = package.pubspec;
    final version = Pubspec.parse(pubspecFile.readAsStringSync()).version!;

    final newVersion = () {
      if (exactVersion != null) {
        if (exactVersion < version) {
          error(
            'Exact version $exactVersion must be greater '
            'than current version $version',
          );
        }
        return exactVersion;
      }
      if (bumpMajor) {
        return version.nextMajor;
      }
      if (bumpPatch) {
        return version.nextPatch;
      }

      // default: bumpMinor
      return version.nextMinor;
    }();

    void applyModifications() {
      for (final modification in _modifications) {
        modification.call(package, version, newVersion);
      }
    }

    bool bumped = false;
    if (commit) {
      final detachedHEAD = 'git symbolic-ref -q HEAD'.start(
        progress: Progress.printStdErr(),
        nothrow: true,
      );
      if (detachedHEAD.exitCode != 0) {
        printerr(
          'You are in "detached HEAD" state. '
          'Not committing version bump',
        );
      } else {
        commitFileModifications(
          applyModifications,
          commitMessage: 'Bump version to $newVersion',
        );
        bumped = true;
      }
    }
    if (!bumped) {
      applyModifications();
    }
    print(green('Bumped ${package.name} from $version to $newVersion'));
  }

  /// Updates the version in pubspec.yaml
  void bumpPubspecVersion(
    DartPackage package,
    Version oldVersion,
    Version newVersion,
  ) {
    // Update version in pubspec.yaml
    package.pubspec.replaceSectionWith(
      startTag: 'version:',
      endTag: '\n',
      content: ' $newVersion',
    );
  }
}

typedef FileModification = void Function(
    DartPackage package, Version oldVersion, Version newVersion);

/// Commits only the file changes that have been done in [block]
void commitFileModifications(
  void Function() block, {
  required String commitMessage,
}) {
  final stashName = 'pre-bump-${DateTime.now().toIso8601String()}';

  // stash changes
  'git stash save --include-untracked "$stashName"'.start(
    progress: Progress.printStdErr(),
  );

  try {
    // apply modifications
    block();

    // commit
    'git add -A'.start(progress: Progress.printStdErr());
    'git commit -m "$commitMessage" --no-verify'.start(
      progress: Progress.printStdErr(),
    );
    'git --no-pager log -n1 --oneline'.run;
  } catch (e) {
    printerr('Detected error, discarding modifications');
    // discard all modifications
    'git reset --hard'.start(progress: Progress.printStdErr());
    rethrow;
  } finally {
    final stashes = 'git stash list'.start(progress: Progress.capture()).lines;
    final stash = stashes.firstOrNullWhere((line) => line.contains(stashName));
    if (stash != null) {
      final stashId = RegExp(r'stash@{(\d+)}').firstMatch(stash)?.group(1);
      // restore changes
      'git stash pop $stashId'.start(progress: Progress.printStdErr());
    }
  }
}

extension VersionExtensions on Version {
  /// Creates a copy of [Version], optionally changing [preRelease] and [build]
  Version Function({String? preRelease, String? build}) get copyWith =>
      _copyWith;

  /// Makes it distinguishable if users used `null` or did not provide any value
  static const _defaultParameter = Object();

  // copyWith version which handles `null`, as in freezed
  Version _copyWith({
    dynamic preRelease = _defaultParameter,
    dynamic build = _defaultParameter,
  }) {
    return Version(
      major,
      minor,
      patch,
      pre: () {
        if (preRelease == _defaultParameter) {
          if (this.preRelease.isEmpty) {
            return null;
          }
          return this.preRelease.join('.');
        }
        return preRelease as String?;
      }(),
      build: () {
        if (build == _defaultParameter) {
          if (this.build.isEmpty) {
            return null;
          }
          return this.build.join('.');
        }
        return build as String?;
      }(),
    );
  }
}
