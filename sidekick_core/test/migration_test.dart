import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:test/test.dart';

void main() {
  test('executes only migrations for the current update', () async {
    final currentVersion = Version.parse('0.4.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];

    void doMigration(MigrationContext context) {
      executed.add(context.step.oldVersion);
    }

    final migrations = [
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.5.0'),
        name: '0.5.0',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.6.0'),
        name: '0.6.0',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.7.0'),
        name: '0.7.0',
      ),
    ];

    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
    );

    expect(executed, [
      Version.parse('0.4.1'),
      Version.parse('0.5.0'),
    ]);
  });

  test('Skip failing migrations executes all others', () async {
    final currentVersion = Version.parse('0.2.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];
    void doMigration(MigrationContext context) {
      executed.add(context.step.oldVersion);
    }

    final migrations = [
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep(
        (_) => throw "something went wrong",
        oldVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];

    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
      onMigrationError: (context) => MigrationErrorHandling.skip,
    );

    expect(executed, isNot(contains(Version.parse('0.3.5'))));

    expect(executed, [
      Version.parse('0.3.0'),
      Version.parse('0.4.1'),
    ]);
  });

  test('Abort failing migration stops execution of all others', () async {
    final currentVersion = Version.parse('0.2.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];
    void doMigration(MigrationContext context) {
      executed.add(context.step.oldVersion);
    }

    final migrations = [
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep(
        (_) => throw "something went wrong",
        oldVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];
    try {
      await migrate(
        from: currentVersion,
        to: updateTo,
        migrations: migrations,
        onMigrationError: (context) => MigrationErrorHandling.abort,
      );
      fail('should have thrown');
    } catch (e) {
      expect(e, "something went wrong");
    }

    expect(executed, [
      Version.parse('0.3.0'),
    ]);
  });

  test('Retry tries again and again and again...', () async {
    final currentVersion = Version.parse('0.2.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];
    void doMigration(MigrationContext context) {
      executed.add(context.step.oldVersion);
    }

    final migrations = [
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep(
        (_) => throw "something went wrong",
        oldVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep(
        doMigration,
        oldVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];

    int retryCount = 0;
    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
      onMigrationError: (context) {
        retryCount++;
        if (retryCount < 10) {
          return MigrationErrorHandling.retry;
        }
        return MigrationErrorHandling.skip;
      },
    );

    expect(retryCount, 10);
    expect(executed, isNot(contains(Version.parse('0.3.5'))));

    expect(executed, [
      Version.parse('0.3.0'),
      Version.parse('0.4.1'),
    ]);
  });
}
