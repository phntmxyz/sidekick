import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:test/test.dart';

void main() {
  test('executes only migrations for the current update', () async {
    final currentVersion = Version.parse('0.4.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];

    MigrationStep trackedMigrationTo(Version version) {
      return MigrationStep.inline(
        (context) => executed.add(context.step.targetVersion),
        targetVersion: version,
        name: version.canonicalizedVersion,
      );
    }

    final migrations = [
      trackedMigrationTo(Version(0, 3, 0)),
      trackedMigrationTo(Version(0, 3, 5)),
      trackedMigrationTo(Version(0, 4, 1)),
      trackedMigrationTo(Version(0, 5, 0)),
      trackedMigrationTo(Version(0, 6, 0)),
      trackedMigrationTo(Version(0, 7, 0)),
    ];
    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
    );

    expect(executed, [
      Version(0, 4, 1),
      Version(0, 5, 0),
      Version(0, 6, 0),
    ]);
  });

  test('Skip failing migrations executes all others', () async {
    final currentVersion = Version.parse('0.2.0');
    final updateTo = Version.parse('0.6.0');

    final List<Version> executed = [];
    void doMigration(MigrationContext context) {
      executed.add(context.step.targetVersion);
    }

    final migrations = [
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep.inline(
        (_) => throw "something went wrong",
        targetVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];

    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
      onMigrationStepError: (context) => MigrationErrorHandling.skip,
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
      executed.add(context.step.targetVersion);
    }

    final migrations = [
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep.inline(
        (_) => throw "something went wrong",
        targetVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];
    try {
      await migrate(
        from: currentVersion,
        to: updateTo,
        migrations: migrations,
        onMigrationStepError: (context) => MigrationErrorHandling.abort,
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
      executed.add(context.step.targetVersion);
    }

    final migrations = [
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.3.0'),
        name: '0.3.0',
      ),
      MigrationStep.inline(
        (_) => throw "something went wrong",
        targetVersion: Version.parse('0.3.5'),
        name: '0.3.5',
      ),
      MigrationStep.inline(
        doMigration,
        targetVersion: Version.parse('0.4.1'),
        name: '0.4.1',
      ),
    ];

    int retryCount = 0;
    await migrate(
      from: currentVersion,
      to: updateTo,
      migrations: migrations,
      onMigrationStepError: (context) {
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
