import 'package:flutter/material.dart';

/// The single search-input shape used by every searchable list (VPS §2,
/// design principle #6 — "every list of >5 items supports search").
final class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: hintText,
      leading: const Icon(Icons.search),
      trailing: controller == null
          ? null
          : [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller!.clear();
                          onChanged('');
                        },
                      ),
              ),
            ],
      onChanged: onChanged,
    );
  }
}
