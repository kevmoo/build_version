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
const String _fieldName = 'field_name';
const String _targetPath = 'target_path';

class _VersionBuilder implements Builder {
  _VersionBuilder([BuilderOptions options])
      : fieldName = options != null && options.config.containsKey(_fieldName)
            ? options.config[_fieldName].toString()
            : 'packageVersion',
        targetPath = options != null && options.config.containsKey(_targetPath)
            ? options.config[_targetPath].toString()
            : 'src/version.dart';

  final String fieldName;
  final String targetPath;

  @override
  Future build(BuildStep buildStep) async {
    var assetId = AssetId(buildStep.inputId.package, 'pubspec.yaml');

    var content = await buildStep.readAsString(assetId);

    var pubspec = Pubspec.parse(content, sourceUrl: assetId.uri);

    if (pubspec.version == null) {
      throw StateError('pubspec.yaml does not have a version defined.');
    }

    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/$targetPath'), '''
/// Generated code. Do not modify.
const String $fieldName = '${pubspec.version}';
''');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': [targetPath]
      };
}
