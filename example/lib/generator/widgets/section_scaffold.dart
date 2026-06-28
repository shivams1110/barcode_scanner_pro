import 'package:flutter/material.dart';

class SectionScaffold extends StatelessWidget {
  const SectionScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}
