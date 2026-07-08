import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/news_item.dart';
import '../models/notification_model.dart';
import '../models/training_criterion.dart';
import '../models/training_period.dart';
import '../models/training_score.dart';
import '../models/user_item.dart';
import 'api_service.dart';

class AppStateService extends ChangeNotifier {
  static const String _eventSeenKeyPrefix = 'member_seen_event_ids_';
  static const String _newsSeenKeyPrefix = 'member_seen_news_ids_';
  static const String _trainingSnapshotKeyPrefix = 'member_training_snapshot_';
  static const String _contactResponseSeenKeyPrefix = 'member_seen_contact_responses_';

  final List<Event> _events = [];
  final List<NewsItem> _news = [];
  final List<UserItem> _officers = [];
  final List<UserItem> _members = [];
  final List<TrainingPeriod> _trainingPeriods = [];
  final List<TrainingCriterion> _trainingCriteria = [];
  final List<TrainingScore> _myTrainingScores = [];
  final Map<int, String> _unitMap = {};
  final Set<String> _registeredEventIds = {};
  final Map<String, Map<String, dynamic>> _myEventRegistrations = {};
  final List<NotificationModel> _notifications = [];
  bool _isLoaded = false;
  bool _isLoadingEvents = false;
  bool _isLoadingNews = false;
  bool _isLoadingOfficers = false;
  bool _isLoadingMembers = false;
  bool _isLoadingTraining = false;
  Map<String, dynamic>? _currentUser;

  List<Event> get events => List.unmodifiable(_events);
  List<NewsItem> get news => List.unmodifiable(_news);
  List<UserItem> get officers => List.unmodifiable(_officers);
  List<UserItem> get members => List.unmodifiable(_members);
  List<TrainingPeriod> get trainingPeriods =>
      List.unmodifiable(_trainingPeriods);
  List<TrainingCriterion> get trainingCriteria =>
      List.unmodifiable(_trainingCriteria);
  List<TrainingScore> get myTrainingScores =>
      List.unmodifiable(_myTrainingScores);
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoadingNews => _isLoadingNews;
  bool get isLoadingOfficers => _isLoadingOfficers;
  bool get isLoadingMembers => _isLoadingMembers;
  bool get isLoadingTraining => _isLoadingTraining;
  List<NotificationModel> get notifications {
    final currentId = _currentUser?['id']?.toString();
    if (currentId == null || currentId.isEmpty) {
      return List.unmodifiable(_notifications);
    }
    return List.unmodifiable(
      _notifications.where((n) => n.recipientId == null || n.recipientId == currentId),
    );
  }
  Map<String, dynamic>? getMyEventRegistration(String eventId) =>
      _myEventRegistrations[eventId];

  String? _registrationStatus(Map<String, dynamic>? registration) {
    if (registration == null) return null;

    final topLevelStatus = registration['status']?.toString().toLowerCase();
    if (topLevelStatus != null && topLevelStatus.isNotEmpty) {
      return topLevelStatus;
    }

    final participant = registration['participant'];
    if (participant is Map) {
      final nestedStatus = participant['status']?.toString().toLowerCase();
      if (nestedStatus != null && nestedStatus.isNotEmpty) {
        return nestedStatus;
      }
    }

    return null;
  }

  int get unreadNotificationCount {
    final currentId = _currentUser?['id']?.toString();
    if (currentId == null || currentId.isEmpty) {
      return _notifications.where((n) => !n.isRead).length;
    }
    return _notifications
        .where((n) => !n.isRead && (n.recipientId == null || n.recipientId == currentId))
        .length;
  }

  // Khởi tạo và tải dữ liệu
  Future<void> initialize() async {
    if (_isLoaded) return;
    await _loadRegisteredEvents();
    await _loadNotifications();
    await refreshEvents();
    await refreshNews();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    _isLoadingEvents = true;
    notifyListeners();

    try {
      final items = await ApiService.getEvents();
      _events
        ..clear()
        ..addAll(items.map((item) => Event.fromApi(item)));
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingEvents = false;
      final role = _currentUser?['role']?.toString().toLowerCase();
      if (role == 'member' || role == 'staff') {
        await refreshMyEventRegistrations();
      }
      if (role == 'member') {
        await _syncEventNotificationsForMember();
      }
      notifyListeners();
    }
  }

  Future<void> refreshNews() async {
    _isLoadingNews = true;
    notifyListeners();

    try {
      final items = await ApiService.getNews();
      _news
        ..clear()
        ..addAll(items.map((item) => NewsItem.fromApi(item)));
      // Debug: log news count after refresh
      // Remove or guard these prints in production if desired
      // ignore: avoid_print
      print('AppStateService.refreshNews: loaded ${_news.length} news items');
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingNews = false;
      if (_currentUser?['role']?.toString().toLowerCase() == 'member') {
        await _syncNewsNotificationsForMember();
      }
      notifyListeners();
    }
  }

