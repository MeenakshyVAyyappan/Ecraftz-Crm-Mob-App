import 'package:flutter/material.dart';

/// Reusable refresh button for headers and toolbars with smooth rotation animation
/// and concurrency protection to prevent multiple simultaneous requests.
class AppRefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String tooltip;

  const AppRefreshButton({
    super.key,
    required this.onRefresh,
    this.tooltip = 'Refresh page data',
  });

  @override
  State<AppRefreshButton> createState() => _AppRefreshButtonState();
}

class _AppRefreshButtonState extends State<AppRefreshButton>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
    });
    _controller.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRefreshing ? null : _handleRefresh,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2E42)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            child: RotationTransition(
              turns: _controller,
              child: SizedBox(
                width: 18,
                height: 18,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _isRefreshing
                      ? const Color(0xFF0A84FF)
                      : (isDark ? const Color(0xFFCDD6F4) : const Color(0xFF6B7A99)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
