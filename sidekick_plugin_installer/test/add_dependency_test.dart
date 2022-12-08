import 'package:pubspec/pubspec.dart'
    show PathReference, HostedReference, GitReference;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  late final Directory packageDir;
  late File pubspec;
  late DartPackage package;

  setUpAll(() {
    // it's necessary to use the same package path in every test because
    // addSelfAsDependency uses sidekickDartRuntime which is initialized only once
    // (final) with env.SIDEKICK_PACKAGE_HOME
    // if env.SIDEKICK_PACKAGE_HOME changes between tests,
    // sidekickDartRuntime breaks
    packageDir = Directory.systemTemp.createTempSync();
  });

  setUp(() {
    pubspec = packageDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: foo

environment:
  sdk: ^2.0.0
''');
    package = DartPackage.fromDirectory(packageDir)!;
    overrideSidekickDartRuntimeWithSystemDartRuntime(packageDir);
  });

  tearDown(() {
    packageDir.deleteSync(recursive: true);
  });

  group('pubspec is correctly modified when', () {
    test('adding a local dependency', () {
      final barDir = Directory.systemTemp.createTempSync();
      addTearDown(() => barDir.deleteSync(recursive: true));
      barDir.file('pubspec.yaml').writeAsStringSync('''
name: bar

environment:
  sdk: ^2.0.0
''');

      addDependency(
        package: package,
        dependency: 'bar',
        localPath: barDir.path,
      );

      final modifiedPubspec = PubSpec.fromFile(pubspec.path);
      final dependency = modifiedPubspec.dependencies['bar'];

      expect(
        dependency?.reference,
        isA<PathReference>().having((p0) => p0.path, 'path', barDir.path),
      );
    });

    test('adding a hosted dependency', () {
      addDependency(
        package: package,
        dependency: 'sidekick_core',
        versionConstraint: '^0.10.0',
      );

      final modifiedPubspec = PubSpec.fromFile(pubspec.path);
      final dependency = modifiedPubspec.dependencies['sidekick_core'];

      expect(
        dependency?.reference,
        isA<HostedReference>().having(
          (p0) => p0.versionConstraint.toString(),
          'version',
          '^0.10.0',
        ),
      );
    });

    test('adding a git dependency', () {
      addDependency(
        package: package,
        dependency: 'sidekick_core',
        gitUrl: 'https://github.com/phntmxyz/sidekick',
        gitPath: 'sidekick_core',
      );

      final modifiedPubspec = PubSpec.fromFile(pubspec.path);
      final dependency = modifiedPubspec.dependencies['sidekick_core'];

      expect(
        dependency?.reference,
        isA<GitReference>()
            .having(
              (p0) => p0.url,
              'url',
              'https://github.com/phntmxyz/sidekick',
            )
            .having(
              (p0) => p0.path,
              'path',
              'sidekick_core',
            ),
      );
    });
  });

  group('throws error when arguments are not valid because', () {
    test('gitUrl is required but is missing', () {
      expect(
        () => addDependency(
          package: package,
          dependency: 'foo',
          gitPath: 'bar',
        ),
        throwsA('git arguments were passed, but `gitUrl` was null.'),
      );
    });
    test('too many arguments are given', () {
      expect(
        () => addDependency(
          package: package,
          dependency: 'foo',
          gitPath: 'bar',
          localPath: 'baz',
        ),
        throwsA(
          'Too many arguments. Pass only one type of arguments (path/hosted/git).',
        ),
      );
    });
  });
}
