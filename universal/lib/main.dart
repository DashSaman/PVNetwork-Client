import 'package:flutter/material.dart';
import 'controller.dart';
import 'core/storage/profile_repository.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final c = PVController(ProfileRepository());
  await c.load();
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: AppShell(controller: c)));
}
