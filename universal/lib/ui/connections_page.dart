import 'package:flutter/material.dart';
import '../controller.dart';
import 'add_connection.dart';
import 'page_frame.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key, required this.controller});
  final PVController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => PageFrame(
          title: 'Connections',
          actions: [IconButton(onPressed: () => showAddConnection(context, controller), icon: const Icon(Icons.add_circle_outline), tooltip: 'Add connection')],
          child: controller.profiles.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      const Icon(Icons.hub_outlined, size: 58),
                      const SizedBox(height: 14),
                      Text('No connections yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('Import a personal profile or use PVNetwork account synchronization later.', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton.icon(onPressed: () => showAddConnection(context, controller), icon: const Icon(Icons.add), label: const Text('Add connection')),
                    ]),
                  ),
                )
              : Column(
                  children: controller.profiles.map((profile) {
                    final active = profile.id == controller.selectedId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          leading: CircleAvatar(
                            backgroundColor: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.router_outlined, color: active ? Theme.of(context).colorScheme.onPrimary : null),
                          ),
                          title: Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${profile.protocol}${profile.endpoint == null ? '' : '  •  ${profile.endpoint}'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (active) const Chip(label: Text('Active')),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'use') controller.select(profile.id);
                                if (value == 'delete') controller.remove(profile.id);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'use', child: Text('Use')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ]),
                          onTap: () => controller.select(profile.id),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      );
}
