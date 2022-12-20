import 'package:sidekick/sidekick.dart';
import 'package:sidekick/src/util/dcli_ask_validators.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;
import 'package:sidekick_core/sidekick_core.dart' as core;
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';

void main() {
  test('version is correct', () {
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue);

    final yaml = pubspec.readAsStringSync();

    final packageName = RegExp(r'name:\s*(.*)').firstMatch(yaml)!.group(1)!;
    final packageVersion =
        Version.parse(RegExp(r'version:\s*(.*)').firstMatch(yaml)!.group(1)!);

    expect(packageName, 'sidekick');
    expect(packageVersion, version);
  });

  test('--version flag prints sidekick and sidekick_core versions', () async {
    final process = await cachedSidekickExecutable
        .run(['--version'], workingDirectory: Directory.current);
    final output = await process.stdoutStream().join('\n');
    expect(output, 'sidekick: $version\nsidekick_core: ${core.version}');
  });

  group('sidekick init - argument validation', () {
    test(
      'throws when entrypointDirectory does not exist',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync());

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--entrypointDirectory',
            tempDir.directory('foo').path,
          ],
          workingDirectory: projectRoot,
        );
        process.stderrStream().listen(printOnFailure);
        await process.shouldExit(255);
        expect(
          await process.stderrStream().contains(
                'Entrypoint directory ${tempDir.directory('foo').path} does not exist',
              ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws when cliPackageDirectory is not inside entrypointDirectory',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync());

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--entrypointDirectory',
            projectRoot.path,
            '--cliPackageDirectory',
            tempDir.path
          ],
          workingDirectory: projectRoot,
        );
        process.stderrStream().listen(printOnFailure);
        await process.shouldExit(255);
        expect(
          await process.stderrStream().contains(
                'CLI package directory ${tempDir.path} is not within or equal to ${projectRoot.path}',
              ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws when mainProjectPath is not inside entrypointDirectory',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        tempDir.file('pubspec.yaml').writeAsStringSync('name: fake');

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--entrypointDirectory',
            projectRoot.path,
            '--mainProjectPath',
            tempDir.path
          ],
          workingDirectory: projectRoot,
        );
        process.stderrStream().listen(printOnFailure);
        await process.shouldExit(255);
        expect(
          await process.stderrStream().contains(
                'Main project ${tempDir.path} is not within or equal to ${projectRoot.path}',
              ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws when mainProjectPath is given but it does not contain a DartPackage',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync());

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--entrypointDirectory',
            projectRoot.path,
            '--mainProjectPath',
            tempDir.path
          ],
          workingDirectory: projectRoot,
        );
        process.stderrStream().listen(printOnFailure);
        await process.shouldExit(255);
        expect(
          await process.stderrStream().contains(
                'mainProjectPath was given, but no DartPackage could be found at the given path ${tempDir.path}',
              ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws error when cli name is invalid',
      () async {
        final process = await cachedSidekickExecutable.run(
          ['init', '-n', '-42invalidName'],
          workingDirectory: Directory.systemTemp.createTempSync(),
        );

        await process.shouldExit(255);
        expect(
          await process.stderr.rest.contains(invalidCliNameErrorMessage),
          isTrue,
        );
      },
    );

    test(
      'throws error when cli name collides with an system executable',
      () async {
        final process = await cachedSidekickExecutable.run(
          ['init', '-n', 'rm'],
          workingDirectory: Directory.systemTemp.createTempSync(),
        );

        await process.shouldExit(255);
        final stderrText = await process.stderr.rest.toList();
        expect(
          stderrText,
          contains(
            'The CLI name rm is already taken by an executable on your system see [/bin/rm]',
          ),
        );
      },
    );
  });

  // TODO do we really need groups for all of these layouts? we had them because in the past we had some ProjectStructureDetector
  group('sidekick init - simple layout', () {
    test(
      'after sidekick init in flutter package, CLI has working dart and flutter commands',
      () async {
        final projectRoot =
            setupTemplateProject('test/templates/minimal_flutter_package');
        final process = await cachedSidekickExecutable.run(
          ['init', '-n', 'dashi'],
          workingDirectory: projectRoot,
        );
        await process.shouldExit(0);
        final entrypoint = File("${projectRoot.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        overrideSidekickCoreWithLocalPath(
          projectRoot.directory('packages/dashi_sidekick'),
        );

        expect(
          projectRoot
              .file('packages/dashi_sidekick/lib/dashi_sidekick.dart')
              .readAsStringSync(),
          isNot(contains('dartSdkPath:')),
        );

        expect(
          projectRoot
              .file('packages/dashi_sidekick/lib/dashi_sidekick.dart')
              .readAsStringSync(),
          contains('flutterSdkPath:'),
        );

        // fake flutter installation because we don't have flutter installed on CI
        final pathWithFakeFlutterSdk = [
          fakeFlutterSdk().directory('bin').path,
          ...PATH
        ].join(env.delimiterForPATH);

        final dartDashProcess = await TestProcess.start(
          entrypoint.path,
          ['dart'],
          workingDirectory: projectRoot.path,
          environment: {'PATH': pathWithFakeFlutterSdk},
        );
        printOnFailure(await dartDashProcess.stdoutStream().join('\n'));
        printOnFailure(await dartDashProcess.stderrStream().join('\n'));
        dartDashProcess.shouldExit(0);

        final flutterDashProcess = await TestProcess.start(
          entrypoint.path,
          ['flutter'],
          workingDirectory: projectRoot.path,
          environment: {'PATH': pathWithFakeFlutterSdk},
        );
        printOnFailure(await flutterDashProcess.stdoutStream().join('\n'));
        printOnFailure(await flutterDashProcess.stderrStream().join('\n'));
        flutterDashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'entrypoint & cli package location are modifiable, target can be given as absolute path, CLI has working dart command and no flutter command',
      () async {
        final cliDir = Directory.systemTemp.createTempSync();
        addTearDown(() => cliDir.deleteSync(recursive: true));
        final entrypointDir = cliDir.directory('foo/custom/entrypointDirectory')
          ..createSync(recursive: true);
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--entrypointDirectory',
            entrypointDir.path,
            '--cliPackageDirectory',
            entrypointDir.directory('my/custom/cliDir').path,
            cliDir.absolute.path,
          ],
          workingDirectory: Directory.current,
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);
        final entrypoint = entrypointDir.file('dashi');
        expect(entrypoint.existsSync(), isTrue);
        final cliPackage =
            entrypointDir.directory('my/custom/cliDir/dashi_sidekick');
        expect(cliPackage.existsSync(), isTrue);

        overrideSidekickCoreWithLocalPath(cliPackage);

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: cliDir.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);

        // CLI has working dart command and no flutter command
        expect(
          cliPackage.file('lib/dashi_sidekick.dart').readAsStringSync(),
          contains('dartSdkPath:'),
        );

        expect(
          cliPackage.file('lib/dashi_sidekick.dart').readAsStringSync(),
          isNot(contains('flutterSdkPath:')),
        );

        final dartDashProcess = await TestProcess.start(
          entrypoint.path,
          ['dart'],
          workingDirectory: cliDir.path,
        );
        printOnFailure(await dartDashProcess.stdoutStream().join('\n'));
        printOnFailure(await dartDashProcess.stderrStream().join('\n'));
        dartDashProcess.shouldExit(0);

        final flutterDashProcess = await TestProcess.start(
          entrypoint.path,
          ['flutter'],
          workingDirectory: cliDir.path,
        );
        printOnFailure(await flutterDashProcess.stdoutStream().join('\n'));
        printOnFailure(await flutterDashProcess.stderrStream().join('\n'));
        flutterDashProcess.shouldExit(64);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('sidekick init - packages layout', () {
    test(
      'init generates sidekick package + entrypoint which executes fine',
      () async {
        final project =
            setupTemplateProject('test/templates/root_with_packages');
        final process = await cachedSidekickExecutable.run(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dashi_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint executes fine
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        overrideSidekickCoreWithLocalPath(
          project.directory('packages/dashi_sidekick'),
        );
        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        dashProcess.stdoutStream().listen(printOnFailure);
        dashProcess.stderrStream().listen(printOnFailure);
        dashProcess.shouldExit(0);

        // root is mainProjectPath
        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          isNot(contains("mainProjectPath: 'packages/dashi_sidekick'")),
        );

        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        // The project itself is a DartPackage
        expect(
          projectFile.readAsStringSync(),
          contains('class DashiProject extends DartPackage'),
        );

        // contains references to all packages of template
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('sidekick init - multi package layout', () {
    test(
      'init generates sidekick package + entrypoint',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await cachedSidekickExecutable.run(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough('Generating dashi_sidekick'),
        );
        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        // no mainProjectPath defined, nothing is set
        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          isNot(contains('mainProjectPath')),
        );

        // contains references to all packages of template
        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with mainProject',
      () async {
        final project = setupTemplateProject('test/templates/multi_package');
        final process = await cachedSidekickExecutable.run(
          [
            'init',
            '-n',
            'dashi',
            '--mainProjectPath',
            project.directory('packages/package_a').path,
            project.path
          ],
          workingDirectory: project.parent,
        );
        await process.shouldExit(0);

        // check git is initialized
        final git = Directory("${project.path}/.git");
        expect(git.existsSync(), isTrue);

        // check entrypoint is executable
        final entrypoint = File("${project.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);
        expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');

        final runFunctionFile = File(
          "${project.path}/packages/dashi_sidekick/lib/dashi_sidekick.dart",
        );
        expect(
          runFunctionFile.readAsStringSync(),
          contains("mainProjectPath: 'packages/package_a'"),
        );

        final projectFile = File(
          "${project.path}/packages/dashi_sidekick/lib/src/dashi_project.dart",
        );
        expect(
          projectFile.readAsStringSync(),
          allOf(
            contains('packages/package_a'),
            contains('packages/package_b'),
          ),
        );

        overrideSidekickCoreWithLocalPath(
          project.directory('packages/dashi_sidekick'),
        );

        final dashProcess = await TestProcess.start(
          entrypoint.path,
          [],
          workingDirectory: project.path,
        );
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
