import 'package:flutter/material.dart';

/// Helper utility for consistent Toast / SnackBar display across the application.
class AppSnackBar {
  static String? _lastMessage;
  static DateTime? _lastShownTime;

  /// Default toast duration of 2 seconds
  static const Duration defaultDuration = Duration(seconds: 2);

  /// Sanitizes technical network error strings into short, clear, user-friendly messages.
  static String sanitizeNetworkError(String rawText) {
    if (rawText.isEmpty) return rawText;
    final lower = rawText.toLowerCase();

    // 1. Timeout / Request took too long
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('took too long') ||
        lower.contains('deadline_exceeded')) {
      return 'The request took too long. Please check your connection and try again.';
    }

    // 2. Weak / unstable network
    if (lower.contains('weak connection') ||
        lower.contains('slow connection') ||
        lower.contains('network_changed') ||
        lower.contains('connection reset') ||
        lower.contains('connection abort') ||
        lower.contains('peer reset') ||
        lower.contains('network is unstable')) {
      return 'Your internet connection is weak. Please try again when the network is stable.';
    }

    // 3. No internet connection (DNS lookup failure, unreachable, offline, disconnected)
    if (lower.contains('failed host lookup') ||
        lower.contains('no address associated') ||
        lower.contains('network is unreachable') ||
        lower.contains('err_internet_disconnected') ||
        lower.contains('err_name_not_resolved') ||
        lower.contains('socketexception') ||
        lower.contains('offline') ||
        lower.contains('no internet')) {
      return 'No internet connection. Please check your Wi-Fi or mobile data and try again.';
    }

    // 4. Unable to connect to server (ClientException, connection refused, handshake, http error, xmlhttprequest, failed to fetch)
    if (lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('handshakeexception') ||
        lower.contains('httpexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('failed to connect') ||
        lower.contains('unable to connect') ||
        lower.contains('failed to fetch') ||
        lower.contains('networkerror') ||
        lower.contains('network error')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    return rawText;
  }

  /// Checks whether a given message string represents a technical network error.
  static bool isNetworkError(String rawText) {
    final sanitized = sanitizeNetworkError(rawText);
    return sanitized != rawText;
  }

  /// Shows a SnackBar with a default 2-second duration.
  /// Dismisses any currently visible SnackBar prior to showing a new one.
  /// Prevents displaying duplicate consecutive messages within a 2-second window.
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    Duration duration = defaultDuration,
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
  }) {
    if (!context.mounted) return;

    final sanitized = sanitizeNetworkError(message).trim();
    if (sanitized.isEmpty) return;

    final now = DateTime.now();
    // Prevent duplicate repeated messages within 2 seconds
    if (_lastMessage == sanitized &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!) < defaultDuration) {
      return;
    }

    _lastMessage = sanitized;
    _lastShownTime = now;

    // Use error background color for sanitized network errors if none specified
    final effectiveBg = backgroundColor ??
        (isNetworkError(message) ? const Color(0xFFFF453A) : null);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(sanitized),
        backgroundColor: effectiveBg,
        behavior: behavior,
        duration: duration,
        action: action,
        margin: margin,
      ),
    );
  }

  /// Displays a custom SnackBar object with duration set to 2s by default,
  /// clearing active snackbars, sanitizing technical network errors, and preventing rapid duplicates.
  static void showCustom(BuildContext context, SnackBar snackBar) {
    if (!context.mounted) return;

    String origText = '';
    if (snackBar.content is Text) {
      origText = (snackBar.content as Text).data ?? '';
    }

    final sanitizedText = sanitizeNetworkError(origText);
    final isNetErr = isNetworkError(origText);

    final now = DateTime.now();
    if (sanitizedText.isNotEmpty &&
        _lastMessage == sanitizedText &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!) < defaultDuration) {
      return;
    }

    if (sanitizedText.isNotEmpty) {
      _lastMessage = sanitizedText;
      _lastShownTime = now;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final duration = (snackBar.duration == const Duration(milliseconds: 4000) ||
            snackBar.duration == const Duration(seconds: 1) ||
            snackBar.duration == const Duration(seconds: 2))
        ? defaultDuration
        : snackBar.duration;

    final Widget content = (origText != sanitizedText && origText.isNotEmpty)
        ? Text(sanitizedText)
        : snackBar.content;

    final Color? effectiveBg = isNetErr && snackBar.backgroundColor == null
        ? const Color(0xFFFF453A)
        : snackBar.backgroundColor;

    messenger.showSnackBar(
      SnackBar(
        key: snackBar.key,
        content: content,
        backgroundColor: effectiveBg,
        elevation: snackBar.elevation,
        margin: snackBar.margin,
        padding: snackBar.padding,
        width: snackBar.width,
        shape: snackBar.shape,
        hitTestBehavior: snackBar.hitTestBehavior,
        behavior: snackBar.behavior ?? SnackBarBehavior.floating,
        action: snackBar.action,
        actionOverflowThreshold: snackBar.actionOverflowThreshold,
        showCloseIcon: snackBar.showCloseIcon,
        closeIconColor: snackBar.closeIconColor,
        duration: duration,
        onVisible: snackBar.onVisible,
        dismissDirection: snackBar.dismissDirection,
        clipBehavior: snackBar.clipBehavior,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message, {SnackBarAction? action}) {
    show(context, message, backgroundColor: const Color(0xFF00C896), action: action);
  }

  static void showError(BuildContext context, String message, {SnackBarAction? action}) {
    show(context, message, backgroundColor: const Color(0xFFFF453A), action: action);
  }

  static void showWarning(BuildContext context, String message, {SnackBarAction? action}) {
    show(context, message, backgroundColor: const Color(0xFFFF9F0A), action: action);
  }

  static void showInfo(BuildContext context, String message, {SnackBarAction? action}) {
    show(context, message, backgroundColor: const Color(0xFF32ADE6), action: action);
  }
}
