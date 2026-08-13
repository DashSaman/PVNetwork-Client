import 'package:flutter/material.dart';
import '../controller.dart';
import 'add_connection.dart';
import 'brand_mark.dart';
import 'page_frame.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller, required this.openConnections});
  final PVController controller;
  final VoidCallback openConnections;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final profile = controller.selected;
          return PageFrame(
            title: 'PVNetwork',
            child: LayoutBuilder(builder: (context, box) {
              final card = Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('●  Not connected', style: TextStyle(fontWeight: FontWeight.w800))),
                    const SizedBox(height: 20),
                    const BrandMark(size: 148),
                    const SizedBox(height: 16),
                    Text(profile?.name ?? 'Choose a connection', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(profile?.endpoint ?? 'Import your own profile or use a PVNetwork service', textAlign: TextAlign.center),
                    if (profile != null) ...[const SizedBox(height: 8), Chip(label: Text(profile.protocol))],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: profile == null ? openConnections : () => showEngineNotice(context),
                        icon: Icon(profile == null ? Icons.hub : Icons.power_settings_new),
                        label: Text(profile == null ? 'Select connection' : 'Connect'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      ),
                    ),
                  ]),
                ),
              );
              final stats = Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    _line(Icons.dns_outlined, 'Server', profile?.endpoint ?? '—'),
                    _line(Icons.security_outlined, 'Protocol', profile?.protocol ?? '—'),
                    _line(Icons.speed, 'Latency', '—'),
                    _line(Icons.swap_vert, 'Traffic', '—'),
                    _line(Icons.public, 'Public IP', '—'),
                  ]),
                ),
              );
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Universal VPN & Proxy Client', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),
                if (box.maxWidth >= 760)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: card), const SizedBox(width: 18), Expanded(flex: 4, child: stats)])
                else ...[card, const SizedBox(height: 14), stats],
                const SizedBox(height: 22),
                Text('Quick actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  ActionChip(avatar: const Icon(Icons.add_link), label: const Text('Add connection'), onPressed: () => showAddConnection(context, controller)),
                  ActionChip(avatar: const Icon(Icons.content_paste), label: const Text('Clipboard'), onPressed: () => importClipboard(context, controller)),
                  ActionChip(avatar: const Icon(Icons.file_open), label: const Text('Import file'), onPressed: () => importFile(context, controller)),
                ]),
              ]);
            }),
          );
        },
      );

  Widget _line(IconData icon, String name, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 10), Expanded(child: Text(name)), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}

void showEngineNotice(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Connection engine pending'),
      content: const Text('Connect stays unavailable until the first real core adapter passes a live tunnel test.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
    ),
  );
}
