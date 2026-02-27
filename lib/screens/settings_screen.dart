import 'dart:io';
import 'package:archive/archive_io.dart';
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

const _kSections = {
  'gpa':         '📊 GPA & Courses',
  'assignments': '📋 Assignments',
  'schedule':    '📅 Schedule',
  'library':     '📚 Library & Notes',
  'formulas':    '📐 Formulas',
  'priorities':  '🎯 Priority Labels',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDark;

    return Scaffold(
      appBar: const GradientAppBar(title: '⚙️ Settings'),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ── Appearance ─────────────────────────────────────────
        _Header(label: '🎨 Appearance'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child:
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: kPrimary),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(isDark ? 'Currently dark' : 'Currently light'),
            value: isDark, activeColor: kPrimary,
            onChanged: (_) => context.read<ThemeService>().toggle())),
        const SizedBox(height: 20),

        // ── Data Backup ────────────────────────────────────────
        _Header(label: '💾 Data Backup'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Column(children: [
          ListTile(
            leading: _iconBox(Icons.upload_rounded, kPrimary),
            title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Choose sections to save or share as JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSectionPicker(context, isExport: true)),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _iconBox(Icons.download_rounded, kSecondary),
            title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Choose sections to restore from JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSectionPicker(context, isExport: false)),
        ])),
        const SizedBox(height: 12),

        // ── Media Backup ───────────────────────────────────────
        _Header(label: '🖼️ Media Backup'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Column(children: [
          ListTile(
            leading: _iconBox(Icons.photo_library_rounded, Colors.teal),
            title: const Text('Export Photos & PDFs', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Bundle all note attachments as a .zip file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportMediaBundle(context)),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _iconBox(Icons.folder_zip_rounded, Colors.orange),
            title: const Text('Import Media Bundle', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Restore attachments from a .zip backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importMediaBundle(context)),
        ])),
        const SizedBox(height: 20),

        // ── Danger Zone ────────────────────────────────────────
        _Header(label: '⚠️ Danger Zone'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: ListTile(
          leading: _iconBox(Icons.delete_forever, Colors.red),
          title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
          subtitle: const Text('Permanently delete everything'),
          trailing: const Icon(Icons.chevron_right, color: Colors.red),
          onTap: () => _confirmClear(context))),
        const SizedBox(height: 20),

        // ── About ──────────────────────────────────────────────
        _Header(label: 'ℹ️ About'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Column(children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: kPrimary),
            title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text('1.4.0', style: TextStyle(color: Colors.grey))),
          const Divider(height: 1, indent: 56),
          const ListTile(
            leading: Icon(Icons.school_outlined, color: kPrimary),
            title: Text('Engineering Student Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Built for students, by students')),
        ])),
      ]),
    );
  }

  Widget _iconBox(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: color));

  // ════════════════════════════════════════════════════════════════
  // MEDIA BUNDLE EXPORT
  // Collects all files from note_attachments/ and zips them,
  // then shares the zip via share_plus.
  // ════════════════════════════════════════════════════════════════
  Future<void> _exportMediaBundle(BuildContext context) async {
    // Show progress dialog
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Zipping media files…'),
        ])));

    try {
      final storage = context.read<StorageService>();
      final appDir = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${appDir.path}/note_attachments');

      // Collect all attachment files referenced in notes
      final allAttachments = storage.notes
          .expand((n) => n.attachments)
          .toList();

      if (allAttachments.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context); // close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No media attachments found to export.')));
        }
        return;
      }

      // Build zip in memory
      final encoder = ZipFileEncoder();
      final tmpDir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipPath = '${tmpDir.path}/dashboard-media-$date.zip';
      encoder.create(zipPath);

      int count = 0;
      for (final att in allAttachments) {
        final f = File(att.localPath);
        if (await f.exists()) {
          // Store with a meaningful name: noteTitle_filename
          encoder.addFile(f, att.name.replaceAll(RegExp(r'[^\w\.\-]'), '_'));
          count++;
        }
      }
      encoder.close();

      if (context.mounted) Navigator.pop(context); // close progress dialog

      if (count == 0) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No media files found on device.')));
        return;
      }

      await Share.shareXFiles(
        [XFile(zipPath, mimeType: 'application/zip')],
        subject: 'Dashboard Media Backup ($count files)',
        text: 'My Dashboard – media backup $date\n$count attachment(s)');

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MEDIA BUNDLE IMPORT
  // User picks a .zip, files are extracted into note_attachments/.
  // Existing files with same name are overwritten.
  // ════════════════════════════════════════════════════════════════
  Future<void> _importMediaBundle(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['zip'], withData: false);
      if (result == null || result.files.isEmpty) return;
      final zipPath = result.files.first.path;
      if (zipPath == null) return;

      // Show progress
      if (!context.mounted) return;
      showDialog(context: context, barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Extracting media…'),
          ])));

      final appDir = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${appDir.path}/note_attachments');
      if (!await attachDir.exists()) await attachDir.create(recursive: true);

      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      int count = 0;
      for (final file in archive) {
        if (file.isFile) {
          final outPath = '${attachDir.path}/${file.name}';
          await File(outPath).writeAsBytes(file.content as List<int>);
          count++;
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Extracted $count file(s) to app storage.'),
          duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SECTION PICKER (shared by Export + Import)
  // ════════════════════════════════════════════════════════════════
  void _showSectionPicker(BuildContext context, {required bool isExport}) {
    final selected = <String>{..._kSections.keys};
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(children: [
            Text(isExport ? '📤 Export — Select Sections' : '📥 Import — Select Sections',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => ss(() => selected.length == _kSections.length ? selected.clear() : selected.addAll(_kSections.keys)),
              child: Text(selected.length == _kSections.length ? 'None' : 'All')),
          ])),
        const Divider(),
        ..._kSections.entries.map((e) => CheckboxListTile(
          value: selected.contains(e.key),
          title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
          activeColor: kPrimary,
          onChanged: (v) => ss(() => v! ? selected.add(e.key) : selected.remove(e.key)),
          controlAffinity: ListTileControlAffinity.leading)),
        const Divider(),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(width: double.infinity, child: GradientButton(
            label: isExport ? 'Continue to Export' : 'Continue to Import',
            icon: isExport ? Icons.upload : Icons.download,
            onPressed: selected.isEmpty ? () {} : () {
              Navigator.pop(ctx);
              if (isExport) _showExportOptions(context, selected);
              else _showImportOptions(context, selected);
            }))),
      ]))));
  }

  // ── Export options ──────────────────────────────────────────────
  void _showExportOptions(BuildContext context, Set<String> sections) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: _iconBox(Icons.share, kPrimary),
        title: const Text('Save / Share as JSON file'),
        subtitle: const Text('Save to Downloads or share via app'),
        onTap: () { Navigator.pop(context); _exportAsFile(context, sections); }),
      ListTile(
        leading: _iconBox(Icons.copy, kSecondary),
        title: const Text('Copy JSON to clipboard'),
        subtitle: const Text('Paste it anywhere manually'),
        onTap: () { Navigator.pop(context); _exportAsCopy(context, sections); }),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _exportAsFile(BuildContext context, Set<String> sections) async {
    final json = context.read<StorageService>().exportData(sections: sections);
    final suf = sections.length == _kSections.length ? 'full' : sections.join('-');
    final filename = 'dashboard-$suf-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], subject: 'Dashboard Backup');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }

  void _exportAsCopy(BuildContext context, Set<String> sections) {
    final json = context.read<StorageService>().exportData(sections: sections);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.copy, color: kPrimary), SizedBox(width: 8), Text('Copy JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${sections.length} section(s) selected:', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 150, child: TextField(
            controller: TextEditingController(text: json), maxLines: null, readOnly: true,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            decoration: const InputDecoration(border: OutlineInputBorder()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(icon: const Icon(Icons.copy), label: const Text('Copy All'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 2)));
          }),
      ]));
  }

  // ── Import options ──────────────────────────────────────────────
  void _showImportOptions(BuildContext context, Set<String> sections) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: _iconBox(Icons.folder_open, kPrimary),
        title: const Text('Pick JSON file'),
        subtitle: const Text('Browse and select your backup file'),
        onTap: () { Navigator.pop(context); _importFromFile(context, sections); }),
      ListTile(
        leading: _iconBox(Icons.paste, kSecondary),
        title: const Text('Paste JSON text'),
        subtitle: const Text('Paste copied backup text manually'),
        onTap: () { Navigator.pop(context); _importFromPaste(context, sections); }),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _importFromFile(BuildContext context, Set<String> sections) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String json;
      if (file.bytes != null) { json = String.fromCharCodes(file.bytes!); }
      else if (file.path != null) { json = await File(file.path!).readAsString(); }
      else { throw Exception('Could not read file'); }
      if (context.mounted) _confirmAndImport(context, json, sections);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  void _importFromPaste(BuildContext context, Set<String> sections) {
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
        ElevatedButton.icon(icon: const Icon(Icons.upload), label: const Text('Import'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            _confirmAndImport(context, ctrl.text.trim(), sections);
          }),
      ]));
  }

  void _confirmAndImport(BuildContext context, String json, Set<String> sections) {
    final sectionNames = sections.map((k) => _kSections[k]!).join('\n• ');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Confirm Import'),
      content: Text('This will overwrite:\n\n• $sectionNames\n\nAre you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            final result = context.read<StorageService>().importData(json, sections: sections);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result == 'success' ? '✅ Imported successfully!' : '❌ $result'),
                duration: const Duration(seconds: 3)));
          },
          child: const Text('Yes, overwrite')),
      ]));
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared.'), duration: Duration(seconds: 2)));
          },
          child: const Text('Delete Everything')),
      ]));
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)));
}
