import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import '../models/repository_info.dart';
import '../services/git_config_parser.dart';
import '../services/repository_store.dart';
import '../theme.dart';

class RepositoryPickerFlyout extends StatefulWidget {
  final RepositoryInfo? activeRepo;
  final Function(RepositoryInfo repo) onRepositorySelected;

  const RepositoryPickerFlyout({
    Key? key,
    required this.activeRepo,
    required this.onRepositorySelected,
  }) : super(key: key);

  @override
  State<RepositoryPickerFlyout> createState() => _RepositoryPickerFlyoutState();
}

class _RepositoryPickerFlyoutState extends State<RepositoryPickerFlyout> {
  final _searchController = TextEditingController();
  List<RepositoryInfo> _recentRepos = [];
  List<RepositoryInfo> _localRepos = [];
  List<RepositoryInfo> _remoteRepos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Recent, 1: Local, 2: GitHub API

  @override
  void initState() {
    super.initState();
    _loadAllRepositories();
  }

  Future<void> _loadAllRepositories() async {
    setState(() => _isLoading = true);

    final recent = await RepositoryStore.getRecentRepositories();
    final local = await RepositoryStore.scanLocalProjects();
    final remote = await RepositoryStore.fetchUserGitHubRepositories();

    if (mounted) {
      setState(() {
        _recentRepos = recent;
        _localRepos = local;
        _remoteRepos = remote;
        _isLoading = false;
      });
    }
  }

  Future<void> _addLocalFolder() async {
    final selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      final repo = await GitConfigParser.parseDirectory(selectedDir);
      if (repo != null) {
        await RepositoryStore.addRecentRepository(repo);
        widget.onRepositorySelected(repo);
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => ContentDialog(
              title: const Text('No Git Repository Found'),
              content: Text('The folder "$selectedDir" does not appear to contain a valid Git repository with a remote GitHub URL in .git/config.'),
              actions: [
                Button(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          );
        }
      }
    }
  }

  List<RepositoryInfo> _filterList(List<RepositoryInfo> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final q = _searchQuery.trim().toLowerCase();
    return source.where((r) => r.fullName.toLowerCase().contains(q) || r.localPath.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedTab == 0
        ? _filterList(_recentRepos)
        : (_selectedTab == 1 ? _filterList(_localRepos) : _filterList(_remoteRepos));

    return Container(
      width: 420,
      height: 480,
      decoration: BoxDecoration(
        color: AppTheme.darkCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.pastelTeal.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Search & Title Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.obsidianBackground,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(FluentIcons.repo, color: AppTheme.pastelTeal, size: 16),
                    SizedBox(width: 8),
                    Text('Select Active Repository', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                TextBox(
                  controller: _searchController,
                  placeholder: 'Filter repositories (e.g. ADB_Toolkit)...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(FluentIcons.search, size: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Category Selector Tabs
          Container(
            color: AppTheme.acrylicNavigationHeader,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Button(
                    style: ButtonStyle(
                      backgroundColor: _selectedTab == 0 ? WidgetStateProperty.all(AppTheme.pastelTeal.withOpacity(0.2)) : null,
                    ),
                    onPressed: () => setState(() => _selectedTab = 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.pinned, size: 11, color: AppTheme.pastelTeal),
                        const SizedBox(width: 4),
                        Text('Recent (${_recentRepos.length})', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Button(
                    style: ButtonStyle(
                      backgroundColor: _selectedTab == 1 ? WidgetStateProperty.all(AppTheme.pastelLavender.withOpacity(0.2)) : null,
                    ),
                    onPressed: () => setState(() => _selectedTab = 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.folder_open, size: 11, color: AppTheme.pastelLavender),
                        const SizedBox(width: 4),
                        Text('Local (${_localRepos.length})', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Button(
                    style: ButtonStyle(
                      backgroundColor: _selectedTab == 2 ? WidgetStateProperty.all(AppTheme.pastelRose.withOpacity(0.2)) : null,
                    ),
                    onPressed: () => setState(() => _selectedTab = 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.cloud, size: 11, color: AppTheme.pastelRose),
                        const SizedBox(width: 4),
                        Text('GitHub (${_remoteRepos.length})', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Repository List View
          Expanded(
            child: _isLoading
                ? const Center(child: ProgressRing())
                : activeList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FluentIcons.open_folder_horizontal, color: AppTheme.pastelLavender, size: 28),
                            const SizedBox(height: 8),
                            Text('No repositories found matching "$_searchQuery"', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: activeList.length,
                        itemBuilder: (ctx, idx) {
                          final repo = activeList[idx];
                          final isSelected = widget.activeRepo?.fullName.toLowerCase() == repo.fullName.toLowerCase();

                          return GestureDetector(
                            onTap: () {
                              RepositoryStore.addRecentRepository(repo);
                              widget.onRepositorySelected(repo);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.pastelTeal.withOpacity(0.15) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: AppTheme.borderOutline.withOpacity(0.5))),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    repo.localPath.isNotEmpty ? FluentIcons.repo : FluentIcons.cloud,
                                    color: isSelected ? AppTheme.pastelTeal : AppTheme.pastelLavender,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          repo.fullName,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? AppTheme.pastelTeal : AppTheme.textPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (repo.localPath.isNotEmpty)
                                          Text(
                                            repo.localPath,
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(FluentIcons.check_mark, color: AppTheme.pastelGreen, size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Footer Action Bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.obsidianBackground,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Button(
                    onPressed: _addLocalFolder,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.add, size: 12),
                        SizedBox(width: 6),
                        Text('Add Local Repository...', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.refresh, size: 12),
                  onPressed: _loadAllRepositories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
