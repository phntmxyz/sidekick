import 'package:dcli/dcli.dart' as dcli;
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/sk_sidekick.dart';
import 'package:sk_sidekick/src/commands/bump_version_command.dart';
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
    print("Initializing package release routine");

    // disable update check
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'false';
    // get all tags from origin for correct divs
    'git fetch -t'.run;

    print('Hey ${_getGitUserName() ?? 'developer'}, ');
    sleep(400, interval: Interval.milliseconds);
    print('let ship a new version to our users!');
    sleep(2);
    print('');

    DartPackage? package = () {
      try {
        return DartPackage.fromArgResults(argResults!);
      } catch (e) {
        return null;
      }
    }();

    if (package == null) {
      print(green('Which package do you want to release?'));
      package = dcli.menu(
        'Select package',
        options: [
          skProject.sidekickPackage,
          skProject.sidekickCorePackage,
          skProject.sidekickPluginInstallerPackage,
          skProject.sidekickVaultPackage,
        ],
        format: (p) => p?.name ?? 'None',
      );
    } else {
      print('Do you want to release a new version for '
          '${green('package:${package.name}')}?');
      final proceed = confirm('Proceed?', defaultValue: false);
      if (!proceed) {
        exitCode = 1;
        return;
      } else {
        print(' ');
      }
    }
    if (package == null) throw StateError('no package selected');

    sleep(400, interval: Interval.milliseconds);
    print('Starting release workflow for package:${package.name}.');
    sleep(400, interval: Interval.milliseconds);
    print(' ');
    await _releasePackage(package);
  }

  Future<void> _releasePackage(DartPackage package) async {
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

    final currentVersion = Version.parse(package.version);
    final versionBumpType = _askForBumpType(package, currentVersion);
    final Version nextVersion = () {
      switch (versionBumpType) {
        case 'major':
          final next = currentVersion.nextMajor;
          final preview = _askForPreviewVersion();
          if (preview) {
            return next.copyWith(preRelease: 'preview.1');
          }
          return next;
        case 'minor':
          return currentVersion.nextMinor;
        case 'patch':
          return currentVersion.nextPatch;
        case 'stable':
          return currentVersion.nextStable;
        case 'preview':
          if (currentVersion.preRelease case ['preview', final int n]) {
            return currentVersion.copyWith(preRelease: 'preview.${n + 1}');
          }
          throw 'Unknown pre-release format of $currentVersion, '
              'expected: X.Y.Z-preview.<number>';
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
      '--exact=$nextVersion',
      '--no-commit',
    ]);
    if (package == skProject.sidekickCorePackage) {
      // update sidekick-core in sk_sidekick
      final runtime = SidekickDartRuntime(skProject.skSidekickPackage.root);
      runtime.dart(
        ['pub', 'get'],
        workingDirectory: skProject.skSidekickPackage.root,
      );
    } else {
      print('$package != ${skProject.sidekickCorePackage}');
    }

    print(' - Committing changelog and version bump ...');
    final tag = '${package.name}-v$nextVersion';
    "git add -A ${package.root.path}".runInRepo;
    "git add -A ${skProject.skSidekickPackage.root.path}/pubspec.lock"
        .runInRepo;
    'git commit -m "Prepare release $tag"'.runInRepo;
    final newChangelogAndVersionBranch =
        _getCurrentBranch(SidekickContext.repository!);

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
      'git checkout $tag'.runInRepo;
      'git branch -D $releaseBranch'.runInRepo;
    }

    print(green("\nRelease preparation complete\n"));

    print(
      "Next step: Publishing $tag to pub.dev (take a 10s break before you continue)",
    );
    sleep(10);
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
    'dart pub publish'.start(
      workingDirectory: package.root.path,
      terminal: true,
    );

    print(
      green(
        '🎉 Success!\n'
        '${package.name}:$nextVersion has been released to pub '
        'https://pub.dev/packages/${package.name}/versions/$nextVersion',
      ),
    );

    print(' - Publishing release $tag on GitHub...');

    while (!isProgramInstalled('gh')) {
      confirm(
        yellow(
          'Please install the gh cli (GitHub CLI, `brew install gh`) and hit enter to continue',
        ),
        defaultValue: false,
      );
    }

    dcli.startFromArgs(
      'gh',
      ['release', 'create', tag, '--notes', '"$nextReleaseChangelog"'],
      terminal: true,
      workingDirectory: package.root.path,
      nothrow: true,
    );
  }

  String _askForBumpType(DartPackage package, Version current) {
    print(
      green(
        'Considering the changelog above, what kind of SemVer release is this?',
      ),
    );

    if (current.isPreview) {
      return menu(
        'Please select a release type',
        options: [
          'preview',
          'stable',
        ],
        defaultOption: 'preview',
        format: (option) {
          switch (option) {
            case 'preview':
              return 'Next Preview ${current.nextPreview}';
            case 'stable':
              return 'Next Stable ${current.nextStable}';
          }
          return option;
        },
      );
    } else {
      return menu(
        'Please select a release type',
        options: [
          'major',
          'minor',
          'patch',
        ],
        defaultOption: 'minor',
        format: (option) {
          switch (option) {
            case 'major':
              return 'Major ${current.nextMajor} (breaking changes)';
            case 'minor':
              return 'Minor ${current.nextMinor} (new features) (default)';
            case 'patch':
              return 'Patch ${current.nextPatch} (bug fixes)';
          }
          return option;
        },
      );
    }
  }

  bool _askForPreviewVersion() {
    print('');
    print(green('Should this version be published as preview?'));
    return confirm('Preview?', defaultValue: false);
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
      return "No commits found since last release";
    }
    sleep(1);
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

    sleep(1);
    print('''
Created changelog file ${relative(nextReleaseChangelog.path)}.


Please follow the instructions in the auto-generated ${relative(nextReleaseChangelog.path)} header.
You can continue once you completed all steps.
''');
    sleep(1);

    final editor = Platform.environment['EDITOR'];
    if (editor == null) {
      print(
        cyan(
          'Please open ${relative(nextReleaseChangelog.path)} with the editor of your choice',
        ),
      );
    } else {
      print("Opening ${relative(nextReleaseChangelog.path)} with $editor ...");
      sleep(300, interval: Interval.milliseconds);
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
    final constraint =
        (ps['dependencies'] as YamlMap)['sidekick_core'] as String?;
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
          workingDirectory: SidekickContext.repository!.path,
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
}) {
  String resolveToHash(String ref) {
    if (ref == 'HEAD') return ref;
    final result = 'git rev-parse $ref'.start(progress: Progress.capture());
    final hash = result.firstLine;
    if (hash == null || hash.isEmpty) {
      throw 'Could not resolve git ref: $ref';
    }
    return hash;
  }

  final fromHash = resolveToHash(from);
  final toHash = to == null ? 'HEAD' : resolveToHash(to);
  final logCmd = [
    'git log',
    '--format="- %s https://github.com/phntmxyz/sidekick/commit/%H"',
    '$fromHash..$toHash',
    if (paths.isNotEmpty) '-- ${paths.join(' ')}',
  ].join(' ');
  return logCmd
      .start(progress: Progress.capture())
      .lines
      .map((l) => l.replaceAll('"', ''))
      .map(_prLinkToMarkdownLink);
}