  Future<void> refreshUnits() async {
    try {
      final items = await ApiService.getUnits();
      _unitMap
        ..clear()
        ..addEntries(items.map((item) {
          final id = item['id'] as int? ?? 0;
          final name = item['name']?.toString() ?? '';
          final code = item['code']?.toString() ?? '';
          final display = name.isNotEmpty ? name : code;
          return MapEntry(id, display);
        }));
    } catch (e) {
      // ignore fetch error
    }
  }

  Future<void> refreshOfficers() async {
    _isLoadingOfficers = true;
    notifyListeners();

    await refreshUnits();

    try {
      final items = await ApiService.getUsers(limit: 200);
      _officers
        ..clear()
        ..addAll(
          items.map((item) => UserItem.fromApi(item, unitMap: _unitMap)),
        );
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingOfficers = false;
      notifyListeners();
    }
  }

  Future<void> refreshMembers() async {
    _isLoadingMembers = true;
    notifyListeners();

    await refreshUnits();

    try {
      final items = await ApiService.getUsers(role: 'member', limit: 200);
      _members
        ..clear()
        ..addAll(items
            .map((item) => UserItem.fromApi(item, unitMap: _unitMap))
            .where((user) {
          final roleMatch = user.role == 'member';
          final position = user.position?.toLowerCase() ?? '';
          final isLeader = position.contains('bí thư') ||
              position.contains('phó bí thư') ||
              position.contains('cán bộ') ||
              position.contains('staff');
          return roleMatch && !isLeader;
        }));
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrainingPeriods() async {
    _isLoadingTraining = true;
    notifyListeners();

    try {
      final items = await ApiService.getTrainingPeriods();
      _trainingPeriods
        ..clear()
        ..addAll(items.map((item) => TrainingPeriod.fromApi(item)));
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingTraining = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrainingCriteria() async {
    _isLoadingTraining = true;
    notifyListeners();

    try {
      final items = await ApiService.getTrainingCriteria();
      _trainingCriteria
        ..clear()
        ..addAll(items.map((item) => TrainingCriterion.fromApi(item)));
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingTraining = false;
      notifyListeners();
    }
  }

  Future<void> refreshMyTrainingScores({int? periodId}) async {
    _isLoadingTraining = true;
    notifyListeners();

    try {
      final items = await ApiService.getMyTrainingScores(periodId: periodId);
      _myTrainingScores
        ..clear()
        ..addAll(items.map((item) => TrainingScore.fromApi(item)));
    } catch (e) {
      // ignore fetch error
    } finally {
      _isLoadingTraining = false;
      if (periodId == null &&
          _currentUser?['role']?.toString().toLowerCase() == 'member') {
        await _syncTrainingNotificationsForMember();
      }
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> saveTrainingScore({
    required int userId,
    required int periodId,
    required List<Map<String, dynamic>> items,
    String status = 'draft',
    String? note,
  }) async {
    final result = await ApiService.createTrainingScore(
      userId: userId,
      periodId: periodId,
      items: items,
      status: status,
      note: note,
    );

    await refreshMyTrainingScores();
    return result;
  }

  Future<void> refreshCurrentUser() async {
    final data = await ApiService.getMe();
    if (data != null) {
      _currentUser = data;
      notifyListeners();
      final role = _currentUser?['role']?.toString().toLowerCase();
      if (role == 'member' || role == 'staff') {
        await refreshMyEventRegistrations();
      }
      if (role == 'member') {
        await _syncContactNotificationsForMember();
      }
    }
  }

  Future<void> refreshMyEventRegistrations() async {
    final role = _currentUser?['role']?.toString().toLowerCase();
    if (role != 'member' && role != 'staff') {
      _myEventRegistrations.clear();
      return;
    }

    final previous =
        Map<String, Map<String, dynamic>>.from(_myEventRegistrations);
    final next = <String, Map<String, dynamic>>{};
    for (final event in _events) {
      try {
        final result =
            await ApiService.getMyEventRegistration(eventId: event.id);
        if (result['success'] == true &&
            result['data'] is Map<String, dynamic>) {
          next[event.id] = Map<String, dynamic>.from(result['data'] as Map);
        }
      } catch (e) {
        // ignore fetch error for individual events
      }
    }

    _myEventRegistrations
      ..clear()
      ..addAll(next);

    final memberId = _currentUser?['id']?.toString();
    if (memberId != null && memberId.isNotEmpty) {
      for (final entry in next.entries) {
        if (!previous.containsKey(entry.key)) {
          continue;
        }

        final previousStatus = _registrationStatus(previous[entry.key]);
        final currentStatus = _registrationStatus(entry.value);
        if (previousStatus == currentStatus || currentStatus == null) {
          continue;
        }

        final matchingEvent = _events.cast<Event?>().firstWhere(
              (event) => event?.id == entry.key,
              orElse: () => null,
            );
        final eventTitle = matchingEvent?.title ?? 'Hoạt động';

        if (currentStatus == 'registered') {
          _registeredEventIds.add(entry.key);
          await addNotificationForMember(
            memberId,
            'Đăng ký thành công',
            'Bạn đã đăng ký thành công cho $eventTitle.',
            'success',
            entry.key,
          );
        } else if (currentStatus == 'canceled') {
          _registeredEventIds.remove(entry.key);
          await addNotificationForMember(
            memberId,
            'Đăng ký không thành công',
            '$eventTitle đã bị từ chối.',
            'error',
            entry.key,
          );
        }
      }
    }

    notifyListeners();
  }

  /// Update current user locally without calling server.
  /// `patch` is a map of fields to merge into the existing current user.
  void updateCurrentUserLocally(Map<String, dynamic> patch) {
    if (_currentUser == null) {
      _currentUser = Map<String, dynamic>.from(patch);
    } else {
      _currentUser = {..._currentUser!, ...patch};
    }
    notifyListeners();
  }

  // Lưu notifications vào SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(notificationsJson));
    } catch (e) {
      print('❌ Lỗi khi lưu notifications: $e');
    }
  }

  // Tải notifications từ SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString('notifications');
      if (notificationsString != null) {
        final List<dynamic> notificationsJson = jsonDecode(notificationsString);
        _notifications.clear();
        _notifications.addAll(
            notificationsJson.map((json) => NotificationModel.fromJson(json)));
      }
    } catch (e) {
      print('❌ Lỗi khi tải notifications: $e');
    }
  }

  // Thêm sự kiện mới
  Future<void> addEvent(Event event) async {
    // Deprecated: use createEvent instead.
    _events.insert(0, event);
    notifyListeners();
  }

  // Xóa sự kiện
  Future<void> removeEvent(String eventId) async {
    await ApiService.deleteEvent(eventId);
    await refreshEvents();
  }

  // Cập nhật sự kiện
  Future<void> updateEvent(Event updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateEventRemote({
    required String eventId,
    String? code,
    required String title,
    required String description,
    required DateTime startTime,
    DateTime? endTime,
    DateTime? registerStartTime,
    DateTime? registerEndTime,
    required String location,
    bool isRequired = false,
    String? coverImageUrl,
  }) async {
    final result = await ApiService.updateEvent(
      eventId: eventId,
      code: code,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      registerStartTime: registerStartTime,
      registerEndTime: registerEndTime,
      location: location,
      isRequired: isRequired,
      coverImageUrl: coverImageUrl,
    );
    await refreshEvents();
    return result;
  }

  Future<Map<String, dynamic>> deleteActivitiesBulk(List<String> ids) async {
    final result = await ApiService.deleteActivitiesBulk(ids);
    await refreshEvents();
    return result;
  }

  Future<Map<String, dynamic>> createEvent({
    String? code,
    required String title,
    required String description,
    required DateTime startTime,
    DateTime? endTime,
    DateTime? registerStartTime,
    DateTime? registerEndTime,
    required String location,
    String? plan,
    bool isRequired = false,
    String? registrationMode,
    String? coverImageUrl,
    String status = 'open',
  }) async {
    final result = await ApiService.createEvent(
      code: code,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      registerStartTime: registerStartTime,
      registerEndTime: registerEndTime,
      location: location,
      plan: plan,
      registrationMode: registrationMode,
      status: status,
      isRequired: isRequired,
      coverImageUrl: coverImageUrl,
    );
    await refreshEvents();
    return result;
  }

  Future<Map<String, dynamic>> createNews({
    required String title,
    required String content,
    String type = 'news',
    String status = 'draft',
    bool pinned = false,
    DateTime? publishedAt,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
    int? unitId,
  }) async {
    final result = await ApiService.createNews(
      title: title,
      content: content,
      type: type,
      status: status,
      pinned: pinned,
      publishedAt: publishedAt,
      coverImageUrl: coverImageUrl,
      galleryImageUrls: galleryImageUrls,
      unitId: unitId,
    );
    await refreshNews();
    return result;
  }

  Future<Map<String, dynamic>> updateNews({
    required String newsId,
    required String title,
    required String content,
    String type = 'news',
    String status = 'draft',
    bool pinned = false,
    DateTime? publishedAt,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
    int? unitId,
  }) async {
    final result = await ApiService.updateNews(
      newsId: newsId,
      title: title,
      content: content,
      type: type,
      status: status,
      pinned: pinned,
      publishedAt: publishedAt,
      coverImageUrl: coverImageUrl,
      galleryImageUrls: galleryImageUrls,
      unitId: unitId,
    );
    await refreshNews();
    return result;
  }

  Future<Map<String, dynamic>> uploadNewsImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    return ApiService.uploadNewsImage(bytes: bytes, filename: filename);
  }

  Future<Map<String, dynamic>> uploadEventImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    return ApiService.uploadEventImage(bytes: bytes, filename: filename);
  }

  Future<void> deleteNews(String newsId) async {
    await ApiService.deleteNews(newsId);
    await refreshNews();
  }

  Future<Map<String, dynamic>> archiveNews(String newsId) async {
    final result = await ApiService.archiveNews(newsId);
    await refreshNews();
    return result;
  }

  Future<Map<String, dynamic>> restoreNews(String newsId) async {
    final result = await ApiService.restoreNews(newsId);
    await refreshNews();
    return result;
  }

  Future<bool> registerForEvent(String eventId, {String? note}) async {
    final result = await ApiService.registerEvent(eventId, note: note);
    if (result['success'] == false) {
      return false;
    }

    final data = result['data'];
    if (data is Map<String, dynamic>) {
      _myEventRegistrations[eventId] = Map<String, dynamic>.from(data);
      final status = _registrationStatus(data) ?? 'pending';
      if (status == 'registered' || status == 'attended') {
        _registeredEventIds.add(eventId);
      } else {
        _registeredEventIds.remove(eventId);
      }
    } else {
      _registeredEventIds.add(eventId);
    }
    await _saveRegisteredEvents();
    notifyListeners();
    return true;
  }

  Future<bool> unregisterFromEvent(String eventId, {String? memberId}) async {
    String? resolvedMemberId = memberId;
    if (resolvedMemberId == null && _currentUser != null) {
      resolvedMemberId = _currentUser?['memberId']?.toString() ??
          _currentUser?['member_id']?.toString() ??
          _currentUser?['id']?.toString();
    }

    if (resolvedMemberId == null || resolvedMemberId.isEmpty) {
      return false;
    }

    final result = await ApiService.unregisterEvent(
      eventId: eventId,
      memberId: resolvedMemberId,
    );

    if (result['success'] == false) {
      return false;
    }

    _registeredEventIds.remove(eventId);
    _myEventRegistrations.remove(eventId);
    await _saveRegisteredEvents();
    notifyListeners();
    return true;
  }

  bool isEventRegistered(String eventId) =>
      _registeredEventIds.contains(eventId) ||
      _registrationStatus(_myEventRegistrations[eventId]) == 'registered';

  bool isEventPendingApproval(String eventId) {
    final status = _registrationStatus(_myEventRegistrations[eventId]);
    return status == 'pending';
  }

  bool isEventInvited(String eventId) {
    return _myEventRegistrations[eventId]?['invited'] == true;
  }

  String? getEventRegistrationStatus(String eventId) {
    return _registrationStatus(_myEventRegistrations[eventId]);
  }

  /// Check xem đã check-in (tham gia hoạt động) hay chưa
  bool isEventCheckedIn(String eventId) {
    final status = _registrationStatus(_myEventRegistrations[eventId]);
    return status == 'attended' || status == 'checked_in';
  }

  Future<void> _loadRegisteredEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList('registeredEventIds') ?? [];
      _registeredEventIds
        ..clear()
        ..addAll(values);
    } catch (e) {
      // ignore load error
    }
  }

  Future<void> _saveRegisteredEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'registeredEventIds',
        _registeredEventIds.toList(),
      );
    } catch (e) {
      // ignore save error
    }
  }

  Future<void> _syncEventNotificationsForMember() async {
    final memberId = _currentUser?['id']?.toString();
    if (memberId == null || memberId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_eventSeenKeyPrefix$memberId';
    final seenIds = prefs.getStringList(key) ?? [];
    final currentIds = _events.map((event) => event.id).toSet();

    if (seenIds.isEmpty) {
      await prefs.setStringList(key, currentIds.toList());
      return;
    }

    for (final event in _events) {
      if (!seenIds.contains(event.id)) {
        await addNotificationForMember(
          memberId,
          'Hoạt động mới',
          'Có hoạt động mới: ${event.title}',
          'activity',
          event.id,
        );
      }
    }

    await prefs.setStringList(key, currentIds.toList());
  }

  Future<void> _syncNewsNotificationsForMember() async {
    final memberId = _currentUser?['id']?.toString();
    if (memberId == null || memberId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_newsSeenKeyPrefix$memberId';
    final seenIds = prefs.getStringList(key) ?? [];
    final currentIds = _news.map((item) => item.id.toString()).toSet();

    if (seenIds.isEmpty) {
      await prefs.setStringList(key, currentIds.toList());
      return;
    }

    for (final item in _news) {
      final id = item.id.toString();
      if (!seenIds.contains(id)) {
        await addNotificationForMember(
          memberId,
          'Tin tức mới',
          item.title,
          'news',
          id,
        );
      }
    }

    await prefs.setStringList(key, currentIds.toList());
  }

  Future<void> _syncTrainingNotificationsForMember() async {
    final memberId = _currentUser?['id']?.toString();
    if (memberId == null || memberId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_trainingSnapshotKeyPrefix$memberId';
    final raw = prefs.getString(key);

    final previous = <String, String>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            previous[entry.key] = entry.value.toString();
          }
        }
      } catch (_) {
        // ignore malformed snapshot
      }
    }

    final current = <String, String>{
      for (final score in _myTrainingScores)
        score.id.toString(): score.status.toString().toLowerCase(),
    };

    if (previous.isEmpty) {
      await prefs.setString(key, jsonEncode(current));
      return;
    }

    for (final score in _myTrainingScores) {
      final scoreId = score.id.toString();
      final currentStatus = score.status.toLowerCase();
      final previousStatus = previous[scoreId];

      if (previousStatus == null) {
        await addNotificationForMember(
          memberId,
          'Điểm rèn luyện mới',
          'Bạn có bản ghi điểm rèn luyện mới (${score.displayStatus}).',
          'training',
          scoreId,
        );
        continue;
      }

      if (previousStatus != currentStatus) {
        await addNotificationForMember(
          memberId,
          'Cập nhật điểm rèn luyện',
          'Trạng thái điểm rèn luyện đã chuyển sang ${score.displayStatus}.',
          'training',
          scoreId,
        );
      }
    }

    await prefs.setString(key, jsonEncode(current));
  }

  Future<void> _syncContactNotificationsForMember() async {
    final memberId = _currentUser?['id']?.toString();
    if (memberId == null || memberId.isEmpty) return;

    final messages = await ApiService.getContactMessages(limit: 100);
    final responded = messages.where((item) {
      if (item is! Map<String, dynamic>) return false;
      final status = (item['status'] ?? '').toString().toLowerCase();
      final response = (item['response'] ?? '').toString().trim();
      return status == 'resolved' && response.isNotEmpty;
    }).cast<Map<String, dynamic>>().toList();

    final prefs = await SharedPreferences.getInstance();
    final key = '$_contactResponseSeenKeyPrefix$memberId';
    final seenIds = prefs.getStringList(key) ?? [];
    final currentIds = responded
        .map((item) => (item['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (seenIds.isEmpty) {
      await prefs.setStringList(key, currentIds.toList());
      return;
    }

    for (final item in responded) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty || seenIds.contains(id)) continue;

      final topic = (item['topic'] ?? 'Liên hệ').toString();
      await addNotificationForMember(
        memberId,
        'Phản hồi liên hệ',
        'Admin đã phản hồi liên hệ "$topic" của bạn.',
        'contact',
        id,
      );
    }

    await prefs.setStringList(key, currentIds.toList());
  }

  bool _isDuplicateNotification(
    String type,
    String? relatedId,
    String? recipientId,
    String title,
  ) {
    return _notifications.any((notification) {
      return notification.type == type &&
          notification.relatedId == relatedId &&
          notification.recipientId == recipientId &&
          notification.title == title;
    });
  }

  // Thêm thông báo cho member cụ thể
  Future<void> addNotificationForMember(
    String memberId,
    String title,
    String message,
    String type,
    String? relatedId,
  ) async {
    if (_isDuplicateNotification(type, relatedId, memberId, title)) {
      return;
    }

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      relatedId: relatedId,
      recipientId: memberId,
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllNotificationsAsRead() async {
    final currentId = _currentUser?['id']?.toString();
    for (int i = 0; i < _notifications.length; i++) {
      final item = _notifications[i];
      if (currentId != null && currentId.isNotEmpty) {
        if (item.recipientId != null && item.recipientId != currentId) {
          continue;
        }
      }
      _notifications[i] = item.copyWith(isRead: true);
    }
    await _saveNotifications();
    notifyListeners();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
