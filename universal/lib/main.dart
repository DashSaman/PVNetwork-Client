import 'package:flutter/material.dart';

void main() => runApp(const PVNetworkApp());

class PVNetworkApp extends StatelessWidget {
  const PVNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PVNetwork VPN',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF2A900),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08090B),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF08090B),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFFF2A900)),
            SizedBox(width: 10),
            Text('PVNetwork VPN', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, size: 120, color: Color(0xFFF2A900)),
                const SizedBox(height: 18),
                const Text('PVNetwork', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Universal VPN Client', style: TextStyle(color: Colors.white60, fontSize: 16)),
                const SizedBox(height: 34),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15171C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      Text('Not connected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 22),
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Color(0xFFF2A900),
                        child: Icon(Icons.power_settings_new_rounded, size: 48, color: Colors.black),
                      ),
                      SizedBox(height: 22),
                      Text(
                        'PVNetwork cross-platform foundation build',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Android • Windows • Linux • macOS • iOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFF2A900), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'English • فارسی • العربية • Türkçe • Русский • 中文 • Español • Français • Deutsch',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
