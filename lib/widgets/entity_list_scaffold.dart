import 'package:flutter/material.dart';

class EntityListScaffold extends StatelessWidget {
  const EntityListScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onRefresh,
    required this.onAdd,
    required this.emptyText,
    required this.isEmpty,
    required this.children,
    this.errorMessage,
    this.header,
  });

  final String title;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final String emptyText;
  final bool isEmpty;
  final List<Widget> children;
  final String? errorMessage;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (header != null) ...[header!, const SizedBox(height: 12)],
                  if (errorMessage != null) Text(errorMessage!),
                  if (isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(emptyText)),
                    )
                  else
                    ...children,
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}