/// Converts the last PR Link in [original] to a markdown link
///
/// E.g. '(#123)' -> '[#123](https://github.com/phntmxyz/sidekick/pull/123)'
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
    '[#$prNumber](https://github.com/phntmxyz/sidekick/pull/$prNumber)',
  );
}

String? _getGitUserName() =>
    'git config user.name'.start(progress: Progress.capture()).firstLine;

void _warnIfNotOnDefaultBranch(Directory directory) {
  final currentBranch = _getCurrentBranch(directory);

  const defaultBranches = ['main', 'main-1.X', 'main-2.X', 'main-3.X'];

  if (!defaultBranches.contains(currentBranch)) {
    final proceed = confirm(
      "\n"
      "You are on branch '$currentBranch', but releases should be made only on branches $defaultBranches.\n"
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

extension on Version {
  Version get nextPreview {
    if (preRelease case ['preview', final int n]) {
      return copyWith(preRelease: 'preview.${n + 1}');
    }
    return nextBreaking.copyWith(preRelease: 'preview.1');
  }

  Version get nextStable {
    if (preRelease case ['preview', final int _]) {
      return copyWith(preRelease: null, build: null);
    }
    return nextMinor;
  }

  bool get isPreview {
    if (preRelease case ['preview', final int _]) {
      return true;
    }
    return false;
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
  void get runInRepo {
    assert(
      SidekickContext.repository != null,
      'Release command must be run in a repository',
    );
    start(workingDirectory: SidekickContext.repository!.path);
  }
}
