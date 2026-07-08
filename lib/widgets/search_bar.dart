import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const AppSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Cari gym di Surabaya...',
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
