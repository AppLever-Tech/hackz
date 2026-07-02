import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';
import '../services/app_metadata_service.dart';
import 'metadata_viewer_content.dart';

/// Opens the shared premium metadata viewer (dialog on desktop, bottom sheet on mobile).
Future<void> showAppMetadataViewer(
  BuildContext context, {
  required String docId,
  String? fallbackTitle,
}) async {
  final AppMetadataDocument? document = await AppMetadataService.fetch(docId);
  if (!context.mounted) return;
  if (document == null) {
    FeedbackService.showInfo(
      context,
      title: fallbackTitle ?? 'Information',
      message: 'Content is not available right now.',
    );
    return;
  }

  final String title = document.title.trim().isEmpty ? (fallbackTitle ?? 'Information') : document.title.trim();
  final Widget content = MetadataViewerContent(document: document);

  if (ResponsiveHelper.isMobile(context)) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Material(
                color: Colors.white,
                elevation: 16,
                shadowColor: const Color(0x406A38FF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                    child: SingleChildScrollView(
                      child: MetadataViewerShell(
                        title: title,
                        onClose: () => Navigator.of(sheetContext).pop(),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return;
  }

  await showAppDialog<void>(
    context: context,
    width: DialogWidthPreset.standard,
    maxWidth: 560,
    child: MetadataViewerShell(
      title: title,
      child: content,
    ),
  );
}

/// Overflow menu actions and selection handler for app metadata.
abstract final class AppMetadataMenu {
  AppMetadataMenu._();

  static const String actionAbout = 'metadata_about';
  static const String actionTeam = 'metadata_team';
  static const String actionPrivacy = 'metadata_privacy';
  static const String actionTerms = 'metadata_terms';
  static const String actionVersion = 'metadata_version';

  static const List<({String value, IconData icon, String label})> _items = <({String value, IconData icon, String label})>[
    (value: actionAbout, icon: Icons.info_outline_rounded, label: 'About Hackz'),
    (value: actionTeam, icon: Icons.groups_2_outlined, label: 'Project Team'),
    (value: actionPrivacy, icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
    (value: actionTerms, icon: Icons.article_outlined, label: 'Terms & Conditions'),
    (value: actionVersion, icon: Icons.verified_outlined, label: 'App Version'),
  ];

  static List<({String value, IconData icon, String label})> get menuItems => _items;

  static Set<String> get dividersBeforeLogout => <String>{'logout'};

  static Future<void> handleSelection(BuildContext context, String value) async {
    switch (value) {
      case actionAbout:
        await showAppMetadataViewer(context, docId: AppMetadataKeys.about, fallbackTitle: 'About Hackz');
      case actionTeam:
        await showAppMetadataViewer(context, docId: AppMetadataKeys.projectTeam, fallbackTitle: 'Project Team');
      case actionPrivacy:
        await showAppMetadataViewer(context, docId: AppMetadataKeys.privacyPolicy, fallbackTitle: 'Privacy Policy');
      case actionTerms:
        await showAppMetadataViewer(context, docId: AppMetadataKeys.terms, fallbackTitle: 'Terms & Conditions');
      case actionVersion:
        await showAppMetadataViewer(context, docId: AppMetadataKeys.appInfo, fallbackTitle: 'App Version');
      default:
        break;
    }
  }
}
