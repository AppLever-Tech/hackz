import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/models/event_schedule_type.dart';
import 'package:hackz/features/ideathons/models/ideathon_idea_snapshot.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_status.dart';

void main() {
  group('EventKind template', () {
    test('defaults names, schedule type, and entry terminology', () {
      expect(EventKind.ideathon.defaultEventName(2026), 'Ideathon 2026');
      expect(EventKind.hackathon.defaultEventName(2026), 'Hackathon 2026');
      expect(EventKind.researchPaper.defaultEventName(2026), 'Research Paper Evaluation 2026');

      expect(EventKind.ideathon.defaultScheduleType, EventScheduleType.dayEvent);
      expect(EventKind.hackathon.defaultScheduleType, EventScheduleType.dayEvent);
      expect(EventKind.researchPaper.defaultScheduleType, EventScheduleType.evaluationEvent);

      expect(EventKind.ideathon.entriesLabel, 'Ideas');
      expect(EventKind.hackathon.entriesLabel, 'Prototypes');
      expect(EventKind.researchPaper.entriesLabel, 'Papers');
      expect(EventKind.researchPaper.payableItemLabel, 'Paper');
      expect(EventKind.researchPaper.templateLabel, 'Research Papers');
    });

    test('fromWire accepts enum names and RESEARCH_PAPER style values', () {
      expect(EventKind.fromWire('hackathon'), EventKind.hackathon);
      expect(EventKind.fromWire('RESEARCH_PAPER'), EventKind.researchPaper);
      expect(EventKind.fromWire('researchPaper'), EventKind.researchPaper);
      expect(EventKind.fromWire(null), EventKind.ideathon);
    });
  });

  group('EventScheduleType', () {
    test('fromRaw uses DAY_EVENT and EVALUATION_EVENT wire values', () {
      expect(
        EventScheduleType.fromRaw('DAY_EVENT', fallback: EventScheduleType.evaluationEvent),
        EventScheduleType.dayEvent,
      );
      expect(
        EventScheduleType.fromRaw('EVALUATION_EVENT', fallback: EventScheduleType.dayEvent),
        EventScheduleType.evaluationEvent,
      );
      expect(
        EventScheduleType.fromRaw(null, fallback: EventScheduleType.evaluationEvent),
        EventScheduleType.evaluationEvent,
      );
    });
  });

  test('saved events use scheduleType for cutoff, not template defaults', () {
    final DateTime start = DateTime(2026, 3, 1, 9);
    final DateTime end = DateTime(2026, 9, 1, 17);
    final IdeathonModel event = IdeathonModel(
      ideathonId: 'e1',
      orgId: 'o1',
      eventKind: EventKind.ideathon,
      scheduleType: EventScheduleType.evaluationEvent,
      name: 'Custom window',
      description: '',
      departmentId: 'CSE',
      startDateTime: start,
      endDateTime: end,
      status: IdeathonStatus.scheduled,
      judgeIds: const <String>[],
      coordinatorIds: const <String>[],
      ideas: const <IdeathonIdeaSnapshot>[],
      evaluationTemplateId: 't1',
      createdBy: 'u1',
      createdAt: start,
      updatedAt: start,
    );
    expect(event.isLongRunning, isTrue);
    expect(event.submissionCutoff, end);
  });
}
