import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A TextField that shows a dropdown of filtered suggestions as the user types.
/// Supports adding multiple items (comma-separated chips) or a single value.
class AutoSuggestField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> suggestions;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool multiSelect; // adds chip-style multi-select

  const AutoSuggestField({
    super.key,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.multiSelect = false,
  });

  @override
  State<AutoSuggestField> createState() => _AutoSuggestFieldState();
}

class _AutoSuggestFieldState extends State<AutoSuggestField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _filtered = [];
  bool _showDropdown = false;
  // For multi-select: each added item
  final List<String> _chips = [];

  @override
  void initState() {
    super.initState();
    if (widget.multiSelect) {
      _chips.addAll(
        widget.initialValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
      _controller = TextEditingController();
    } else {
      _controller = TextEditingController(text: widget.initialValue);
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showDropdown = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (!widget.multiSelect) {
      widget.onChanged(value);
    }
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filtered = [];
        _showDropdown = false;
      });
      return;
    }
    final results = widget.suggestions
        .where((s) => s.toLowerCase().contains(query))
        .take(6)
        .toList();
    setState(() {
      _filtered = results;
      _showDropdown = results.isNotEmpty;
    });
  }

  void _selectSuggestion(String item) {
    if (widget.multiSelect) {
      if (!_chips.contains(item)) {
        setState(() {
          _chips.add(item);
          _controller.clear();
          _showDropdown = false;
          _filtered = [];
        });
        widget.onChanged(_chips.join(', '));
      }
    } else {
      _controller.text = item;
      _controller.selection = TextSelection.collapsed(offset: item.length);
      setState(() => _showDropdown = false);
      widget.onChanged(item);
    }
    _focusNode.unfocus();
  }

  void _removeChip(String item) {
    setState(() => _chips.remove(item));
    widget.onChanged(_chips.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips row for multi-select
        if (widget.multiSelect && _chips.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _chips.map((chip) {
              return Chip(
                label: Text(chip, style: TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500),
                deleteIconColor: AppTheme.primary,
                onDeleted: () => _removeChip(chip),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          SizedBox(height: 8),
        ],

        // Input field
        Stack(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              maxLines: widget.multiSelect ? 1 : widget.maxLines,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
                        onPressed: () {
                          _controller.clear();
                          if (!widget.multiSelect) widget.onChanged('');
                          setState(() {
                            _filtered = [];
                            _showDropdown = false;
                          });
                        },
                      )
                    : Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),

        // Dropdown suggestions
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _filtered.asMap().entries.map((entry) {
                final isLast = entry.key == _filtered.length - 1;
                return InkWell(
                  onTap: () => _selectSuggestion(entry.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(bottom: BorderSide(color: AppTheme.actionButton)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_pharmacy_outlined,
                            size: 16, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.add, size: 16, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}


