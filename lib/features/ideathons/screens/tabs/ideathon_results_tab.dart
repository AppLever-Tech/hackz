import 'package:flutter/material.dart';
import 'package:hackz/features/evaluations/screens/evaluation_results_screen.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonResultsTab extends StatelessWidget {
  const IdeathonResultsTab({
    super.key,
    required this.event,
    required this.actor,
  });

  final IdeathonModel event;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    return EvaluationResultsScreen(
      user: actor,
      ideathonId: event.ideathonId,
      ideathonName: event.name,
      embedded: true,
    );
  }
}
