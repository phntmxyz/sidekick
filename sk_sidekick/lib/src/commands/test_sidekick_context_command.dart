import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/sk_sidekick.dart';

class TestSidekickContextCommand extends Command {
  @override
  String get name => 'test-sidekick-context';

  @override
  String get description => 'Tests the sidekick context';

  @override
  Future<void> run() async {
    final sidekickPackage = SidekickContext.sidekickPackage;
    print('sidekickPackage: ${relative(sidekickPackage.root.path)}');
    final entryPoint = SidekickContext.entryPoint;
    print('entryPoint: ${relative(entryPoint.file.path)}');
    final repository = SidekickContext.repository;
    print('repository: ${relative(repository.root.path)}');
  }
}
