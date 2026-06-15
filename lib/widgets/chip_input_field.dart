import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChipInputField extends StatefulWidget {
  final List<String> suggestions;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const ChipInputField({
    super.key,
    required this.suggestions,
    required this.selectedItems,
    required this.onChanged,
    required this.label,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onTextChanged() {
    _filterSuggestions();
    _overlayEntry?.markNeedsBuild();
  }

  void _filterSuggestions() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) {
      _filteredSuggestions = widget.suggestions
          .where((s) => !widget.selectedItems.contains(s))
          .take(6)
          .toList();
    } else {
      _filteredSuggestions = widget.suggestions
          .where((s) => s.toLowerCase().contains(text) && !widget.selectedItems.contains(s))
          .take(6)
          .toList();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _focusNode.unfocus();
              },
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 4.0),
              child: Material(
                elevation: 4,
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      ..._filteredSuggestions.map((suggestion) {
                        return InkWell(
                          onTap: () => _addItem(suggestion),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_controller.text.trim().isNotEmpty &&
                          !_filteredSuggestions.any((s) => s.toLowerCase() == _controller.text.trim().toLowerCase()) &&
                          !widget.selectedItems.any((s) => s.toLowerCase() == _controller.text.trim().toLowerCase()))
                        InkWell(
                          onTap: () => _addItem(_controller.text.trim()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add "${_controller.text.trim()}"',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem(String item) {
    if (!widget.selectedItems.contains(item)) {
      final newList = List<String>.from(widget.selectedItems)..add(item);
      widget.onChanged(newList);
    }
    _controller.clear();
    _focusNode.unfocus();
  }

  void _removeItem(String item) {
    final newList = List<String>.from(widget.selectedItems)..remove(item);
    widget.onChanged(newList);
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.label,
              prefixIcon: const Icon(Icons.search, size: 20),
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
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (widget.selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.selectedItems.map((item) {
                return Chip(
                  label: Text(item, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  deleteIconColor: AppTheme.primary,
                  onDeleted: () => _removeItem(item),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
