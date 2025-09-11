/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dev/packages/build_runner)
/// for more information.
library;

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'src/git_info.dart';

const _defaultOutput = 'lib/src/version.dart';

Builder buildVersion([BuilderOptions? options]) => _VersionBuilder(
  output: (options?.config['output'] as String?) ?? _defaultOutput,
  genGitInfo: options?.config['gen_git_info'] as bool? ?? false,
);

class _VersionBuilder implements Builder {
  final String output;
  final bool genGitInfo;

  _VersionBuilder({required this.output, required this.genGitInfo});

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

    final pubspec = Pubspec.parse(content, sourceUrl: assetId.uri);

    if (pubspec.version == null) {
      throw StateError('pubspec.yaml does not have a version defined.');
    }

    final gitInfoStr = await _buildGitInfoStr(Directory.current);

    await buildStep.writeAsString(buildStep.allowedOutputs.single, '''
// Generated code. Do not modify.
const packageVersion = '${pubspec.version}';${gitInfoStr.isNotEmpty ? "\n\n" : ''}$gitInfoStr
''');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    'pubspec.yaml': [output],
  };

  Future<String> _buildGitInfoStr(Directory dir) async {
    if (!genGitInfo) {
      return '';
    }

    try {
      final gitInfo = await GitInfo.fromDir(dir);
      return '''// git info
const gitBranch = '${gitInfo?.branch ?? ''}';
const gitCommitId = '${gitInfo?.commitId ?? ''}';''';
    } catch (_) {}

    return '';
  }
}
