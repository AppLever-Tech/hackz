/// In-memory cache for Event Details tab loads (per open pane / event id).
abstract final class EventDetailsTabCache {
  EventDetailsTabCache._();

  static final Map<String, EventDetailsTabCacheBucket> _buckets = <String, EventDetailsTabCacheBucket>{};

  static EventDetailsTabCacheBucket forEvent(String ideathonId) {
    final String id = ideathonId.trim();
    return _buckets.putIfAbsent(id, () => EventDetailsTabCacheBucket());
  }

  static void invalidateEvent(String ideathonId) {
    _buckets.remove(ideathonId.trim());
  }

  static void clearAll() {
    _buckets.clear();
  }
}

final class EventDetailsTabCacheBucket {
  final Map<String, Object> _values = <String, Object>{};
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};

  T? peek<T>(String key) {
    final Object? value = _values[key];
    return value is T ? value : null;
  }

  Future<T> getOrLoad<T>(String key, Future<T> Function() load) {
    final T? cached = peek<T>(key);
    if (cached != null) return Future<T>.value(cached);

    final Future<Object?>? existing = _inFlight[key];
    if (existing != null) {
      return existing.then((Object? value) => value as T);
    }

    final Future<T> future = load().then((T value) {
      _values[key] = value as Object;
      _inFlight.remove(key);
      return value;
    }).catchError((Object error, StackTrace stack) {
      _inFlight.remove(key);
      Error.throwWithStackTrace(error, stack);
    });

    _inFlight[key] = future;
    return future;
  }

  void invalidate([String? key]) {
    if (key == null) {
      _values.clear();
      _inFlight.clear();
      return;
    }
    _values.remove(key);
    _inFlight.remove(key);
  }

  void invalidateEvaluationData() {
    invalidate(EventDetailsTabKeys.evaluationBundle);
    invalidate(EventDetailsTabKeys.evaluation);
    invalidate(EventDetailsTabKeys.ideas);
    invalidate(EventDetailsTabKeys.overviewPeople);
    invalidate(EventDetailsTabKeys.judgeAssignments);
    invalidate(EventDetailsTabKeys.reports);
    invalidate(EventDetailsTabKeys.winners);
    invalidate(EventDetailsTabKeys.leaderboard);
  }
}

/// Cache keys for event details tab slices.
abstract final class EventDetailsTabKeys {
  EventDetailsTabKeys._();

  /// Phase 1 workspace-only key (superseded by [evaluationBundle]).
  static const String evaluation = 'evaluation';

  static const String evaluationBundle = 'evaluation_bundle';
  static const String overviewPeople = 'overview_people';
  static const String ideas = 'ideas';
  static const String payments = 'payments';
  static const String judgeAssignments = 'judge_assignments';
  static const String unusedDeletable = 'unused_deletable';
  static const String reports = 'reports';
  static const String winners = 'winners';
  static const String leaderboard = 'leaderboard_vm';
}
