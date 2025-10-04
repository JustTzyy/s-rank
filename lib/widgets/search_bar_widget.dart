import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  
  const SearchBarWidget({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search courses...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update when explicitly cleared (initialValue becomes empty)
    if (widget.initialValue != oldWidget.initialValue && 
        (widget.initialValue == null || widget.initialValue!.isEmpty)) {
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryPurple.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus 
              ? AppTheme.primaryPurple.withOpacity(0.4)
              : AppTheme.primaryPurple.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: _focusNode.hasFocus 
                  ? AppTheme.primaryPurple 
                  : AppTheme.textSecondary.withOpacity(0.6),
              size: 22,
            ),
          ),
          suffixIcon: _buildClearButton(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2C2C2C),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget? _buildClearButton() {
    if (_controller.text.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppTheme.textSecondary.withOpacity(0.8),
              size: 16,
            ),
          ),
          onPressed: _onClear,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          splashRadius: 16,
        ),
      );
    }

    return null;
  }
}
