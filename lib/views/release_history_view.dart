import 'package:fluent_ui/fluent_ui.dart';
import '../models/github_release.dart';
import '../models/repository_info.dart';
import '../services/github_api_service.dart';
import '../theme.dart';

class ReleaseHistoryView extends StatefulWidget {
  final RepositoryInfo? activeRepo;

  const ReleaseHistoryView({
    Key? key,
    required this.activeRepo,
  }) : super(key: key);

  @override
  State<ReleaseHistoryView> createState() => _ReleaseHistoryViewState();
}

class _ReleaseHistoryViewState extends State<ReleaseHistoryView> {
  List<GitHubRelease> _releases = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  @override
  void didUpdateWidget(covariant ReleaseHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRepo?.fullName != widget.activeRepo?.fullName) {
      _loadReleases();
    }
  }

  Future<void> _loadReleases() async {
    final repo = widget.activeRepo;
    if (repo == null || !repo.isValid) {
      setState(() {
        _releases = [];
        _errorMessage = 'No valid repository selected. Please select a repository above.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await GitHubApiService.fetchReleases(repo.owner, repo.repo);
      if (mounted) {
        setState(() {
          _releases = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRelease(GitHubRelease release) async {
    final repo = widget.activeRepo;
    if (repo == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Delete Release Confirmation', style: TextStyle(color: AppTheme.pastelCoral, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete release "${release.tagName}"? This will also delete all attached asset binaries on GitHub.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            child: const Text('DELETE RELEASE', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await GitHubApiService.deleteRelease(
        owner: repo.owner,
        repo: repo.repo,
        releaseId: release.id,
      );

      if (success) {
        _loadReleases();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.activeRepo;

    return ScaffoldPage.withPadding(
      header: PageHeader(
        title: Row(
          children: [
            const Icon(FluentIcons.history, color: AppTheme.pastelLavender, size: 22),
            const SizedBox(width: 10),
            const Text('Release History & Assets'),
            const Spacer(),
            IconButton(
              icon: const Icon(FluentIcons.refresh, size: 16),
              onPressed: _loadReleases,
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.warning, color: AppTheme.pastelYellow, size: 36),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Button(onPressed: _loadReleases, child: const Text('Retry Fetching Releases')),
                    ],
                  ),
                )
              : _releases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FluentIcons.open_folder_horizontal, color: AppTheme.pastelLavender, size: 40),
                          const SizedBox(height: 12),
                          Text('No published releases found for ${repo?.fullName ?? "this repository"}.', style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _releases.length,
                      itemBuilder: (ctx, idx) {
                        final rel = _releases[idx];
                        final badgeColor = rel.isDraft ? AppTheme.pastelCoral : (rel.isPrerelease ? AppTheme.pastelYellow : AppTheme.pastelGreen);
                        final badgeLabel = rel.isDraft ? 'DRAFT' : (rel.isPrerelease ? 'PRE-RELEASE' : 'PUBLISHED');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderOutline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeColor),
                                    ),
                                    child: Text(badgeLabel, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(rel.tagName, style: const TextStyle(color: AppTheme.pastelTeal, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 10),
                                  Text(rel.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(FluentIcons.delete, color: AppTheme.pastelCoral, size: 16),
                                    onPressed: () => _deleteRelease(rel),
                                  ),
                                ],
                              ),
                              if (rel.body.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.acrylicNavigationHeader,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rel.body,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (rel.assets.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('ATTACHED ASSETS:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: rel.assets.map((asset) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.obsidianBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.borderOutline),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(FluentIcons.download, color: AppTheme.pastelTeal, size: 12),
                                          const SizedBox(width: 6),
                                          Text(asset.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 6),
                                          Text('(${asset.formattedSize} • ${asset.downloadCount} downloads)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
