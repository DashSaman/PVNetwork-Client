import 'package:flutter/material.dart';
import 'brand_mark.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, required this.child, this.actions = const []});
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: Row(children: [const BrandMark(size: 42), const SizedBox(width: 12), Text(title)]),
            actions: actions,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: child),
              ),
            ),
          ),
        ],
      );
}
