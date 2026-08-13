import 'package:flutter/material.dart';
import 'page_frame.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Store',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: const [
          Icon(Icons.storefront_outlined, size: 60),
          SizedBox(height: 14),
          Text('PVNetwork services'),
          SizedBox(height: 8),
          Text('Service catalog is not configured in this development branch.'),
        ]),
      ),
    ),
  );
}
