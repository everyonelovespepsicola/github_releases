import 'dart:io';
import '../models/repository_info.dart';

class GitConfigParser {
  static Future<RepositoryInfo?> parseDirectory(String directoryPath) async {
    try {
      final configFile = File('$directoryPath\\.git\\config');
      if (!await configFile.exists()) {
        return null;
      }

      final content = await configFile.readAsString();
      final lines = content.split('\n');
      String? remoteUrl;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.contains('[remote "origin"]') || line.contains('[remote ')) {
          for (var j = i + 1; j < lines.length; j++) {
            final subLine = lines[j].trim();
            if (subLine.startsWith('[')) break; // Start of next section
            if (subLine.startsWith('url =')) {
              remoteUrl = subLine.substring(5).trim();
              break;
            }
          }
        }
      }

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        return parseRemoteUrl(remoteUrl, directoryPath);
      }
    } catch (_) {}
    return null;
  }

  static RepositoryInfo? parseRemoteUrl(String url, String localPath) {
    try {
      String clean = url.trim();
      if (clean.endsWith('.git')) {
        clean = clean.substring(0, clean.length - 4);
      }

      String owner = '';
      String repo = '';

      if (clean.startsWith('https://github.com/') || clean.startsWith('http://github.com/')) {
        final parts = clean.replaceFirst(RegExp(r'https?://github\.com/'), '').split('/');
        if (parts.length >= 2) {
          owner = parts[0];
          repo = parts[1];
        }
      } else if (clean.startsWith('git@github.com:')) {
        final parts = clean.replaceFirst('git@github.com:', '').split('/');
        if (parts.length >= 2) {
          owner = parts[0];
          repo = parts[1];
        }
      }

      if (owner.isNotEmpty && repo.isNotEmpty) {
        return RepositoryInfo(
          owner: owner,
          repo: repo,
          localPath: localPath,
          remoteUrl: url,
        );
      }
    } catch (_) {}
    return null;
  }
}
