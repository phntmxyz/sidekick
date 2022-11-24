import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';

class BumpVersionCommand extends Command {
  @override
  final String description = 'Bumps the version of a package';

  @override
  final String name = 'bump-version';

  @override
  String get invocation => super.invocation.replaceFirst(
        ' [arguments]',
        '<package-path> --major|minor|patch --[no-]commit',
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

    final bool commit = argResults?['commit'] as bool? ?? false;

    if (bumpMinor && bumpPatch) {
      error('Either bump minor or patch');
    }
    if (!bumpMinor && !bumpPatch) {
      // default to minor bump
      bumpMinor = true;
    }

    final packagePath = argResults!.rest.firstOrNull ?? Directory.current.path;
    final package = DartPackage.fromDirectory(Directory(packagePath));
    if (package == null) {
      throw 'Could not find a package in $packagePath';
    }

    final pubspecFile = package.pubspec;
    final pubSpec = PubSpec.fromFile(pubspecFile.path);
    final version = pubSpec.version!;

    final newVersion = () {
      if (bumpMajor) {
        return version.nextMajor;
      }
      if (bumpMinor) {
        return version.nextMinor;
      }
      if (bumpPatch) {
        return version.nextPatch;
      }

      // default
      return version.nextMajor;
    }();

    void applyModifications() {
      for (final modification in _modifications) {
        modification.call(package, version, newVersion);
      }
    }

    bool bumped = false;
    if (commit) {
      final detachedHEAD = 'git symbolic-ref -q HEAD'
          .start(progress: Progress.printStdErr(), nothrow: true);
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
  DartPackage package,
  Version oldVersion,
  Version newVersion,
);

/// Commits only the file changes that have been done in [block]
void commitFileModifications(
  void Function() block, {
  required String commitMessage,
}) {
  // stash changes
  'git stash save --include-untracked'.start(progress: Progress.printStdErr());

  try {
    // apply modifications
    block();

    // commit
    'git add -A'.start(progress: Progress.printStdErr());
    'git commit -m "$commitMessage" --no-verify'
        .start(progress: Progress.printStdErr());
    'git --no-pager log -n1 --oneline'.run;
  } catch (e) {
    printerr('Detected error, discarding modifications');
    // discard all modifications
    'git reset --hard'.start(progress: Progress.printStdErr());
    rethrow;
  } finally {
    // restore changes
    'git stash pop 0'.start(progress: Progress.printStdErr());
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
