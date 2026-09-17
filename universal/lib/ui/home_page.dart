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
          final state = controller.linkState;
          final stats = controller.stats;
          final adapter = controller.adapterFor(profile);

          final status = switch (state) {
            PVLinkState.disconnected => ('●  Not connected', Colors.transparent),
            PVLinkState.connecting => ('●  Connecting…', Colors.amber),
            PVLinkState.connected => ('●  Connected', Colors.green),
            PVLinkState.disconnecting => ('●  Disconnecting…', Colors.orange),
            PVLinkState.error => ('●  Connection error', Colors.red),
          };

          final card = Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: status.$2, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(status.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 20),
                const BrandMark(size: 148),
                const SizedBox(height: 16),
                Text(profile?.name ?? 'Choose a connection', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(profile?.endpoint ?? 'Import your own profile or use a PVNetwork service', textAlign: TextAlign.center),
                if (profile != null) ...[const SizedBox(height: 8), Wrap(spacing: 6, children: [Chip(label: Text(profile.protocol)), if (profile.transport != null) Chip(label: Text(profile.transport!)), if (profile.security != null && profile.security != 'none') Chip(label: Text(profile.security!.toUpperCase()))])],
                if (controller.lastError != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Expanded(child: Text(controller.lastError!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12))),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: controller.clearError,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: profile == null
                        ? openConnections
                        : controller.isBusy
                            ? null
                            : () => _toggle(context),
                    icon: Icon(switch (state) {
                      PVLinkState.connected => Icons.power_settings_new,
                      PVLinkState.connecting || PVLinkState.disconnecting => Icons.hourglass_top,
                      _ => Icons.hub,
                    }),
                    label: Text(switch (state) {
                      PVLinkState.connected => 'Disconnect',
                      PVLinkState.connecting => 'Connecting…',
                      PVLinkState.disconnecting => 'Disconnecting…',
                      PVLinkState.error => 'Retry',
                      _ => profile == null ? 'Select connection' : 'Connect',
                    }),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                  ),
                ),
              ]),
            ),
          );

          final info = Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                _line(Icons.dns_outlined, 'Server', profile?.endpoint ?? '—'),
                _line(Icons.security_outlined, 'Protocol', profile?.protocol ?? '—'),
                _line(Icons.speed, 'Latency', stats?.latencyMs != null && stats!.latencyMs! > 0 ? '${stats.latencyMs} ms' : '—'),
                _line(Icons.swap_vert, 'Traffic', stats == null ? '—' : '↑ ${humanBytes(stats.uploadBytes)}  ↓ ${humanBytes(stats.downloadBytes)}'),
                _line(Icons.public, 'Engine', adapter?.id ?? '—'),
              ]),
            ),
          );

          return LayoutBuilder(builder: (context, box) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Universal VPN & Proxy Client', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            if (box.maxWidth >= 760)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: card), const SizedBox(width: 18), Expanded(flex: 4, child: info)])
            else ...[card, const SizedBox(height: 14), info],
            const SizedBox(height: 22),
            Text('Quick actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              ActionChip(avatar: const Icon(Icons.add_link), label: const Text('Add connection'), onPressed: () => showAddConnection(context, controller)),
              ActionChip(avatar: const Icon(Icons.content_paste), label: const Text('Clipboard'), onPressed: () => importClipboard(context, controller)),
              ActionChip(avatar: const Icon(Icons.file_open), label: const Text('Import file'), onPressed: () => importFile(context, controller)),
            ]),
          ]));
        },
      );

  void _toggle(BuildContext context) {
    final profile = controller.selected;
    if (profile == null) return;
    if (controller.linkState == PVLinkState.connected) {
      controller.disconnect();
      return;
    }
    final adapter = controller.adapterFor(profile);
    if (adapter == null) {
      showEngineNotice(context, profile.engineRequirements['engine'] ?? profile.protocol);
      return;
    }
    controller.connect();
  }

  Widget _line(IconData icon, String name, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 10), Expanded(child: Text(name)), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}

String humanBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

void showEngineNotice(BuildContext context, String engine) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Engine not enabled yet'),
      content: Text(
          'This profile needs the "$engine" engine. PVNetwork currently serves VLESS, VMess, Trojan, Shadowsocks, SOCKS and HTTP through the first-party Xray core; other engines land as separate adapters.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
    ),
  );
}
