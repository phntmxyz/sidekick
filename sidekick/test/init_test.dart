import 'package:sidekick/sidekick.dart';
import 'package:sidekick/src/util/dcli_ask_validators.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;
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

  test(
    '--version flag prints sidekick and sidekick_core versions',
    () async {
      final versionRegExp =
          RegExp(r"final Version version = Version.parse\('(.*)'\);");
      final sidekickCoreFile = File('../sidekick_core/lib/sidekick_core.dart');
      final sidekickCoreVersion = versionRegExp
          .firstMatch(sidekickCoreFile.readAsStringSync())!
          .group(1)!;
      final process = await cachedGlobalSidekickCli
          .run(['--version'], workingDirectory: Directory.current);
      final output = await process.stdoutStream().join('\n');
      expect(output, 'sidekick: $version\nsidekick_core: $sidekickCoreVersion');
    },
    skip: !shouldUseLocalDeps,
  );

  group('sidekick init - argument validation', () {
    test(
      'Creates projectRoot when it does not exist',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedGlobalSidekickCli.run(
          [
            'init',
            '-n',
            'dashi',
            '--projectRoot',
            tempDir.directory('foo').path,
          ],
          workingDirectory: projectRoot,
        );
        process.stderrStream().listen(printOnFailure);
        await process.shouldExit(0);
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws when cliPackageDirectory is not inside projectRoot',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync());

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedGlobalSidekickCli.run(
          [
            'init',
            '-n',
            'dashi',
            '--projectRoot',
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
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws when mainProjectPath is not inside projectRoot',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        tempDir.file('pubspec.yaml').writeAsStringSync('name: fake');

        final projectRoot =
            setupTemplateProject('test/templates/minimal_dart_package');
        final process = await cachedGlobalSidekickCli.run(
          [
            'init',
            '-n',
            'dashi',
            '--projectRoot',
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
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
          ),
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
        final process = await cachedGlobalSidekickCli.run(
          [
            'init',
            '-n',
            'dashi',
            '--projectRoot',
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
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'throws error when cli name is invalid',
      () async {
        final process = await cachedGlobalSidekickCli.run(
          ['init', '-n', '-42invalidName'],
          workingDirectory: Directory.systemTemp.createTempSync(),
        );

        await process.shouldExit(255);
        expect(
          await process.stderr.rest.contains(invalidCliNameErrorMessage),
          isTrue,
        );
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
          ),
        );
      },
    );

    test(
      'throws error when cli name collides with an system executable',
      () async {
        final process = await cachedGlobalSidekickCli.run(
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
        expect(
          process.stdout,
          isNot(
            contains('Successfully generated dashi_sidekick 🎉'),
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
        final process = await cachedGlobalSidekickCli.run(
          ['init', '-n', 'dashi'],
          workingDirectory: projectRoot,
        );
        final stdout = await process.stdoutStream().join('\n');

        expect(
          stdout,
          contains('Successfully generated dashi_sidekick 🎉'),
        );
        await process.shouldExit(0);
        final entrypoint = File("${projectRoot.path}/dashi");
        expect(entrypoint.existsSync(), isTrue);

        overrideSidekickCoreWithLocalPath(
          projectRoot.directory('dashi_sidekick'),
        );

        final runFunctionFile = projectRoot
            .file('dashi_sidekick/lib/dashi_sidekick.dart')
            .readAsStringSync();
        expect(runFunctionFile, contains("mainProjectPath: '.',"));
        expect(runFunctionFile, isNot(contains('dartSdkPath:')));
        expect(runFunctionFile, contains('flutterSdkPath:'));

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
        final entrypointDir = cliDir.directory('foo/custom/projectRoot')
          ..createSync(recursive: true);
        final process = await cachedGlobalSidekickCli.run(
          [
            'init',
            '-n',
            'dashi',
            '--projectRoot',
            entrypointDir.path,
            '--cliPackageDirectory',
            entrypointDir.directory('my/custom/cliDir').path,
            cliDir.absolute.path,
          ],
          workingDirectory: Directory.current,
        );
        final stdout = await process.stdoutStream().join('\n');

        expect(
          stdout,
          contains('Successfully generated dashi_sidekick 🎉'),
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

        final runFunctionFile =
            cliPackage.file('lib/dashi_sidekick.dart').readAsStringSync();
        expect(runFunctionFile, isNot(contains('mainProjectPath:')));
        expect(runFunctionFile, contains('dartSdkPath:'));
        expect(runFunctionFile, isNot(contains('flutterSdkPath:')));

        // CLI has working dart command and no flutter command
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
        final process = await cachedGlobalSidekickCli.run(
          ['init', '-n', 'dashi'],
          workingDirectory: project,
        );

        await expectLater(
          process.stdout,
          emitsThrough(contains('Generating dashi_sidekick')),
        );
        final stdout = await process.stdoutStream().join('\n');

        expect(
          stdout,
          contains('Successfully generated dashi_sidekick 🎉'),
        );

        printOnFailure(await process.stdoutStream().join('\n'));
        printOnFailure(await process.stderrStream().join('\n'));
        await process.shouldExit(0);

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
        final runFunctionFile = project
            .file('packages/dashi_sidekick/lib/dashi_sidekick.dart')
            .readAsStringSync();
        expect(runFunctionFile, contains("mainProjectPath: '.',"));

        final packages = findAllPackages(project);
        final expectedPackages = {
          DartPackage(project, 'root_with_packages'),
          DartPackage(project.directory('packages/package_a'), 'package_a'),
          DartPackage(project.directory('packages/package_b'), 'package_b'),
          DartPackage(
            project.directory('packages/dashi_sidekick'),
            'dashi_sidekick',
          ),
        };
        expect(packages.toSet(), expectedPackages);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  test(
    'Installs optional flutterw_sidekick_plugin',
    () async {
      final projectRoot =
          setupTemplateProject('test/templates/minimal_flutter_package');
      final process = await cachedGlobalSidekickCli.run(
        [
          'init',
          '-n',
          'dashi',
          '--projectRoot',
          '.',
        ],
        workingDirectory: projectRoot,
        environment: {
          'SIDEKICK_INIT_APPROVE_FLUTTERW_INSTALL': 'true',
        },
      );
      process.stderrStream().listen(printOnFailure);
      final output = await process.stdoutStream().join('\n');
      expect(
        output,
        allOf([
          contains('flutterw_sidekick_plugin'),
          contains('Sidekick detected 1 Flutter packages in your project.'),
          contains(
            'Do you want pin the Flutter version of this project with flutterw?',
          ),
        ]),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: 'Enable when sidekick_core 1.0 has been release with SidekickContext',
  );
}
