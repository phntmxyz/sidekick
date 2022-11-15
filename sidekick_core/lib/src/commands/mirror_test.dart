import 'dart:mirrors';
import 'package:sidekick_core/src/template/sidekick_package.template.dart';

void main() {
  final x = currentMirrorSystem();

  final templateLibrary = currentMirrorSystem().libraries[Uri.parse(
      'package:sidekick_core/src/template/sidekick_package.template.dart')]!;


  final c = templateLibrary.declarations[#SidekickTemplate]! as ClassMirror;

  print(c.declarations);

  final i = c.newInstance(Symbol.empty, []);

  print(i);

  print(i.invoke(#foo, []));
}
