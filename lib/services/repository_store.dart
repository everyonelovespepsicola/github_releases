import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repository_info.dart';
import 'git_config_parser.dart';
import 'github_api_service.dart';

class RepositoryStore {
  static const String _prefRecentReposKey = 'recent_repositories_list';

  static Future<List<RepositoryInfo>> getRecentRepositories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefRecentReposKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        return list.map((e) {
          final map = e as Map<String, dynamic>;
          return RepositoryInfo(
            owner: map['owner'] as String? ?? '',
            repo: map['repo'] as String? ?? '',
            localPath: map['localPath'] as String? ?? '',
            remoteUrl: map['remoteUrl'] as String? ?? '',
          );
        }).where((r) => r.isValid).toList();
      } catch (_) {}
    }
    return await scanLocalProjects();
  }

  static Future<void> addRecentRepository(RepositoryInfo repo) async {
    if (!repo.isValid) return;

    final current = await getRecentRepositories();
    current.removeWhere((r) => r.fullName.toLowerCase() == repo.fullName.toLowerCase());
    current.insert(0, repo);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = current
        .take(15)
        .map((r) => {
              'owner': r.owner,
              'repo': r.repo,
              'localPath': r.localPath,
              'remoteUrl': r.remoteUrl,
            })
        .toList();

    await prefs.setString(_prefRecentReposKey, jsonEncode(jsonList));
  }

  static Future<List<RepositoryInfo>> scanLocalProjects() async {
    final List<RepositoryInfo> results = [];
    final List<String> searchRoots = [
      'C:\\projects\\android_apps',
      'C:\\projects\\github_apps',
      'C:\\projects',
    ];

    for (final rootPath in searchRoots) {
      final dir = Directory(rootPath);
      if (await dir.exists()) {
        try {
          final subDirs = await dir.list().toList();
          for (final entity in subDirs) {
            if (entity is Directory) {
              final repo = await GitConfigParser.parseDirectory(entity.path);
              if (repo != null && !results.any((r) => r.fullName.toLowerCase() == repo.fullName.toLowerCase())) {
                results.add(repo);
              }
            }
          }
        } catch (_) {}
      }
    }
    return results;
  }

  static Future<List<RepositoryInfo>> fetchUserGitHubRepositories() async {
    final List<RepositoryInfo> results = [];
    final token = await GitHubApiService.getSavedToken();
    if (token == null || token.isEmpty) return results;

    try {
      final url = Uri.parse('https://api.github.com/user/repos?per_page=100&sort=updated');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'GitHubReleaseManager/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final fullName = map['full_name'] as String? ?? '';
          final htmlUrl = map['html_url'] as String? ?? '';
          if (fullName.contains('/')) {
            final parts = fullName.split('/');
            results.add(RepositoryInfo(
              owner: parts[0],
              repo: parts[1],
              localPath: '',
              remoteUrl: htmlUrl,
            ));
          }
        }
      }
    } catch (_) {}
    return results;
  }
}
