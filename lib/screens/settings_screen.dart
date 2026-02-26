import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final isDark = theme.isDark;

    return Scaffold(
      appBar: const GradientAppBar(title: '⚙️ Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Appearance ─────────────────────────────────────────
          _SectionHeader(label: '🎨 Appearance'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: kPrimary),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(isDark ? 'Currently dark' : 'Currently light'),
                value: isDark,
                activeColor: kPrimary,
                onChanged: (_) => context.read<ThemeService>().toggle(),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Data Backup ────────────────────────────────────────
          _SectionHeader(label: '💾 Data Backup'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.upload, color: kPrimary)),
                title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Save or share all your data as JSON'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showExportOptions(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.download, color: kSecondary)),
                title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Restore from a JSON backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showImportOptions(context),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Danger Zone ────────────────────────────────────────
          _SectionHeader(label: '⚠️ Danger Zone'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_forever, color: Colors.red)),
              title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Permanently delete everything'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _confirmClear(context),
            ),
          ),
          const SizedBox(height: 20),

          // ── About ──────────────────────────────────────────────
          _SectionHeader(label: 'ℹ️ About'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: kPrimary),
                title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Text('1.2.0', style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.school_outlined, color: kPrimary),
                title: const Text('Engineering Student Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Built for students, by students'),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Export ──────────────────────────────────────────────────────
  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.share, color: kPrimary)),
        title: const Text('Save / Share as JSON file'),
        subtitle: const Text('Save to Downloads or share via app'),
        onTap: () { Navigator.pop(context); _exportAsFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.copy, color: kSecondary)),
        title: const Text('Copy JSON to clipboard'),
        subtitle: const Text('Paste it anywhere manually'),
        onTap: () { Navigator.pop(context); _exportAsCopy(context); },
      ),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _exportAsFile(BuildContext context) async {
    final json = context.read<StorageService>().exportData();
    final filename = 'dashboard-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], subject: 'Dashboard Backup');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }

  void _exportAsCopy(BuildContext context) {
    final json = context.read<StorageService>().exportData();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.copy, color: kPrimary), SizedBox(width: 8), Text('Copy JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Tap Copy to copy all data:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 150, child: TextField(controller: TextEditingController(text: json), maxLines: null, readOnly: true,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'), decoration: const InputDecoration(border: OutlineInputBorder()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy), label: const Text('Copy All'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)));
          },
        ),
      ],
    ));
  }

  // ── Import ──────────────────────────────────────────────────────
  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder_open, color: kPrimary)),
        title: const Text('Pick JSON file'),
        subtitle: const Text('Browse and select your backup file'),
        onTap: () { Navigator.pop(context); _importFromFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.paste, color: kSecondary)),
        title: const Text('Paste JSON text'),
        subtitle: const Text('Paste copied backup text manually'),
        onTap: () { Navigator.pop(context); _importFromPaste(context); },
      ),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String json;
      if (file.bytes != null) {
        json = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        json = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file');
      }
      if (context.mounted) _confirmAndImport(context, json);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  void _importFromPaste(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.paste, color: kPrimary), SizedBox(width: 8), Text('Paste JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Paste your backup JSON below:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, maxLines: 8, decoration: const InputDecoration(hintText: 'Paste JSON here...', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload), label: const Text('Import'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            _confirmAndImport(context, ctrl.text.trim());
          },
        ),
      ],
    ));
  }

  void _confirmAndImport(BuildContext context, String json) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Confirm Import'),
      content: const Text('This will overwrite ALL current data.\n\nAre you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            final result = context.read<StorageService>().importData(json);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result == 'success' ? '✅ Imported successfully!' : '❌ $result'),
                duration: const Duration(seconds: 3)));
          },
          child: const Text('Yes, overwrite'),
        ),
      ],
    ));
  }

  // ── Clear All ───────────────────────────────────────────────────
  void _confirmClear(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Clear All Data'),
      content: const Text('This will permanently delete all your courses, assignments, schedule, notes, formulas, and library sections.\n\nThis cannot be undone!'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(ctx);
            context.read<StorageService>().clearAll();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All data cleared.'), duration: Duration(seconds: 2)));
          },
          child: const Text('Delete Everything'),
        ),
      ],
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
  );
}
