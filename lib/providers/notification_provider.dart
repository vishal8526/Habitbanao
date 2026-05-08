import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// Global provider for the NotificationService singleton.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
