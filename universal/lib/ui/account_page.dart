import 'package:flutter/material.dart';
import 'brand_mark.dart';
import 'page_frame.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'PVNetwork',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BrandMark(size: 96),
          const SizedBox(height: 16),
          Text('Guest mode', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Personal profiles work without an account.'),
          const SizedBox(height: 14),
          const Text('PVNetwork service synchronization is not configured in this development branch.'),
        ]),
      ),
    ),
  );
}
