import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AppReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  static const String _prefsKeyLastRequestDate = 'app_review_last_request_date';
  static const String _prefsKeySignificantEvents = 'app_review_significant_events';

  // Configuration
  // Ask after 3 significant events (e.g. completing 3 Surahs)
  static const int _minEventsBeforeFirstRequest = 3;
  // Don't ask more than once every 30 days
  static const int _daysBetweenRequests = 30;

  // TODO: REPLACE THIS WITH YOUR ACTUAL APP STORE ID FROM APP STORE CONNECT
  // This is required for the "Rate this App" button to open your specific page on iOS.
  static const String _appStoreId = '6759464099'; 

  /// Logs a significant event (e.g., completing a Surah) and checks if a review should be requested.
  /// Returns true if the review flow was triggered.
  Future<bool> logSignificantEvent() async {
    final prefs = await SharedPreferences.getInstance();

    // Increment event count
    int currentEvents = (prefs.getInt(_prefsKeySignificantEvents) ?? 0) + 1;
    await prefs.setInt(_prefsKeySignificantEvents, currentEvents);

    return await _checkAndRequestReview(prefs, currentEvents);
  }

  /// Manually trigger the review flow if conditions are met.
  /// This triggers the system popup (1-5 stars) and is subject to strict OS quotas.
  /// This should NOT be called from a button (e.g. "Rate Us").
  Future<bool> _checkAndRequestReview(SharedPreferences prefs, int eventCount) async {
    final lastRequestMs = prefs.getInt(_prefsKeyLastRequestDate);
    final now = DateTime.now();

    bool shouldRequest = false;

    if (lastRequestMs == null) {
      // Never requested before. Check if enough events have occurred.
      if (eventCount >= _minEventsBeforeFirstRequest) {
        shouldRequest = true;
      }
    } else {
      // Requested before. Check if enough time has passed.
      final lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
      final difference = now.difference(lastRequestDate).inDays;

      if (difference >= _daysBetweenRequests) {
        shouldRequest = true;
      }
    }

    if (shouldRequest) {
      if (await _inAppReview.isAvailable()) {
        try {
          await _inAppReview.requestReview();
          // Update last request date
          await prefs.setInt(_prefsKeyLastRequestDate, now.millisecondsSinceEpoch);
          return true;
        } catch (e) {
          debugPrint('Error requesting review: $e');
          return false;
        }
      }
    }

    return false;
  }

  /// Open the store listing directly (for "Rate Us" buttons in settings).
  /// This is not subject to quotas and is compliant with Apple's HIG for manual actions.
  Future<void> openStoreListing() async {
    // On iOS, this requires the App Store ID to open the specific app page.
    // If empty, it might just open the App Store front page or fail.
    if (_appStoreId.isNotEmpty) {
      await _inAppReview.openStoreListing(appStoreId: _appStoreId);
    } else {
      // Fallback or warning if ID is missing during development
      debugPrint('AppReviewService: App Store ID is missing. Please set _appStoreId.');
      // Attempt to open without ID (works on Android, might fail on iOS)
      await _inAppReview.openStoreListing();
    }
  }
}
