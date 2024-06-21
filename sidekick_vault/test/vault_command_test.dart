import 'package:dcli_core/dcli_core.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner runner;
  late SidekickVault vault;
  setUp(() async {
    await insideFakeProjectWithSidekick((projectRoot) async {
      final tempVault = Directory.systemTemp.createTempSync();
      await Directory('test/vault').copyRecursively(tempVault);
      vault = SidekickVault(
        location: tempVault,
        environmentVariableName: 'DASH_VAULT_PASSPHRASE',
      );
      runner = initializeSidekick();
      runner.addCommand(VaultCommand(vault: vault));
    });
  });

  test('encrypt/decrypt a file', () async {
    final secretFile = File('test/vault/secret.txt.gpg');
    final tempDir = Directory.systemTemp.createTempSync();

    final clearTextFile = tempDir.file('cleartext.txt')..writeAsStringSync('Dash is cool');
    addTearDown(() {
      if (secretFile.existsSync()) {
        secretFile.deleteSync();
      }
      tempDir.deleteSync(recursive: true);
    });
    final decryptedFile = tempDir.file('decrypted.txt');
    await withEnvironment(
      () async {
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);

        await runner.run([
          'vault',
          'decrypt',
          '--passphrase',
          'dartlang',
          '--output',
          decryptedFile.absolute.path,
          'secret.txt.gpg',
        ]);
      },
      environment: {
        'DASH_VAULT_PASSPHRASE': 'asdfasdf',
        'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
      },
    );
    expect(decryptedFile.readAsStringSync(), 'Dash is cool');
  });

  group('decrypt args validation', () {
    test('throws without file', () {
      expect(
        () => runner.run(['vault', 'decrypt']),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Missing file'),
              )
              .having(
                (it) => it,
                'example',
                contains('dash vault decrypt secret.txt.gpg'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'decrypt', 'unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist in vault'),
          ),
        ),
      );
    });
    test('throws for multiple files', () {
      expect(
        () => runner.run([
          'vault',
          'decrypt',
          'test/vault/encrypted.txt.gpg',
          'test/vault/encrypted.txt.gpg',
        ]),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Enter one file only'),
              )
              .having(
                (it) => it,
                'example',
                contains('dash vault decrypt secret.txt.gpg'),
              ),
        ),
      );
    });
  });

  group('encrypt args validation', () {
    test('throws without file', () {
      expect(
        () => runner.run(['vault', 'encrypt']),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Missing file'),
              )
              .having(
                (it) => it,
                'example',
                contains('dash vault encrypt secret.txt'),
              ),
        ),
      );
    });
    test('throws for non-files (absolute path)', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'encrypt', 'unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist in'),
          ),
        ),
      );
    });
    test('throws for non-files (relative path)', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'encrypt', '/root/unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist'),
          ),
        ),
      );
    });
    test('throws for multiple files', () {
      expect(
        () => runner.run([
          'vault',
          'encrypt',
          'test/vault/decrypted.txt',
          'test/vault/decrypted.txt',
        ]),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Enter one file only'),
              )
              .having(
                (it) => it,
                'example',
                contains('dash vault encrypt secret.txt.gpg'),
              ),
        ),
      );
    });
  });

  test('Change password', () async {
    await runner.run([
      'vault',
      'change-password',
      '--old',
      'asdfasdf',
      '--new',
      'newpw',
    ]);

    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });
    final decryptedFile = tempDir.file('decrypted.txt');
    await runner.run([
      'vault',
      'decrypt',
      '--passphrase',
      'newpw',
      '--output',
      decryptedFile.absolute.path,
      'encrypted.txt.gpg',
    ]);

    expect(decryptedFile.readAsStringSync(), '42');
  });

  test('encrypt overwrites existing files', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final clearTextFile = tempDir.file('cleartext.txt')..writeAsStringSync('Dash is cool');
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    await withEnvironment(
      () async {
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);

        // writing it a second time works just fine
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);
      },
      environment: {
        'DASH_VAULT_PASSPHRASE': 'asdfasdf',
        'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
      },
    );
  });
}

/// Fakes a sidekick package by writing required files and environment variables
///
/// Optional Parameters:
/// - [overrideSidekickCoreWithLocalDependency] whether to add a dependency
///   override to use the local sidekick_core dependency
/// - [sidekickCoreVersion] the dependency of sidekick_core in the pubspec.
///   Only written to pubspec if value is not null.
/// - [lockedSidekickCoreVersion] the used version in pubspec.lock
/// - [sidekickCliVersion] sidekick: cli_version: <sidekickCliVersion> in the
///   pubspec. Only written to pubspec if value is not null.
R insideFakeProjectWithSidekick<R>(
  R Function(Directory projectRoot) callback, {
  bool overrideSidekickCoreWithLocalDependency = false,
  String? sidekickCoreVersion,
  String? lockedSidekickCoreVersion,
  String? sidekickCliVersion,
  bool insideGitRepo = false,
}) {
  final tempDir = Directory.systemTemp.createTempSync();
  Directory projectRoot = tempDir;
  if (insideGitRepo) {
    'git init -q ${tempDir.path}'.run;
    projectRoot = tempDir.directory('myProject')..createSync();
  }

  projectRoot.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: main_project

environment:
  sdk: '>=2.14.0 <3.0.0'
''');
  projectRoot.file('dash').createSync();

  final fakeSidekickDir = projectRoot.directory('packages/dash')..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash

environment:
  sdk: '>=2.14.0 <3.0.0'
  
${sidekickCoreVersion == null && !overrideSidekickCoreWithLocalDependency ? '' : '''
dependencies:
  sidekick_core: ${sidekickCoreVersion ?? '0.0.0'}
'''}

${sidekickCliVersion == null ? '' : '''
sidekick:
  cli_version: $sidekickCliVersion
'''}
''');
  fakeSidekickDir.file('pubspec.lock')
    ..createSync()
    ..writeAsStringSync('''
packages:
  sidekick_core:
    dependency: "direct main"
    source: hosted
    description:
      name: sidekick_core
      url: "https://pub.dev"
    version: "${lockedSidekickCoreVersion ?? '0.0.0'}"
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = projectRoot.absolute.path;
  if (!env.exists('SIDEKICK_ENABLE_UPDATE_CHECK')) {
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'false';
  }

  addTearDown(() {
    projectRoot.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = null;
  });

  Directory cwd = projectRoot;
  return IOOverrides.runZoned<R>(
    () => callback(projectRoot),
    getCurrentDirectory: () => cwd,
    setCurrentDirectory: (dir) => cwd = Directory(dir),
  );
}
