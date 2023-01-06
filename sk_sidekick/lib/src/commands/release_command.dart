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
    final package = DartPackage.fromArgResults(argResults!);

    print('Hey ${_getGitUserName() ?? 'developer'}, '
        'you started the release process for package:${package.name}.');
    final proceed = confirm(
      'Do you want to release a new version?',
      defaultValue: false,
    );
    if (!proceed) {
      exitCode = 1;
      return;
    } else {
      print(' ');
    }

    _warnIfNotOnDefaultBranch(package.root);

    while (_gitRepoHasChangesIn(package.root)) {
      ask(
        red('package:${package.name} contains local changes. '
            'Please remove/commit them, then hit enter to continue'),
        required: false,
      );
    }

    final nextReleaseChangelog = _prepareNextReleaseChangelog(package);

    print("\nChangelog for this release:\n${grey(nextReleaseChangelog)}\n");

    final versionBumpType = _askForBumpType(package);
    final Version nextVersion = () {
      final current = Version.parse(package.version);
      switch (versionBumpType) {
        case 'major':
          return current.nextMajor;
        case 'minor':
          return current.nextMinor;
        case 'patch':
          return current.nextPatch;
        default:
          throw StateError('Unknown bump type: $versionBumpType');
      }
    }();

    final currentPackageVersionTag = '${package.name}-v${package.version}';
    final nextPackageVersionTag = '${package.name}-v$nextVersion';

    print("\nAlright, all information for this release is collected.\n"
        "Let's prepare the release:");
    sleep(1);

    print(' - Updating CHANGELOG.md...');
    final changelog = package.root.file('CHANGELOG.md');
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    changelog.writeAsStringSync('''
# Changelog

## [$nextVersion](https://github.com/phntmxyz/sidekick/compare/$currentPackageVersionTag..$nextPackageVersionTag) ($date)

${nextReleaseChangelog.trim()}

${changelog.readAsStringSync().replaceFirst('# Changelog', '').trimLeft()}''');

    print(' - Bumping version...');
    await runSk([
      'bump-version',
      package.root.path,
      '--$versionBumpType',
      '--no-commit',
    ]);

    print(' - Committing changelog and version bump ...');
    final tag = '${package.name}-v$nextVersion';
    "git add -A ${package.root.path}".runInRepo;
    'git commit -m "Prepare release $tag"'.runInRepo;
    final newChangelogAndVersionBranch = _getCurrentBranch(repository.root);

    final bool lock = package == skProject.sidekickPackage;
    if (lock) {
      print(' - Locking dependencies...');
      await runSk(
        ['lock-dependencies', '--check-dart-version', package.root.path],
      );
    }

    final releaseBranch = 'release/${package.name}-v$nextVersion';
    if (lock) {
      // locked pubspec files are committed to a separate branch
      print(
        " - Create release branch '$releaseBranch' (locally) and tag ($tag)...",
      );
      'git checkout -b $releaseBranch'.runInRepo;

      print(" - Committing changes and tag commit ($tag)...");
      'git add -A ${package.root.path}'.runInRepo;
      'git commit -m "Locking dependencies"'.runInRepo;
    }

    print(" - Tagging release ($tag)...");
    'git tag $tag'.runInRepo;

    if (lock) {
      // delete release branch, it was only necessary for the commit.
      // The commit is still accessible with the tag
      'git checkout $newChangelogAndVersionBranch'.runInRepo;
      'git branch -D $releaseBranch'.runInRepo;
    }

    print(green("\nRelease preparation complete\n"));

    final publish = confirm(
      'Do you want to publish release $tag to pub.dev?',
      defaultValue: false,
    );
    if (!publish) {
      exitCode = 1;
      return;
    }

    print(' - Pushing changelog and version bump ...');
    // push main
    'git push origin $newChangelogAndVersionBranch'.runInRepo;

    print(' - Pushing tag $tag to origin...');
    'git push origin refs/tags/$tag'.start(workingDirectory: package.root.path);

    print(' - Publishing ${package.name}:$nextVersion to pub.dev...');
    'dart pub publish'.start(workingDirectory: package.root.path);
    print(
      green(
        '🎉 Success!\n'
        '${package.name}:$nextVersion has been released to pub '
        'https://pub.dev/packages/${package.name}/versions/$nextVersion',
      ),
    );
  }

  String _askForBumpType(DartPackage package) {
    print(
      green(
        'Considering the changelog above, what kind of SemVer release is this?',
      ),
    );
    return menu(
      prompt: 'Please select a release type',
      options: ['major', 'minor', 'patch'],
      defaultOption: 'minor',
      format: (option) {
        switch (option) {
          case 'major':
            return 'Major (breaking changes)';
          case 'minor':
            return 'Minor (new features) (default)';
          case 'patch':
            return 'Patch (bug fixes)';
        }
        return option;
      },
    );
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
  String _prepareNextReleaseChangelog(DartPackage package) {
    final currentPackageVersionTag = '${package.name}-v${package.version}';
    print('Auto-generating changelog for $currentPackageVersionTag...HEAD ...');
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
      ..writeAsStringSync('''
<!--
Please edit this auto-generated changelog for the next release of package:${package.name}
- [ ] Combine connected commits into meaningful items
- [ ] Remove commits that have been reverted
- [ ] Add examples of how to use the new APIs (check PRs for examples/tests)
- [ ] Highlight breaking changes
- [ ] Delete this header
-->

Full diff: https://github.com/phntmxyz/sidekick/compare/$currentPackageVersionTag...main

$initialChangelog
''');

    print('''
Created changelog file ${relative(nextReleaseChangelog.path)}.


Please follow the instructions in the auto-generated ${relative(nextReleaseChangelog.path)} header.
You can continue once you completed all steps.
''');

    final editor = Platform.environment['EDITOR'];
    if (editor == null) {
      print(
        cyan(
          'Please open ${relative(nextReleaseChangelog.path)} with the editor of your choice',
        ),
      );
    } else {
      print("Opening ${relative(nextReleaseChangelog.path)} with $editor ...");
      '$editor ${nextReleaseChangelog.path}'.start(nothrow: true);
    }

    print(
      "Waiting for all steps to be completed (and header being removed)...",
    );
    bool allStepsCompleted() {
      final text = nextReleaseChangelog.readAsStringSync();
      return text.contains('Delete this header');
    }

    while (allStepsCompleted()) {
      sleep(1);
    }

    print("Detected deletion of header.\n");

    while (!confirm(
      'Do you want to continue the release process with the changelog in ${relative(nextReleaseChangelog.path)}?',
      defaultValue: false,
    )) {}

    final nextChangelogContent = nextReleaseChangelog.readAsStringSync();
    nextReleaseChangelog.deleteSync();
    return nextChangelogContent;
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

        final message = '\n<!--\nAlso package:sidekick_core updated '
            '($oldSidekickCoreVersionTag -> $currentSidekickCoreVersionTag), '
            'please consider those changes as well.\n-->\n';
        final diffLink =
            'sidekick_core diff: https://github.com/phntmxyz/sidekick/compare/sidekick_core-v$oldSidekickCoreVersion...sidekick_core-v$currentSidekickCoreVersion\n';
        return [message, diffLink, ...newSidekickCoreCommits];
      }
    }
    return null;
  }
}

