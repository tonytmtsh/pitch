import 'package:flutter/material.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key, required this.tableId, required this.name});

  final String tableId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: const Center(
        child: Text('Table (mock) — future work'),
      ),
    );
  }
}
