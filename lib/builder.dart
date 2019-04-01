/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dartlang.org/packages/build_runner)
/// for more information.
library builder;

import 'dart:async';

import 'package:build/build.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

Builder buildVersion([BuilderOptions options]) => _VersionBuilder(options);

// The top level keys supported for the `options` config for the [_VersionBuilder].
const _fieldName = 'field_name';
const _targetPath = 'target_path';

class _VersionBuilder implements Builder {
  _VersionBuilder([BuilderOptions options])
      : fieldName = _field(options, _fieldName, 'packageVersion'),
        targetPath = _field(options, _targetPath, 'src/version.dart');

  static String _field(
          BuilderOptions options, String name, String defaultValue) =>
      options != null && options.config.containsKey(name)
          ? options.config[name] as String
          : defaultValue;

  final String fieldName;
  final String targetPath;

  @override
  Future build(BuildStep buildStep) async {
    final assetId = AssetId(buildStep.inputId.package, 'pubspec.yaml');

    final content = await buildStep.readAsString(assetId);

    final pubspec = Pubspec.parse(content, sourceUrl: assetId.uri);

    if (pubspec.version == null) {
      throw StateError('pubspec.yaml does not have a version defined.');
    }

    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/$targetPath'), '''
// Generated code. Do not modify.
const $fieldName = '${pubspec.version}';
''');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': [targetPath]
      };
}
