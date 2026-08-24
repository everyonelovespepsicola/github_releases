import 'package:fluent_ui/fluent_ui.dart';
import '../services/github_api_service.dart';
import '../theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _tokenController = TextEditingController();
  bool _isLoadingToken = false;
  String _authStatusMessage = 'Resolving credentials...';

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    setState(() => _isLoadingToken = true);
    final savedToken = await GitHubApiService.getSavedToken();
    if (mounted) {
      setState(() {
        if (savedToken != null && savedToken.isNotEmpty) {
          _tokenController.text = savedToken;
          _authStatusMessage = '🟢 GitHub Credentials Active (Token / GitHub CLI gh)';
        } else {
          _authStatusMessage = '🔴 No GitHub Personal Access Token or gh CLI token detected.';
        }
        _isLoadingToken = false;
      });
    }
  }

  Future<void> _saveToken() async {
    final t = _tokenController.text.trim();
    await GitHubApiService.saveToken(t);
    _loadSavedToken();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('Token Saved'),
          content: const Text('Personal Access Token has been saved to secure local storage.'),
          actions: [
            Button(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      );
    }
  }

  Future<void> _autoDetectGhToken() async {
    setState(() => _isLoadingToken = true);
    final ghToken = await GitHubApiService.resolveGhCliToken();
    if (mounted) {
      setState(() {
        if (ghToken != null && ghToken.isNotEmpty) {
          _tokenController.text = ghToken;
          GitHubApiService.saveToken(ghToken);
          _authStatusMessage = '🟢 Successfully auto-detected active token from GitHub CLI (gh)!';
        } else {
          _authStatusMessage = '⚠️ GitHub CLI (gh) not logged in. Run "gh auth login" in terminal.';
        }
        _isLoadingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      header: PageHeader(
        title: Row(
          children: [
            Icon(FluentIcons.settings, color: AppTheme.pastelTeal, size: 22),
            const SizedBox(width: 10),
            const Text('Settings & GitHub Authentication'),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth Card
            Container(
              width: double.infinity,
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
                      Icon(FluentIcons.lock, color: AppTheme.pastelLavender, size: 18),
                      const SizedBox(width: 8),
                      const Text('GITHUB API AUTHENTICATION TOKEN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_authStatusMessage, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: _tokenController,
                    placeholder: 'ghp_... (Personal Access Token with repo scope)',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: _saveToken,
                        child: Text('SAVE TOKEN', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onAccent)),
                      ),
                      Button(
                        onPressed: _isLoadingToken ? null : _autoDetectGhToken,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.refresh, size: 14),
                            SizedBox(width: 6),
                            Text('Auto-Detect GitHub CLI Token (gh)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme Info Card
            Container(
              width: double.infinity,
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
                      Icon(FluentIcons.color, color: AppTheme.pastelTeal, size: 18),
                      const SizedBox(width: 8),
                      Text('METRO DARK JSON THEME ACTIVE (${AppTheme.current.themeName})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Built with JSON-driven theme schema (assets/themes/metro_dark.json) using paired contrast tokens (Deep Charcoal, Dark Greys, Crisp Whites, Amber Yellow, Crimson Red).',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
