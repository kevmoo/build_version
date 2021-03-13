/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dev/packages/build_runner)
/// for more information.
library builder;

import 'dart:async';

import 'package:build/build.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

Builder buildVersion([BuilderOptions? options]) => _VersionBuilder();

class _VersionBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    final assetId = AssetId(buildStep.inputId.package, 'pubspec.yaml');

    final content = await buildStep.readAsString(assetId);

    final pubspec = Pubspec.parse(content, sourceUrl: assetId.uri);

    if (pubspec.version == null) {
      throw StateError('pubspec.yaml does not have a version defined.');
    }

    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/src/version.dart'), '''
// Generated code. Do not modify.
const packageVersion = '${pubspec.version}';
''');
  }

  @override
  final buildExtensions = const {
    r'$lib$': ['src/version.dart']
  };
}
