import '../../events/models/event_kind.dart';
import '../../ideathons/models/ideathon_status.dart';

/// Event-generic section used to group a judge's assigned ideas.
class JudgeEventSection {
  const JudgeEventSection({
    required this.eventId,
    required this.name,
    this.schedule = '',
    this.status,
    this.kind = EventKind.ideathon,
    this.pendingCount = 0,
    this.evaluatedCount = 0,
    this.startAt,
  });

  final String eventId;
  final String name;
  final String schedule;
  final IdeathonStatus? status;
  final EventKind kind;
  final int pendingCount;
  final int evaluatedCount;
  final DateTime? startAt;

  int get assignedCount => pendingCount + evaluatedCount;
}

enum JudgeEventGroupSort {
  statusThenName,
  nearestEvent,
  mostRecentActivity,
}

/// Groups judge scoring rows by event for Pending, Evaluated, and Feedback.
abstract final class JudgeEventGrouping {
  JudgeEventGrouping._();

  static List<MapEntry<JudgeEventSection, List<T>>> group<T>({
    required List<T> items,
    required String Function(T) eventIdOf,
    required String Function(T) nameOf,
    required String Function(T) scheduleOf,
    IdeathonStatus? Function(T)? statusOf,
    DateTime? Function(T)? startAtOf,
    DateTime? Function(T)? activityAtOf,
    Map<String, int> pendingCountByEvent = const <String, int>{},
    Map<String, int> evaluatedCountByEvent = const <String, int>{},
    JudgeEventGroupSort sort = JudgeEventGroupSort.statusThenName,
  }) {
    final Map<String, List<T>> grouped = <String, List<T>>{};
    for (final T item in items) {
      grouped.putIfAbsent(eventIdOf(item).trim(), () => <T>[]).add(item);
    }

    final List<MapEntry<JudgeEventSection, List<T>>> out = <MapEntry<JudgeEventSection, List<T>>>[];
    for (final MapEntry<String, List<T>> e in grouped.entries) {
      final T first = e.value.first;
      final String name = nameOf(first).trim();
      out.add(
        MapEntry<JudgeEventSection, List<T>>(
          JudgeEventSection(
            eventId: e.key,
            name: name.isEmpty ? 'Event' : name,
            schedule: scheduleOf(first).trim(),
            status: statusOf?.call(first),
            startAt: startAtOf?.call(first),
            pendingCount: pendingCountByEvent[e.key] ?? 0,
            evaluatedCount: evaluatedCountByEvent[e.key] ?? 0,
          ),
          e.value,
        ),
      );
    }

    out.sort((MapEntry<JudgeEventSection, List<T>> a, MapEntry<JudgeEventSection, List<T>> b) {
      switch (sort) {
        case JudgeEventGroupSort.nearestEvent:
          return _compareNearest(a.key, b.key);
        case JudgeEventGroupSort.mostRecentActivity:
          return _latestActivity(b.value, activityAtOf).compareTo(_latestActivity(a.value, activityAtOf));
        case JudgeEventGroupSort.statusThenName:
          final int rankA = _statusRank(a.key.status);
          final int rankB = _statusRank(b.key.status);
          if (rankA != rankB) return rankA.compareTo(rankB);
          return a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase());
      }
    });
    return out;
  }

  static DateTime _latestActivity<T>(List<T> items, DateTime? Function(T)? activityAtOf) {
    DateTime? latest;
    if (activityAtOf != null) {
      for (final T item in items) {
        final DateTime? at = activityAtOf(item);
        if (at == null) continue;
        if (latest == null || at.isAfter(latest)) latest = at;
      }
    }
    return latest ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _compareNearest(JudgeEventSection a, JudgeEventSection b) {
    final int bucket = _nearestBucket(a.status).compareTo(_nearestBucket(b.status));
    if (bucket != 0) return bucket;
    final DateTime? sa = a.startAt;
    final DateTime? sb = b.startAt;
    if (sa == null && sb == null) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (sa == null) return 1;
    if (sb == null) return -1;
    if (a.status == IdeathonStatus.completed || a.status == IdeathonStatus.archived) {
      return sb.compareTo(sa);
    }
    return sa.compareTo(sb);
  }

  static int _nearestBucket(IdeathonStatus? status) {
    return switch (status) {
      IdeathonStatus.inProgress => 0,
      IdeathonStatus.scheduled => 1,
      IdeathonStatus.completed => 2,
      IdeathonStatus.draft => 3,
      IdeathonStatus.archived => 4,
      null => 5,
    };
  }

  static int _statusRank(IdeathonStatus? status) {
    return switch (status) {
      IdeathonStatus.inProgress => 0,
      IdeathonStatus.scheduled => 1,
      IdeathonStatus.completed => 2,
      IdeathonStatus.draft => 3,
      IdeathonStatus.archived => 4,
      null => 5,
    };
  }
}
