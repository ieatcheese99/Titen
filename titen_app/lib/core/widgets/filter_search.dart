import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// M08 FilterSearch — Search and filter input component per 03_APP_FLUTTER_SPEC.md §5
class FilterSearch extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const FilterSearch({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Cari node berdasarkan nama atau ID (contoh: 01)...',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextField(
        controller: TextEditingController(text: query)..selection = TextSelection.collapsed(offset: query.length),
        onChanged: onChanged,
        style: TitenTypography.body(color: tokens.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.search, size: 20, color: tokens.textMetadata),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: tokens.textMetadata),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}
