import 'package:flutter/material.dart';
import '../controller.dart';
import 'account_page.dart';
import 'connections_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'store_page.dart';
import 'brand_mark.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final PVController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      HomePage(controller: widget.controller, openConnections: () => setState(() => index = 1)),
      ConnectionsPage(controller: widget.controller),
      const AccountPage(),
      const StorePage(),
      SettingsPage(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(children: [
                NavigationRail(
                  selectedIndex: index,
                  extended: MediaQuery.sizeOf(context).width >= 1180,
                  onDestinationSelected: (value) => setState(() => index = value),
                  leading: const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: BrandMark(size: 72)),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: Text('Connections')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('PVNetwork')),
                    NavigationRailDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: Text('Store')),
                    NavigationRailDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[index]),
              ])
            : pages[index],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Connections'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'PVNetwork'),
                NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Store'),
                NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Settings'),
              ],
            ),
    );
  }
}
