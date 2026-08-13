import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller.dart';

Future<void> showAddConnection(BuildContext context, PVController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add connection', style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Tile(Icons.content_paste, 'Paste from clipboard', 'VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC and more', () async {
            Navigator.pop(sheetContext);
            await importClipboard(context, controller);
          }),
          _Tile(Icons.file_open, 'Import file', 'OpenVPN .ovpn, WireGuard .conf, JSON, YAML or text', () async {
            Navigator.pop(sheetContext);
            await importFile(context, controller);
          }),
          _Tile(Icons.link, 'Subscription URL', 'Add a remote profile or node-list URL', () {
            Navigator.pop(sheetContext);
            showSubscriptionDialog(context, controller);
          }),
          _Tile(Icons.edit_note, 'Manual configuration', 'Paste or type a complete configuration', () {
            Navigator.pop(sheetContext);
            showManualDialog(context, controller);
          }),
          _Tile(Icons.qr_code_scanner, 'Scan QR', 'Camera scanner follows the platform permission milestone', () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR camera adapter is not enabled in this development build yet.')));
          }),
        ]),
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

Future<void> importClipboard(BuildContext context, PVController controller) async {
  try {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (value.isEmpty) throw const FormatException('Clipboard does not contain configuration text.');
    await controller.addRaw(value, source: 'clipboard');
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection imported.')));
  } catch (error) {
    if (context.mounted) _error(context, error);
  }
}

Future<void> importFile(BuildContext context, PVController controller) async {
  try {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ovpn', 'conf', 'json', 'yaml', 'yml', 'txt'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) throw const FormatException('The selected file path is unavailable.');
    final raw = await File(path).readAsString();
    if (raw.trim().isEmpty) throw const FormatException('The selected file is empty or unreadable.');
    await controller.addRaw(raw, source: 'file:${file.extension ?? 'unknown'}');
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File imported.')));
  } catch (error) {
    if (context.mounted) _error(context, error);
  }
}

Future<void> showManualDialog(BuildContext context, PVController controller) async {
  final field = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Manual configuration'),
      content: SizedBox(width: 640, child: TextField(controller: field, minLines: 8, maxLines: 18, autocorrect: false, decoration: const InputDecoration(hintText: 'Paste the complete configuration here'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            await controller.addRaw(field.text, source: 'manual');
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (dialogContext.mounted) _error(dialogContext, error);
          }
        }, child: const Text('Import')),
      ],
    ),
  );
  field.dispose();
}

Future<void> showSubscriptionDialog(BuildContext context, PVController controller) async {
  final field = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Subscription URL'),
      content: SizedBox(width: 560, child: TextField(controller: field, keyboardType: TextInputType.url, autocorrect: false, decoration: const InputDecoration(prefixIcon: Icon(Icons.link), hintText: 'https://...'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            final uri = Uri.tryParse(field.text.trim());
            if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) throw const FormatException('Enter a valid HTTP/HTTPS URL.');
            await controller.addRaw(uri.toString(), source: 'subscription');
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (dialogContext.mounted) _error(dialogContext, error);
          }
        }, child: const Text('Save')),
      ],
    ),
  );
  field.dispose();
}

void _error(BuildContext context, Object error) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Import failed'),
      content: Text(error.toString()),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
    ),
  );
}
