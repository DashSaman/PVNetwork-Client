import 'package:flutter/material.dart';
import '../controller.dart';
import 'page_frame.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});
  final PVController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String language = 'system';
  ThemeMode theme = ThemeMode.system;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Settings',
    child: Column(children: [
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English and Persian are the first production languages'),
            trailing: DropdownButton<String>(
              value: language,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fa', child: Text('فارسی')),
              ],
              onChanged: (v) => setState(() => language = v ?? 'system'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.contrast),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: theme,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              ],
              onChanged: (v) => setState(() => theme = v ?? ThemeMode.system),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      const Card(
        child: Column(children: [
          ListTile(leading: Icon(Icons.route_outlined), title: Text('Routing'), subtitle: Text('Global, rule-based, direct, smart and split-tunnel controls')), 
          Divider(height: 1),
          ListTile(leading: Icon(Icons.dns_outlined), title: Text('DNS'), subtitle: Text('System, custom, DoH, DoT and split-DNS after core integration')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.shield_outlined), title: Text('Kill switch'), subtitle: Text('Will only be enabled after leak tests pass')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.article_outlined), title: Text('Logs & diagnostics'), subtitle: Text('Sensitive values will be redacted')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.info_outline), title: Text('About & licenses'), subtitle: Text('PVNetwork 0.3 development')),
        ]),
      ),
    ]),
  );
}
