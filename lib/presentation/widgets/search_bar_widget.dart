import 'package:flutter/material.dart';

/// شريط بحث زجاجي
class SearchBarWidget extends StatelessWidget {
  final Function(String query) onSearch;
  final String? initialValue;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'بحث عن صورة...',
        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
      onChanged: onSearch,
    );
  }
}
