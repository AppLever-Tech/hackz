import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/ideathons/services/ideathon_judge_assignment_service.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_judge_assignment_workspace_body.dart';
import 'package:hackz/features/user/models/user_model.dart';

/// Ideathon Details tab: explicit Idea → Judge assignment (existing workspace UI).
class IdeathonJudgeAssignmentsTab extends StatefulWidget {
  const IdeathonJudgeAssignmentsTab({
    super.key,
    required this.ideathonId,
    required this.actor,
  });

  final String ideathonId;
  final UserModel actor;

  @override
  State<IdeathonJudgeAssignmentsTab> createState() => _IdeathonJudgeAssignmentsTabState();
}

class _IdeathonJudgeAssignmentsTabState extends State<IdeathonJudgeAssignmentsTab> {
  late Future<IdeathonJudgeAssignmentViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = IdeathonJudgeAssignmentService.load(widget.ideathonId);
  }

  @override
  void didUpdateWidget(covariant IdeathonJudgeAssignmentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ideathonId != widget.ideathonId) {
      _future = IdeathonJudgeAssignmentService.load(widget.ideathonId);
    }
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
        return IdeathonJudgeAssignmentWorkspaceBody(
          vm: snapshot.data!,
          actor: widget.actor,
        );
      },
    );
  }
}
