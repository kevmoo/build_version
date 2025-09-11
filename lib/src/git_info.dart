import 'dart:io';

/// Information about the current Git repository.
class GitInfo {
  final String branch;
  final String commitId;

  GitInfo({required this.branch, required this.commitId});

  /// try to get git info from the target directory
  static Future<GitInfo?> fromDir(Directory dir) async {
    // check if it is a Git repo
    final gitDir = Directory('${dir.path}/.git');
    if (!gitDir.existsSync()) {
      return null;
    }

    // get branch name
    final branchResult = await Process.run('git', [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ]);
    if (branchResult.exitCode != 0) {
      return null;
    }
    final branch = (branchResult.stdout as String).trim();

    // get HEAD commit ID of current branch
    final commitResult = await Process.run('git', ['rev-parse', 'HEAD']);
    if (commitResult.exitCode != 0) {
      return null;
    }
    final commitId = (commitResult.stdout as String).trim();

    return GitInfo(branch: branch, commitId: commitId);
  }
}
