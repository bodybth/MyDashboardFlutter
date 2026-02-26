import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

// ════════════════════════════════════════════════════════════════════
// LIBRARY SCREEN – grid of section tiles (Formulas, Notes, custom…)
// ════════════════════════════════════════════════════════════════════
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
    [Color(0xFF30cfd0), Color(0xFF667EEA)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📚 Library',
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.add), tooltip: 'New Section', onPressed: () => _addSection(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.notebooks.isEmpty) {
            return const Center(child: Text('Tap + to add a section', style: TextStyle(color: Colors.grey, fontSize: 16)));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1),
              itemCount: storage.notebooks.length,
              itemBuilder: (ctx, i) {
                final nb = storage.notebooks[i];
                final grad = _gradients[nb.id.hashCode.abs() % _gradients.length];
                final count = nb.type == 'formulas' ? storage.formulas.length : storage.notesForNotebook(nb.id).length;
                return _SectionTile(notebook: nb, grad: grad, count: count);
              },
            ),
          );
        },
      ),
    );
  }

  void _addSection(BuildContext context) {
    final ctrl = TextEditingController();
    String emoji = '📓';
    final emojis = ['📓','📐','📝','📧','🔬','💡','🧪','🔧','📊','🗂️','📌','🧲','⚗️','📡','🌐','🔑','📎','🖊️','💼','🗒️'];
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('New Section', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(height: 52, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: emojis.length,
            itemBuilder: (_, idx) => GestureDetector(
              onTap: () => ss(() => emoji = emojis[idx]),
              child: Container(width: 44, height: 44, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: emoji == emojis[idx] ? kPrimary.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: emoji == emojis[idx] ? Border.all(color: kPrimary, width: 2) : null),
                alignment: Alignment.center, child: Text(emojis[idx], style: const TextStyle(fontSize: 22)))))),
          const SizedBox(height: 12),
          TextField(controller: ctrl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Section Title *', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(label: 'Create', icon: Icons.add,
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              context.read<StorageService>().addNotebook(Notebook(title: ctrl.text.trim(), emoji: emoji, type: 'notes'));
              Navigator.pop(ctx);
            })),
        ]))));
  }
}

// ── Section tile card ─────────────────────────────────────────────
class _SectionTile extends StatelessWidget {
  final Notebook notebook;
  final List<Color> grad;
  final int count;
  const _SectionTile({required this.notebook, required this.grad, required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _options(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: grad[0].withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(notebook.emoji, style: const TextStyle(fontSize: 32)),
              GestureDetector(onTap: () => _options(context),
                  child: const Icon(Icons.more_vert, color: Colors.white70, size: 20)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notebook.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$count item${count == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (notebook.type == 'formulas') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FormulasDetailPage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NotesDetailPage(notebook: notebook)));
    }
  }

  void _options(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit_outlined, color: kPrimary), title: const Text('Rename'),
          onTap: () { Navigator.pop(ctx); _rename(context); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete Section', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); _confirmDelete(context); }),
    ])));
  }

  void _rename(BuildContext context) {
    final ctrl = TextEditingController(text: notebook.title);
    showDialog(context: context, builder: (d) => AlertDialog(
      title: const Text('Rename Section'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder()), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              context.read<StorageService>().updateNotebook(Notebook(id: notebook.id, title: ctrl.text.trim(), emoji: notebook.emoji, type: notebook.type, createdAt: notebook.createdAt));
            }
            Navigator.pop(d);
          }, child: const Text('Save')),
      ]));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (d) => AlertDialog(
      title: const Text('Delete Section'),
      content: Text('Delete "${notebook.title}"? All items inside will be deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () { Navigator.pop(d); context.read<StorageService>().deleteNotebook(notebook.id); },
          child: const Text('Delete')),
      ]));
  }
}

// ════════════════════════════════════════════════════════════════════
// NOTES DETAIL PAGE  (for Notes-type notebooks)
// ════════════════════════════════════════════════════════════════════
class NotesDetailPage extends StatelessWidget {
  final Notebook notebook;
  const NotesDetailPage({super.key, required this.notebook});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '${notebook.emoji} ${notebook.title}',
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final items = storage.notesForNotebook(notebook.id);
          if (items.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notes_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No items yet\nTap + to add one', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _NoteCard(note: items[i], notebookId: notebook.id),
          );
        },
      ),
    );
  }

  void _showEditor(BuildContext context, [Note? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'New Item' : 'Edit Item', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 6,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder(), alignLabelWithHint: true)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add' : 'Save Changes',
            icon: existing == null ? Icons.add : Icons.save,
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final s = context.read<StorageService>();
              final note = Note(id: existing?.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: notebook.id);
              if (existing == null) s.addNote(note); else s.updateNote(note);
              Navigator.pop(ctx);
            })),
        ]))));
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final String notebookId;
  const _NoteCard({required this.note, required this.notebookId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _detail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _edit(context)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => context.read<StorageService>().deleteNote(note.id)),
            ]),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Text(DateFormat('MMM dd, yyyy').format(note.date), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  void _detail(BuildContext context) {
    showDialog(context: context, builder: (d) => AlertDialog(
      title: Text(note.title),
      content: SingleChildScrollView(child: Text(note.content.isEmpty ? '(empty)' : note.content)),
      actions: [
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: '${note.title}\n\n${note.content}')); Navigator.pop(d); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1))); }, child: const Text('Copy')),
        TextButton(onPressed: () { Navigator.pop(d); _edit(context); }, child: const Text('Edit')),
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close')),
      ]));
  }

  void _edit(BuildContext context) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Edit Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 6,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder(), alignLabelWithHint: true)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(label: 'Save Changes', icon: Icons.save,
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              context.read<StorageService>().updateNote(Note(id: note.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: notebookId));
              Navigator.pop(ctx);
            })),
        ]))));
  }
}

