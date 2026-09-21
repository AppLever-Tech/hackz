import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/ideathons/services/event_details_tab_cache.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_shell_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_judge_assignment_service.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_judge_assignments_panel.dart';
import 'package:hackz/features/user/models/user_model.dart';

/// Ideathon Details tab: explicit Idea → Judge assignment (cached per event pane).
class IdeathonJudgeAssignmentsTab extends StatefulWidget {
  const IdeathonJudgeAssignmentsTab({
    super.key,
    required this.shell,
    required this.cache,
    required this.actor,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final UserModel actor;

  @override
  State<IdeathonJudgeAssignmentsTab> createState() => _IdeathonJudgeAssignmentsTabState();
}

class _IdeathonJudgeAssignmentsTabState extends State<IdeathonJudgeAssignmentsTab> {
  late Future<IdeathonJudgeAssignmentViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant IdeathonJudgeAssignmentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shell.ideathon.ideathonId != widget.shell.ideathon.ideathonId) {
      setState(() => _future = _load());
    }
  }

  Future<IdeathonJudgeAssignmentViewModel> _load() {
    return widget.cache.getOrLoad<IdeathonJudgeAssignmentViewModel>(
      EventDetailsTabKeys.judgeAssignments,
      () => IdeathonJudgeAssignmentService.loadForEventDetails(widget.shell, widget.cache),
    );
  }

  Future<void> _reloadAfterMutation() async {
    widget.cache.invalidate(EventDetailsTabKeys.judgeAssignments);
    widget.cache.invalidateEvaluationData();
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdeathonJudgeAssignmentViewModel>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<IdeathonJudgeAssignmentViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(AppIcons.judges, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.hasError ? 'Unable to load assignments: ${snapshot.error}' : 'Assignments not found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }
        return IdeathonJudgeAssignmentsPanel(
          vm: snapshot.data!,
          actor: widget.actor,
          onAssignmentsChanged: _reloadAfterMutation,
        );
      },
    );
  }
}