/// Whether the git repository has untracked changes in [directory]
///
/// Note that the repository may contain untracked changes in other directories
bool _gitRepoHasChangesIn(Directory directory) =>
    'git status --porcelain ${directory.path}'
        .start(
          progress: Progress.capture(),
          workingDirectory: repository.root.path,
        )
        .lines
        .isNotEmpty;

/// Returns all changes in the history from [from] (default: HEAD) to [to]
/// If [paths] is given, returns only commits which modified [paths]
///
/// The format of each line is '<commit hash> <commit title>'
Iterable<String> _getChanges({
  required String from,
  String? to = 'HEAD',
  Iterable<String> paths = const [],
}) =>
    // %H = commit hash, %b = commit title
    "git log --format='- %s %h' $from..$to -- ${paths.join(' ')}"
        .start(progress: Progress.capture())
        .lines
        .map(_prLinkToMarkdownLink);

/// Converts the last PR Link in [original] to a markdown link
///
/// E.g. '(#123)' -> '([#123](https://github.com/phntmxyz/sidekick/pull/123))'
String _prLinkToMarkdownLink(String original) {
  final prLinkRegExp = RegExp(r'\(#(\d+)\)');
  final prLink = prLinkRegExp.allMatches(original).lastOrNull;
  if (prLink == null) {
    return original;
  }
  final prNumber = prLink.group(1)!;
  return original.replaceRange(
    prLink.start,
    prLink.end,
    '([#$prNumber](https://github.com/phntmxyz/sidekick/pull/$prNumber))',
  );
}

String? _getGitUserName() =>
    'git config user.name'.start(progress: Progress.capture()).firstLine;

void _warnIfNotOnDefaultBranch(Directory directory) {
  final currentBranch = _getCurrentBranch(directory);

  const defaultBranch = 'main';

  if (defaultBranch != currentBranch) {
    final proceed = confirm(
      "\n"
      "You are on branch '$currentBranch', but releases should be made on branch $defaultBranch.\n"
      "Do you really want to continue?",
      defaultValue: false,
    );
    if (!proceed) {
      exit(1);
    } else {
      print('\n');
    }
  }
}

String _getCurrentBranch(Directory directory) {
  final path = directory.path;
  final currentBranch = 'git branch --show-current'
      .start(progress: Progress.capture(), workingDirectory: path)
      .firstLine;

  if (currentBranch == null) {
    throw "Couldn't determine current branch for git repository at $path";
  }
  return currentBranch;
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

extension on String {
  void get runInRepo => start(workingDirectory: repository.root.path);
}