// ════════════════════════════════════════════════════════════════════
// FORMULAS DETAIL PAGE  (full formulas experience inside library)
// ════════════════════════════════════════════════════════════════════
class FormulasDetailPage extends StatefulWidget {
  const FormulasDetailPage({super.key});
  @override State<FormulasDetailPage> createState() => _FormulasDetailPageState();
}

class _FormulasDetailPageState extends State<FormulasDetailPage> {
  String _search = '';
  String? _selCat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📐 Formulas',
        actions: <Widget>[
          Consumer<StorageService>(builder: (_, storage, __) => IconButton(
            icon: const Icon(Icons.category_outlined), tooltip: 'Categories',
            onPressed: () => showCategoryManager(context: context, title: 'Formula Categories',
              categories: storage.formulaCategories,
              onAdd: (c) => storage.addFormulaCategory(c),
              onDelete: (id) => storage.deleteFormulaCategory(id)))),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset', onPressed: () => _reset(context)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _editor(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final catMap = {for (final c in storage.formulaCategories) c.id: c};
          final filtered = storage.formulas.where((f) {
            final mc = _selCat == null || f.category == _selCat;
            final ms = _search.isEmpty || f.name.toLowerCase().contains(_search) || f.formula.toLowerCase().contains(_search) || f.desc.toLowerCase().contains(_search);
            return mc && ms;
          }).toList();
          final grouped = <String, List<Formula>>{};
          for (final f in filtered) grouped.putIfAbsent(f.category, () => []).add(f);

          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(hintText: 'Search formulas…', prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10)))),
            SizedBox(height: 50,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _chip(null, '🔍 All', storage),
                  ...storage.formulaCategories.map((c) => _chip(c.id, '${c.emoji} ${c.name}', storage)),
                ])),
            Expanded(child: grouped.isEmpty
              ? const Center(child: Text('No formulas found', style: TextStyle(color: Colors.grey)))
              : ListView(padding: const EdgeInsets.all(12), children: grouped.entries.map((e) {
                  final cat = catMap[e.key];
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${cat?.emoji ?? '📐'} ${cat?.name ?? e.key}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPrimary))),
                    ...e.value.map((f) => _FormulaCard(formula: f,
                        onEdit: () => _editor(context, f),
                        onDelete: () => context.read<StorageService>().deleteFormula(f.id))),
                  ]);
                }).toList())),
          ]);
        },
      ),
    );
  }

  Widget _chip(String? id, String label, StorageService storage) {
    final sel = _selCat == id;
    return Padding(padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: sel, onSelected: (_) => setState(() => _selCat = id),
        selectedColor: kPrimary, labelStyle: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w500)));
  }

  void _reset(BuildContext context) => showDialog(context: context, builder: (d) => AlertDialog(
    title: const Text('Reset Formulas'), content: const Text('Restore defaults and remove custom formulas?'),
    actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
        onPressed: () { Navigator.pop(d); context.read<StorageService>().resetFormulas(); }, child: const Text('Reset'))]));

  void _editor(BuildContext context, [Formula? existing]) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final formulaCtrl = TextEditingController(text: existing?.formula ?? '');
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    String category = existing?.category ?? (storage.formulaCategories.isNotEmpty ? storage.formulaCategories.first.id : '');

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Formula' : 'Edit Formula', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: formulaCtrl, decoration: const InputDecoration(labelText: 'Formula *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Consumer<StorageService>(builder: (_, s, __) => DropdownButtonFormField<String>(
            value: s.formulaCategories.any((c) => c.id == category) ? category : (s.formulaCategories.isNotEmpty ? s.formulaCategories.first.id : null),
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: s.formulaCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
            onChanged: (v) => ss(() => category = v!))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Formula' : 'Save Changes',
            icon: existing == null ? Icons.add : Icons.save,
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || formulaCtrl.text.trim().isEmpty) return;
              final f = Formula(id: existing?.id, name: nameCtrl.text.trim(), formula: formulaCtrl.text.trim(), desc: descCtrl.text.trim(), category: category, isCustom: true);
              final s = context.read<StorageService>();
              if (existing == null) s.addFormula(f); else s.updateFormula(f);
              Navigator.pop(ctx);
            })),
        ])))));
  }
}

class _FormulaCard extends StatelessWidget {
  final Formula formula;
  final VoidCallback onEdit, onDelete;
  const _FormulaCard({required this.formula, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(formula.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(formula.formula, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (formula.desc.isNotEmpty) Text(formula.desc, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(children: [
              TextButton.icon(icon: const Icon(Icons.copy, size: 16), label: const Text('Copy'),
                onPressed: () { Clipboard.setData(ClipboardData(text: '${formula.name}: ${formula.formula}')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1))); }),
              TextButton.icon(icon: const Icon(Icons.edit_outlined, size: 16, color: kPrimary), label: const Text('Edit', style: TextStyle(color: kPrimary)), onPressed: onEdit),
              if (formula.isCustom) TextButton.icon(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red)), onPressed: onDelete),
            ]),
          ]))]));
  }
}
