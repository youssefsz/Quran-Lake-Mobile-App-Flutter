import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A beautiful, reusable error widget that shows a friendly illustration,
/// a localized title and subtitle, and an optional retry button.
///
/// Usage:
/// ```dart
/// AppErrorWidget(
///   errorType: AppErrorType.noInternet,
///   translations: _translations,
///   onRetry: () => provider.fetchData(),
///   compact: false, // full-page mode
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  /// The classified error type to display.
  final AppErrorType errorType;

  /// The screen's translation map (must contain the error keys).
  /// Falls back to English defaults when keys are missing.
  final Map<String, dynamic> translations;

  /// Called when the user taps the retry button. If null, no button is shown.
  final VoidCallback? onRetry;

  /// If true, renders a smaller inline card (e.g. inside a section).
  /// If false, renders a centered full-screen placeholder.
  final bool compact;

  const AppErrorWidget({
    super.key,
    required this.errorType,
    this.translations = const {},
    this.onRetry,
    this.compact = false,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _t(String key, String fallback) {
    final value = translations[key];
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  _ErrorDisplayData _displayData() {
    switch (errorType) {
      case AppErrorType.noInternet:
        return _ErrorDisplayData(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.neutral500,
          title: _t('error_no_internet_title', 'No Internet Connection'),
          subtitle: _t(
            'error_no_internet_subtitle',
            'Please check your Wi-Fi or mobile data and try again.',
          ),
        );
      case AppErrorType.timeout:
        return _ErrorDisplayData(
          icon: Icons.hourglass_empty_rounded,
          iconColor: AppColors.warning,
          title: _t('error_timeout_title', 'Connection Timed Out'),
          subtitle: _t(
            'error_timeout_subtitle',
            'The server is taking too long to respond. Please try again.',
          ),
        );
      case AppErrorType.serverUnreachable:
        return _ErrorDisplayData(
          icon: Icons.cloud_off_rounded,
          iconColor: AppColors.neutral500,
          title: _t('error_server_title', 'Server Unavailable'),
          subtitle: _t(
            'error_server_subtitle',
            'We could not reach the server. Please try again later.',
          ),
        );
      case AppErrorType.serverError:
        return _ErrorDisplayData(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: _t('error_server_error_title', 'Something Went Wrong'),
          subtitle: _t(
            'error_server_error_subtitle',
            'An unexpected error occurred on the server. Please try again.',
          ),
        );
      case AppErrorType.locationError:
        return _ErrorDisplayData(
          icon: Icons.location_off_rounded,
          iconColor: AppColors.warning,
          title: _t('error_location_title', 'Location Unavailable'),
          subtitle: _t(
            'error_location_subtitle',
            'Please enable location services and grant permission to the app.',
          ),
        );
      case AppErrorType.unknown:
        return _ErrorDisplayData(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.neutral500,
          title: _t('error_unknown_title', 'Oops!'),
          subtitle: _t(
            'error_unknown_subtitle',
            'Something unexpected happened. Please try again.',
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFullPage(context);
  }

  /// Inline / card-style error for embedding inside a section.
  Widget _buildCompact(BuildContext context) {
    final data = _displayData();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconCircle(data, size: 48, iconSize: 24),
          const SizedBox(height: 14),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            _buildRetryButton(context, small: true),
          ],
        ],
      ),
    );
  }

  /// Full-page centered error placeholder.
  Widget _buildFullPage(BuildContext context) {
    final data = _displayData();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconCircle(data, size: 80, iconSize: 40),
            const SizedBox(height: 24),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              _buildRetryButton(context, small: false),
            ],
          ],
        ),
      ),
    );
  }

  /// Soft pastel circle behind the icon.
  Widget _buildIconCircle(
    _ErrorDisplayData data, {
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.iconColor.withValues(alpha: 0.1),
      ),
      child: Icon(data.icon, size: iconSize, color: data.iconColor),
    );
  }

  /// Styled retry button.
  Widget _buildRetryButton(BuildContext context, {required bool small}) {
    final retryLabel = _t('error_retry', 'Try Again');

    return SizedBox(
      width: small ? null : double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(retryLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 20 : 24,
            vertical: small ? 10 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Internal helper to group display properties for each error type.
class _ErrorDisplayData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ErrorDisplayData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}
