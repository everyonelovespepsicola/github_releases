class GitHubReleaseAsset {
  final int id;
  final String name;
  final int size;
  final int downloadCount;
  final String browserDownloadUrl;
  final String createdAt;

  GitHubReleaseAsset({
    required this.id,
    required this.name,
    required this.size,
    required this.downloadCount,
    required this.browserDownloadUrl,
    required this.createdAt,
  });

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseAsset(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'asset',
      size: json['size'] as int? ?? 0,
      downloadCount: json['download_count'] as int? ?? 0,
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class GitHubRelease {
  final int id;
  final String tagName;
  final String title;
  final String body;
  final bool isDraft;
  final bool isPrerelease;
  final String htmlUrl;
  final String publishedAt;
  final List<GitHubReleaseAsset> assets;

  GitHubRelease({
    required this.id,
    required this.tagName,
    required this.title,
    required this.body,
    required this.isDraft,
    required this.isPrerelease,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assetList = (json['assets'] as List<dynamic>?)
            ?.map((e) => GitHubReleaseAsset.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return GitHubRelease(
      id: json['id'] as int? ?? 0,
      tagName: json['tag_name'] as String? ?? '',
      title: json['name'] as String? ?? json['tag_name'] as String? ?? 'Release',
      body: json['body'] as String? ?? '',
      isDraft: json['draft'] as bool? ?? false,
      isPrerelease: json['prerelease'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? json['created_at'] as String? ?? '',
      assets: assetList,
    );
  }
}
