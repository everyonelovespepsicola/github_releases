class RepositoryInfo {
  final String owner;
  final String repo;
  final String localPath;
  final String remoteUrl;

  RepositoryInfo({
    required this.owner,
    required this.repo,
    required this.localPath,
    required this.remoteUrl,
  });

  String get fullName => '$owner/$repo';
  bool get isValid => owner.isNotEmpty && repo.isNotEmpty;
}
