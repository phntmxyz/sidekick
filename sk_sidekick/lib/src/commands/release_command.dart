import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/sk_sidekick.dart';
import 'package:yaml/yaml.dart';

class ReleaseCommand extends Command {
  @override
  final String description = 'Releases new version of a package';

  @override
  final String name = 'release';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        '[package-path]',
      );

  @override
  Future<void> run() async {
    final packagePath = argResults!.rest.firstOrNull ?? Directory.current.path;
    final package = DartPackage.fromDirectory(Directory(packagePath));
    if (package == null) {
      throw 'Could not find a package in $packagePath';
    }

    print('You started the release process for package:${package.name}.');
    final proceed = confirm(
      'Do you want to release a new version?',
      defaultValue: false,
    );
    if (!proceed) {
      exitCode = 1;
      return;
    }

    _warnIfNotOnDefaultBranch(package.root);

    while (gitRepoHasLocalChanges(package.root)) {
      ask(
        red('Your repository contains local changes. '
            'Please remove them and hit enter to continue'),
        required: false,
      );
    }

    final nextReleaseChangelog = _prepareNextReleaseChangelog(package);
    final nextVersion = _bumpVersion(package);

    print('Creating changelog ...');
    final changelog = package.root.file('CHANGELOG.md');
    changelog.writeAsStringSync('''
# Changelog

## $nextVersion

${nextReleaseChangelog.readAsStringSync().trim()}

${changelog.readAsStringSync().replaceFirst('# Changelog', '').trimLeft()}''');
    nextReleaseChangelog.deleteSync();

    final bool lock = package == skProject.sidekickPackage;
    if (lock) {
      print('Locking dependencies ...');
      await runSk(['lock-dependencies', package.root.path]);
    }

    final tag = '${package.name}-v$nextVersion';
    final commitMessage = 'Prepare release $tag';
    print('Creating commit "Prepare release "$commitMessage" '
        'and tagging release as $tag');
    for (final cmd in [
      'git add -A ${package.root.path}',
      'git commit -m "$commitMessage"',
      'git tag $tag'
    ]) {
      cmd.start(workingDirectory: repository.root.path);
    }

    final publish =
        confirm('Do you want to publish $tag to pub.dev?', defaultValue: false);
    if (!publish) {
      exitCode = 1;
      return;
    }

    'git push origin refs/tags/$tag'.start(workingDirectory: package.root.path);

    // TODO remove --dry-run when ready
    'dart pub lish --dry-run'.start(workingDirectory: package.root.path);
    print(
      green(
        '🎉 Success!\n'
        '${package.name}:$nextVersion has been released to pub '
        'https://pub.dev/packages/${package.name}/versions/$nextVersion',
      ),
    );
  }

  Version _bumpVersion(DartPackage package) {
    const major = 'Major (breaking changes)';
    const minor = 'Minor (new features) (default)';
    const patch = 'Patch (bug fixes)';
    print('Considering the changelog, what kind of release do you want to do?');
    final releaseType = menu(
      prompt: 'Please select a release type',
      options: [major, minor, patch],
      defaultOption: minor,
    );
    final nextVersion = () {
      final current = Version.parse(package.version);
      switch (releaseType) {
        case major:
          return current.nextMajor;
        case minor:
          return current.nextMinor;
        case patch:
          return current.nextPatch;
        default:
          throw StateError('unreachable');
      }
    }();

    print('Bumping version to $nextVersion ...');
    '${Repository.requiredEntryPoint.path} '
            'bump-version ${package.root.path} '
            '--${releaseType.split(' ').first.toLowerCase()} '
            '--no-commit'
        .run;
    return nextVersion;
  }

  /// Returns file `NEXT_RELEASE_CHANGELOG.md` which contains the changelog
  /// for the new version that should be released
  ///
  /// The file is generated by getting all changes in the repository from
  /// the tag '<package name>-v<current package version>' until HEAD
  ///
  /// Initially, the file contains one line for each change
  /// formatted as '<hash> <commit title>'
  ///
  /// The user is then asked to edit the file and it is returned once it
  /// differs from the initially generated content and the user confirms it
  File _prepareNextReleaseChangelog(DartPackage package) {
    final currentPackageVersionTag = '${package.name}-v${package.version}';
    print('Calculating diff between $currentPackageVersionTag and HEAD ...');
    final packageChanges =
        _getChanges(from: currentPackageVersionTag, paths: [package.root.path]);
    if (packageChanges.isEmpty) {
      throw 'No commits found since last release';
    }
    print('Found ${packageChanges.length} commits since last release');

    // also check sidekick_core updates
    final sidekickCoreChanges = _getSidekickCoreChanges(package);

    final initialChangelog =
        [...packageChanges, ...?sidekickCoreChanges].join('\n');
    final nextReleaseChangelog = package.root.file('NEXT_RELEASE_CHANGELOG.md')
      ..writeAsStringSync(initialChangelog);

    print('''
${nextReleaseChangelog.path} has been automatically created containing all relevant commits/PRs for this release. Please edit this before it will be used as changelog for this release.
- Combine connected commits into meaningful items
- Remove commits that have been reverted
- Add examples how to use the new APIs (check PRs for examples/tests)
- Highlight breaking changes

${cyan('Please open NEXT_RELEASE_CHANGELOG.md with the editor of your choice and edit it according to the instructions.')}
''');

    while (initialChangelog == nextReleaseChangelog.readAsStringSync()) {
      sleep(1);
    }

    while (!confirm(
      'Do you want to continue the release process with the changelog in NEXT_RELEASE_CHANGELOG.md?',
      defaultValue: false,
    )) {}

    return nextReleaseChangelog;
  }

  String? _getMinSidekickCoreVersion(String pubspec) {
    final doc = loadYamlDocument(pubspec);
    final ps = doc.contents.value as YamlMap;
    final constraint = ps['dependencies']['sidekick_core'] as String?;
    if (constraint == null) {
      return null;
    }
    return VersionConstraint.parse(constraint).minVersion.toString();
  }

  List<String>? _getSidekickCoreChanges(DartPackage package) {
    final currentSidekickCoreVersion =
        _getMinSidekickCoreVersion(package.pubspec.readAsStringSync());
    if (currentSidekickCoreVersion != null) {
      final currentSidekickCoreVersionTag =
          'sidekick_core-v$currentSidekickCoreVersion';

      final oldPubspecContent =
          'git show $currentSidekickCoreVersionTag:${package.name}/pubspec.yaml'
              .start(progress: Progress.capture())
              .lines
              .join('\n');
      final oldSidekickCoreVersion =
          _getMinSidekickCoreVersion(oldPubspecContent);

      if (oldSidekickCoreVersion != null &&
          currentSidekickCoreVersion != oldSidekickCoreVersion) {
        final oldSidekickCoreVersionTag =
            'sidekick_core-v$oldSidekickCoreVersion';
        final newSidekickCoreCommits = _getChanges(
          from: oldSidekickCoreVersionTag,
          to: currentSidekickCoreVersionTag,
          paths: ['sidekick_core'],
        );

        final message = '\nAlso package:sidekick_core updated '
            '($oldSidekickCoreVersionTag -> $currentSidekickCoreVersionTag), '
            'please consider those changes as well.\n';

        return [message, ...newSidekickCoreCommits];
      }
    }
    return null;
  }
}

