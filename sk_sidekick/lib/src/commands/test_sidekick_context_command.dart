import 'package:sidekick_core/sidekick_core.dart';

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
    print('entryPoint: ${relative(entryPoint.path)}');
    final projectRoot = SidekickContext.projectRoot;
    print('projectRoot: ${relative(projectRoot.path)}');
  }
}
