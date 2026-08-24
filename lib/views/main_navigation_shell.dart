import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import '../models/repository_info.dart';
import '../services/git_config_parser.dart';
import '../theme.dart';
import 'create_release_view.dart';
import 'release_history_view.dart';
import 'settings_view.dart';

import 'repository_picker_flyout.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _topIndex = 0;
  RepositoryInfo? _activeRepo;
  final _customRepoUrlController = TextEditingController();
  final FlyoutController _repoFlyoutController = FlyoutController();

  @override
  void initState() {
    super.initState();
    // Default fallback to local directory scan or owner/repo
    _autoDetectCurrentRepo();
  }

  @override
  void dispose() {
    _repoFlyoutController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectCurrentRepo() async {
    final defaultPath = 'C:\\projects\\android_apps\\ADB_Toolkit';
    final repo = await GitConfigParser.parseDirectory(defaultPath);
    if (repo != null && mounted) {
      setState(() {
        _activeRepo = repo;
        _customRepoUrlController.text = repo.fullName;
      });
    }
  }

  void _applyCustomRepoText() {
    final text = _customRepoUrlController.text.trim();
    if (text.isEmpty) return;

    final parsed = GitConfigParser.parseRemoteUrl(text, '');
    if (parsed != null && mounted) {
      setState(() => _activeRepo = parsed);
    } else if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length >= 2) {
        setState(() {
          _activeRepo = RepositoryInfo(
            owner: parts[0],
            repo: parts[1],
            localPath: '',
            remoteUrl: 'https://github.com/$text',
          );
        });
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          Button(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          // Windows Native Window TitleBar & Repository Bar
          Container(
            height: 48,
            color: AppTheme.obsidianBackground,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(FluentIcons.git_graph, color: AppTheme.pastelTeal, size: 20),
                const SizedBox(width: 8),
                Text('GitHub Release Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(width: 20),

                // GitHub Desktop Style Repository Selector Flyout Trigger
                FlyoutTarget(
                  controller: _repoFlyoutController,
                  child: Button(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(AppTheme.darkCardSurface),
                    ),
                    onPressed: () {
                      _repoFlyoutController.showFlyout(
                        builder: (context) {
                          return FlyoutContent(
                            padding: EdgeInsets.zero,
                            child: RepositoryPickerFlyout(
                              activeRepo: _activeRepo,
                              onRepositorySelected: (repo) {
                                Navigator.of(context).pop();
                                setState(() {
                                  _activeRepo = repo;
                                  _customRepoUrlController.text = repo.fullName;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.repo, color: AppTheme.pastelTeal, size: 14),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Current repository', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                              Text(
                                _activeRepo != null ? _activeRepo!.fullName : 'Select Repository...',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.pastelTeal),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Icon(FluentIcons.chevron_down, size: 10, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Quick Direct Repo Input Box
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCardSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderOutline),
                    ),
                    child: Row(
                      children: [
                        Icon(FluentIcons.code, color: AppTheme.pastelLavender, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextBox(
                            controller: _customRepoUrlController,
                            placeholder: 'owner/repo or https://github.com/owner/repo',
                            style: TextStyle(fontSize: 12, color: AppTheme.pastelTeal, fontWeight: FontWeight.bold),
                            onSubmitted: (_) => _applyCustomRepoText(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(FluentIcons.check_mark, size: 12, color: AppTheme.pastelGreen),
                          onPressed: _applyCustomRepoText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Window Drag Area & Controls
                const Expanded(child: WindowCaption()),
              ],
            ),
          ),

          // Main NavigationPane Content
          Expanded(
            child: NavigationView(
              pane: NavigationPane(
                selected: _topIndex,
                onChanged: (index) => setState(() => _topIndex = index),
                displayMode: PaneDisplayMode.expanded,
                items: [
                  PaneItem(
                    icon: const Icon(FluentIcons.rocket),
                    title: const Text('Create & Publish Release'),
                    body: CreateReleaseView(
                      activeRepo: _activeRepo,
                      onReleaseCreated: () => setState(() => _topIndex = 1),
                    ),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.history),
                    title: const Text('Release History'),
                    body: ReleaseHistoryView(activeRepo: _activeRepo),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.settings),
                    title: const Text('Settings & Auth'),
                    body: const SettingsView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