bool gitRepoHasLocalChanges(Directory directory) => 'git status --porcelain'
    .start(progress: Progress.capture(), workingDirectory: directory.path)
    .lines
    .isNotEmpty;

/// Returns all changes in the history from [from] (default: HEAD) to [to]
/// If [paths] is given, returns only commits which modified [paths]
///
/// The format of each line is '<commit hash> <commit title>'
List<String> _getChanges({
  required String from,
  String? to = 'HEAD',
  List<String> paths = const [],
}) =>
    // %H = commit hash, %b = commit title
    "git log --format='%H %s' $from..$to -- ${paths.join(' ')}"
        .start(progress: Progress.capture())
        .lines;

void _warnIfNotOnDefaultBranch(Directory directory) {
  final path = directory.path;
  final defaultBranch = 'git rev-parse --abbrev-ref origin/HEAD'
      .start(progress: Progress.capture(), workingDirectory: path)
      .firstLine
      ?.removePrefix('origin/');

  if (defaultBranch == null) {
    throw "Couldn't determine default branch for git repository at $path";
  }

  final currentBranch = 'git branch --show-current'
      .start(progress: Progress.capture(), workingDirectory: path)
      .firstLine;

  if (currentBranch == null) {
    throw "Couldn't determine current branch for git repository at $path";
  }

  if (defaultBranch != currentBranch) {
    final proceed = confirm(
      "Are you sure you want to release a new version from "
      "branch '$currentBranch'? This differs from the default "
      "branch '$defaultBranch'.",
      defaultValue: false,
    );
    if (!proceed) {
      exit(1);
    }
  }
}

extension on VersionConstraint {
  Version get minVersion {
    final versionConstraint = this;
    if (versionConstraint is VersionRange) {
      final minVersion = versionConstraint.min;
      if (minVersion == null) {
        return Version.none;
      }
      return versionConstraint.includeMin ? minVersion : minVersion.nextPatch;
    } else if (versionConstraint is Version) {
      return versionConstraint;
    } else {
      throw 'Unknown $versionConstraint';
    }
  }
}

extension on DartPackage {
  String get version {
    final doc = loadYamlDocument(pubspec.readAsStringSync());
    final pubspecContent = doc.contents.value as YamlMap;
    final version = pubspecContent['version'] as String?;
    if (version == null) {
      throw 'package:$name has no version';
    }
    return version;
  }
}
