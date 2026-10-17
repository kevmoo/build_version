/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dev/packages/build_runner)
/// for more information.
library;

import 'dart:async';

import 'package:build/build.dart';

import 'src/version_generator.dart';

Builder buildVersion([BuilderOptions? options]) =>
    _VersionBuilder((options?.config['output'] as String?) ?? defaultOutput);

class _VersionBuilder implements Builder {
  final String output;

  _VersionBuilder(this.output);

  @override
  Future<void> build(BuildStep buildStep) async {
    final assetId = AssetId(buildStep.inputId.package, 'pubspec.yaml');

    if (assetId != buildStep.inputId) {
      // Skip nested packages!
      // Should be able to use `^pubspec.yaml` – but it no work
      // See https://github.com/dart-lang/build/issues/3286
      return;
    }

    final content = await buildStep.readAsString(assetId);
    final outputContent = generateVersionContent(
      content,
      sourceUrl: assetId.uri,
    );
    if (outputContent == null) {
      throw StateError(missingVersionMessage);
    }

    await buildStep.writeAsString(
      buildStep.allowedOutputs.single,
      outputContent,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    'pubspec.yaml': [output],
  };
}
