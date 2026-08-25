import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_release.dart';

class GitHubApiService {
  static const String _prefTokenKey = 'github_personal_access_token';

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefTokenKey);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return await resolveGhCliToken();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, token.trim());
  }

  static Future<String?> resolveGhCliToken() async {
    try {
      final shell = Shell(throwOnError: false);
      final result = await shell.run('gh auth token');
      if (result.isNotEmpty && result.first.exitCode == 0) {
        final token = result.first.stdout.toString().trim();
        if (token.isNotEmpty && !token.contains('error')) {
          return token;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<String>> fetchBranches(String owner, String repo) async {
    final token = await getSavedToken();
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/branches');

    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'GitHubReleaseManager/1.0',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final branches = jsonList.map((e) => e['name'] as String).toList();
        if (branches.isNotEmpty) return branches;
      }
    } catch (_) {}
    return ['master', 'main'];
  }

  static Future<List<GitHubRelease>> fetchReleases(String owner, String repo) async {
    final token = await getSavedToken();
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');

    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'GitHubReleaseManager/1.0',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => GitHubRelease.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('GitHub API HTTP ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createRelease({
    required String owner,
    required String repo,
    required String tagName,
    required String title,
    required String body,
    required bool isDraft,
    required bool isPrerelease,
    String targetCommitish = 'main',
  }) async {
    final token = await getSavedToken();
    if (token == null || token.isEmpty) {
      throw Exception('GitHub Access Token is missing. Please add a Personal Access Token in Settings or log into GitHub CLI (gh auth login).');
    }

    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');
    final payload = {
      'tag_name': tagName,
      'target_commitish': targetCommitish,
      'name': title.isNotEmpty ? title : tagName,
      'body': body,
      'draft': isDraft,
      'prerelease': isPrerelease,
      'generate_release_notes': body.isEmpty,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'GitHubReleaseManager/1.0',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create release (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  static Future<bool> uploadAsset({
    required String uploadUrlTemplate,
    required String filePath,
    required String fileName,
  }) async {
    final token = await getSavedToken();
    if (token == null || token.isEmpty) return false;

    // Clean upload URL template e.g. "https://uploads.github.com/repos/owner/repo/releases/1/assets{?name,label}"
    var cleanUrl = uploadUrlTemplate.split('{').first;
    cleanUrl = '$cleanUrl?name=${Uri.encodeComponent(fileName)}';

    final file = File(filePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();

    final response = await http.post(
      Uri.parse(cleanUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/octet-stream',
        'User-Agent': 'GitHubReleaseManager/1.0',
      },
      body: bytes,
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> deleteRelease({
    required String owner,
    required String repo,
    required int releaseId,
  }) async {
    final token = await getSavedToken();
    if (token == null || token.isEmpty) return false;

    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/$releaseId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'GitHubReleaseManager/1.0',
      },
    );

    return response.statusCode == 240 || response.statusCode == 204;
  }
}
