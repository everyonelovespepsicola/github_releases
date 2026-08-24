import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../models/repository_info.dart';
import '../services/github_api_service.dart';
import '../theme.dart';

class CreateReleaseView extends StatefulWidget {
  final RepositoryInfo? activeRepo;
  final VoidCallback onReleaseCreated;

  const CreateReleaseView({
    Key? key,
    required this.activeRepo,
    required this.onReleaseCreated,
  }) : super(key: key);

  @override
  State<CreateReleaseView> createState() => _CreateReleaseViewState();
}

class _CreateReleaseViewState extends State<CreateReleaseView> {
  final _tagController = TextEditingController(text: 'v1.0.0');
  final _titleController = TextEditingController(text: 'v1.0.0 - Official Release');
  final _bodyController = TextEditingController();
  final _targetBranchController = TextEditingController(text: 'main');

  bool _isDraft = false;
  bool _isPrerelease = false;
  bool _isPublishing = false;
  String _statusMessage = '';

  final List<String> _attachedFilePaths = [];

  @override
  void initState() {
    super.initState();
    _applyDefaultTemplate();
  }

  void _applyDefaultTemplate() {
    _bodyController.text = '''## 🌟 What's Changed in this Release

### 🚀 Key Highlights & Features
- Initial release build.
- Added native Windows 11 Fluent UI interface.

### 🐛 Bug Fixes & Improvements
- Performance optimizations & security enhancements.

---
*Generated with GitHub Release Manager*''';
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final path in result.paths) {
          if (path != null && !_attachedFilePaths.contains(path)) {
            _attachedFilePaths.add(path);
          }
        }
      });
    }
  }

  bool _isValidGitTag(String tag) {
    if (tag.isEmpty) return false;
    if (tag.startsWith('-') || tag.endsWith('.') || tag.endsWith('.lock')) return false;
    final invalidChars = RegExp(r'[\s~^:?*\[\\\]@{}]');
    if (invalidChars.hasMatch(tag)) return false;
    if (tag.contains('..') || tag.contains('//')) return false;
    return true;
  }

  Future<void> _publishRelease() async {
    final repo = widget.activeRepo;
    if (repo == null || !repo.isValid) {
      _showDialog('No Repository Selected', 'Please select or enter a valid GitHub repository (owner/repo) first.');
      return;
    }

    final tag = _tagController.text.trim();
    if (tag.isEmpty) {
      _showDialog('Missing Tag Name', 'Please enter a valid Git release tag (e.g. v1.0.0).');
      return;
    }

    if (!_isValidGitTag(tag)) {
      _showDialog(
        'Invalid Git Tag Format',
        'The tag "$tag" contains invalid characters.\n\n'
        'Git Tag Rules:\n'
        '• Cannot contain spaces, tildes (~), colons (:), carats (^), or wildcards (*, ?, [).\n'
        '• Cannot contain consecutive dots (..) or slashes (//).\n'
        '• Valid examples: v1.0.0, v1.0.0-beta.1, 1.2.3',
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _statusMessage = 'Publishing release tag "$tag" to ${repo.fullName}...';
    });

    try {
      final releaseJson = await GitHubApiService.createRelease(
        owner: repo.owner,
        repo: repo.repo,
        tagName: tag,
        title: _titleController.text.trim(),
        body: _bodyController.text,
        isDraft: _isDraft,
        isPrerelease: _isPrerelease,
        targetCommitish: _targetBranchController.text.trim(),
      );

      final uploadUrl = releaseJson['upload_url'] as String?;

      if (_attachedFilePaths.isNotEmpty && uploadUrl != null) {
        for (var i = 0; i < _attachedFilePaths.length; i++) {
          final filePath = _attachedFilePaths[i];
          final fileName = filePath.split('\\').last.split('/').last;

          setState(() {
            _statusMessage = 'Uploading asset [${i + 1}/${_attachedFilePaths.length}]: $fileName...';
          });

          await GitHubApiService.uploadAsset(
            uploadUrlTemplate: uploadUrl,
            filePath: filePath,
            fileName: fileName,
          );
        }
      }

      setState(() {
        _isPublishing = false;
        _statusMessage = '';
        _attachedFilePaths.clear();
      });

      widget.onReleaseCreated();

      _showDialog('🟢 Release Published Successfully!', 'GitHub Release "$tag" has been created for ${repo.fullName} with all assets attached.');
    } catch (e) {
      setState(() {
        _isPublishing = false;
        _statusMessage = '';
      });
      _showDialog('🔴 Release Publication Failed', e.toString());
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.activeRepo;

    return ScaffoldPage.withPadding(
      header: PageHeader(
        title: Row(
          children: [
            const Icon(FluentIcons.rocket, color: AppTheme.pastelTeal, size: 22),
            const SizedBox(width: 10),
            const Text('Create & Publish Release'),
            const Spacer(),
            if (repo != null && repo.isValid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderOutline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.code, color: AppTheme.pastelLavender, size: 14),
                    const SizedBox(width: 6),
                    Text(repo.fullName, style: const TextStyle(color: AppTheme.pastelLavender, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grid: Tag, Title, Branch
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InfoLabel(
                    label: 'Tag Version Name:',
                    child: TextBox(
                      controller: _tagController,
                      placeholder: 'e.g. v1.0.0',
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\s~^:?*\[\\\]@{}]')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: InfoLabel(
                    label: 'Release Title:',
                    child: TextBox(
                      controller: _titleController,
                      placeholder: 'e.g. v1.0.0 — Official Initial Release',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InfoLabel(
                    label: 'Target Branch:',
                    child: TextBox(
                      controller: _targetBranchController,
                      placeholder: 'main',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options: Draft & Pre-release Toggles
            Row(
              children: [
                ToggleSwitch(
                  checked: _isPrerelease,
                  onChanged: (val) => setState(() => _isPrerelease = val),
                  content: const Text('Mark as Pre-release (Beta / Alpha)'),
                ),
                const SizedBox(width: 24),
                ToggleSwitch(
                  checked: _isDraft,
                  onChanged: (val) => setState(() => _isDraft = val),
                  content: const Text('Save as Draft (Do not notify users)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Release Notes Text Area
            InfoLabel(
              label: 'Release Notes (Markdown supported):',
              child: TextBox(
                controller: _bodyController,
                maxLines: 8,
                placeholder: 'Describe your changes...',
              ),
            ),
            const SizedBox(height: 16),

            // Asset Attachment Dropzone
            DropTarget(
              onDragDone: (details) {
                setState(() {
                  for (final file in details.files) {
                    if (!_attachedFilePaths.contains(file.path)) {
                      _attachedFilePaths.add(file.path);
                    }
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.pastelTeal.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(FluentIcons.cloud_upload, color: AppTheme.pastelTeal, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Drag & Drop Release Binaries (.zip, .exe, .apk, .7z) Here',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text('or click the button below to pick files from your computer', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 12),
                    Button(
                      onPressed: _pickFiles,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.folder_open, size: 14),
                          SizedBox(width: 6),
                          Text('Browse Files...'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Attached Files List
            if (_attachedFilePaths.isNotEmpty) ...[
              const Text('ATTACHED RELEASE ASSETS:', style: TextStyle(color: AppTheme.pastelLavender, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attachedFilePaths.length,
                itemBuilder: (ctx, idx) {
                  final path = _attachedFilePaths[idx];
                  final name = path.split('\\').last.split('/').last;
                  final size = File(path).existsSync() ? File(path).lengthSync() : 0;
                  final formattedSize = size < 1024 * 1024 ? '${(size / 1024).toStringAsFixed(1)} KB' : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.acrylicNavigationHeader,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderOutline),
                    ),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.archive, color: AppTheme.pastelTeal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Text(formattedSize, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(FluentIcons.delete, color: AppTheme.pastelCoral, size: 14),
                          onPressed: () {
                            setState(() => _attachedFilePaths.removeAt(idx));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Publish Button & Progress Indicator
            if (_isPublishing) ...[
              ProgressBar(value: null),
              const SizedBox(height: 8),
              Text(_statusMessage, style: const TextStyle(color: AppTheme.pastelYellow, fontSize: 12, fontWeight: FontWeight.bold)),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _publishRelease,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.rocket, size: 18, color: Colors.black),
                      SizedBox(width: 8),
                      Text('PUBLISH RELEASE TO GITHUB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
