import 'package:flutter/material.dart';

import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';
import '../../dashboard/chrome/dashboard_session_scope.dart';
import '../data/docs_registry.dart';
import '../screens/documentation_shell_screen.dart';

/// Single entry point for opening Help (overflow menu + contextual ?).
abstract final class HelpNavigation {
  HelpNavigation._();

  static const String overflowAction = 'help';

  /// Opens the Help shell as a full-screen route.
  static Future<void> open(
    BuildContext context, {
    String? pageId,
    String? sectionId,
    UserModel? user,
  }) {
    final UserModel? resolved =
        user ?? DashboardSessionScope.maybeOf(context)?.user;
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => DocumentationShellScreen(
          user: resolved,
          initialPageId: pageId ?? DocsRegistry.helpHomeId,
          initialSectionId: sectionId,
          standalone: true,
        ),
      ),
    );
  }

  /// Opens Help for a dashboard menu / workspace context label.
  static Future<void> openForContext(
    BuildContext context, {
    required String contextKey,
    UserModel? user,
  }) {
    final String? pageId = DocsRegistry.helpPageForContext(contextKey);
    return open(context, pageId: pageId, user: user);
  }

  static String roleGreeting(UserRole role) =>
      'Hello ${UserRoleLabels.labelFor(role)} 👋';
}
