/// How an event uses its start/end timestamps. Independent of [EventKind].
enum EventScheduleType {
  dayEvent('DAY_EVENT', 'Day Event'),
  evaluationEvent('EVALUATION_EVENT', 'Evaluation Event');

  const EventScheduleType(this.value, this.label);

  final String value;
  final String label;

  bool get isDayEvent => this == EventScheduleType.dayEvent;
  bool get isEvaluationEvent => this == EventScheduleType.evaluationEvent;

  String get helpText => switch (this) {
        EventScheduleType.dayEvent =>
          'Morning-to-evening event schedule. Start and end are the actual event times.',
        EventScheduleType.evaluationEvent =>
          'Long-running submission and evaluation period. Dates are the applicable window, not a same-day event.',
      };

  DateTime defaultEndDateTime(DateTime start) => switch (this) {
        EventScheduleType.dayEvent => start.add(const Duration(hours: 8)),
        EventScheduleType.evaluationEvent =>
          DateTime(start.year, start.month + 6, start.day, start.hour, start.minute),
      };

  static EventScheduleType fromRaw(String? raw, {required EventScheduleType fallback}) {
    final String v = (raw ?? '').trim().toUpperCase().replaceAll('-', '_');
    if (v == EventScheduleType.evaluationEvent.value) {
      return EventScheduleType.evaluationEvent;
    }
    if (v == EventScheduleType.dayEvent.value) {
      return EventScheduleType.dayEvent;
    }
    return fallback;
  }
}
