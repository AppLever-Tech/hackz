import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart' show DocumentationTable, DocumentationTimeline;
import 'docs_asset_paths.dart';

abstract final class AiAnalysisSetupSections {
  static const String overview = 'overview';
  static const String infographic = 'infographic';
  static const String whoConfigures = 'who-configures';
  static const String configureProvider = 'configure-provider';
  static const String capabilities = 'capabilities';
  static const String runAnalysis = 'run-idea-analysis';
  static const String judgeEvaluation = 'judge-evaluation';
  static const String security = 'security-multitenancy';
  static const String troubleshooting = 'troubleshooting';
  static const String platformOneTime = 'platform-setup-one-time';
  static const String orgSetup = 'organisation-setup-summary';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: infographic, title: 'Workflow Infographic'),
    DocSectionSpec(id: overview, title: 'Overview'),
    DocSectionSpec(id: whoConfigures, title: 'Who Configures It'),
    DocSectionSpec(id: configureProvider, title: 'Configure Provider'),
    DocSectionSpec(id: capabilities, title: 'Available Capabilities'),
    DocSectionSpec(id: runAnalysis, title: 'Run Idea Analysis'),
    DocSectionSpec(id: judgeEvaluation, title: 'Judge Evaluation'),
    DocSectionSpec(id: security, title: 'Security & Multi-Tenancy'),
    DocSectionSpec(id: troubleshooting, title: 'Troubleshooting'),
    DocSectionSpec(id: orgSetup, title: 'Per-Organisation Setup Summary'),
    DocSectionSpec(
      id: platformOneTime,
      title: 'Hackz Platform Setup — One Time',
    ),
  ];

  static List<String> get searchCorpus => const <String>[
        'ai analysis originality turnitin drillbit similarity ai writing',
        'college admin configure provider test connection capabilities',
        'run analysis idea submitted judge evaluation full report',
        'secret manager analysis service webhook credentials',
        'pending processing completed failed refresh retry',
      ];
}

class AiAnalysisSetupDocBody extends StatelessWidget {
  const AiAnalysisSetupDocBody({
    super.key,
    required this.sectionKeys,
    this.onPrint,
  });

  final Map<String, GlobalKey> sectionKeys;
  final VoidCallback? onPrint;

  Widget _section({
    required String id,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return DocumentationSection(
      key: sectionKeys[id],
      id: id,
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }

  Widget _bullets(BuildContext context, List<String> lines) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(AppIcons.info, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line, style: const TextStyle(height: 1.45))),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<({String title, String body})> _troubleshootingItems() {
    return <({String title, String body})>[
      (
        title: 'Test Connection failure',
        body:
            'Problem → Connection test fails or status stays Not Configured / Error.\n'
            'Cause → Wrong Turnitin API base URL, invalid or expired API key, integration not enabled, or Hackz Analysis Service unreachable.\n'
            'Fix → Confirm region-correct TCA base URL, regenerate API key from Turnitin Integrations, use integration name Hackz, re-save credentials, ensure Control Plane invoke URL points at a live Analysis Service.\n'
            'Verify → College Admin → AI Analysis → Test Connection shows Connected and capabilities list updates.',
      ),
      (
        title: 'Incorrect or expired provider credentials',
        body:
            'Problem → Save succeeds but tests or runs fail with provider errors.\n'
            'Cause → Rotated or revoked Turnitin key, wrong institution integration.\n'
            'Fix → Turnitin administrator issues a new TCA scope key; College Admin → Replace credentials → Test Connection.\n'
            'Verify → Connected status; run analysis on a submitted test idea.',
      ),
      (
        title: 'Similarity unavailable',
        body:
            'Problem → Similarity row never appears after completion.\n'
            'Cause → Capability not in org public config (feature discovery did not include similarity) or provider result missing.\n'
            'Fix → Confirm Turnitin licence includes similarity; Test Connection to refresh capabilities; Refresh analysis after completion.\n'
            'Verify → Completed analysis shows Similarity % when capability is listed on provider card.',
      ),
      (
        title: 'AI-Writing Indicator unavailable',
        body:
            'Problem → AI-Writing row is hidden.\n'
            'Cause → Not licensed on Turnitin account or not returned from provider feature discovery — Hackz hides unsupported capabilities (no N/A row).\n'
            'Fix → Enable AI-writing product with Turnitin administrator; Test Connection again.\n'
            'Verify → Capability appears on AI Analysis screen only when provider reports it.',
      ),
      (
        title: 'Matching Sources unavailable',
        body:
            'Problem → Matching Sources count not shown.\n'
            'Cause → Capability not enabled/licensed for the organisation.\n'
            'Fix → Confirm provider licence and Test Connection; Refresh completed analysis.\n'
            'Verify → Row appears only when matchingSources capability is present.',
      ),
      (
        title: 'Full Report unavailable',
        body:
            'Problem → View Full Report button missing or opens with error.\n'
            'Cause → fullReport capability false, analysis not COMPLETED, or provider did not return a viewer URL.\n'
            'Fix → Wait for COMPLETED; Refresh; confirm Turnitin report viewer is licensed; retry from Idea Details or Judge Evaluation.\n'
            'Verify → Button visible when fullReportAvailable; external viewer opens (short-lived URL).',
      ),
      (
        title: 'Analysis stuck Pending / Processing',
        body:
            'Problem → Status does not move to Completed for a long time.\n'
            'Cause → Provider still processing, webhook not delivered (Turnitin async), or refresh not run.\n'
            'Fix → College/Dept Admin → Idea Details → Refresh (does not start a new scan); confirm Turnitin webhook URL if async; check provider dashboard.\n'
            'Verify → Firestore analysis record status becomes COMPLETED and metrics populate.',
      ),
      (
        title: 'Analysis Failed',
        body:
            'Problem → Status FAILED with message.\n'
            'Cause → Provider rejection, invalid submission content, credential error mid-run.\n'
            'Fix → Read failure message; fix credentials or idea eligibility (submitted ideas only); Retry (explicit new run).\n'
            'Verify → New analysisId on retry; eventual COMPLETED or actionable error.',
      ),
      (
        title: 'Retry vs Refresh',
        body:
            'Problem → Unsure whether a action started another paid scan.\n'
            'Cause → Confusion between admin actions.\n'
            'Fix → Refresh and Get Latest pull status for the current analysisId only. Run Analysis / Retry create a new analysis run explicitly.\n'
            'Verify → Refresh does not add a second provider submission unless Run Analysis was clicked.',
      ),
      (
        title: 'Provider unavailable (DrillBit)',
        body:
            'Problem → DrillBit card shows unavailable.\n'
            'Cause → DrillBit adapter is not implemented in Hackz yet (pending provider API documentation).\n'
            'Fix → Use Turnitin if licensed; wait for Hackz release notes when DrillBit is enabled.\n'
            'Verify → Only Turnitin can be configured and tested today.',
      ),
      (
        title: 'Webhook / status update issue',
        body:
            'Problem → Turnitin completes but Hackz stays Processing until Refresh.\n'
            'Cause → Webhook URL not registered in Turnitin or routing not saved at submit time.\n'
            'Fix → Hackz operator confirms one-time webhook URL on Analysis Service; Turnitin admin registers it; admins use Refresh until webhook path verified.\n'
            'Verify → Automatic COMPLETED without manual refresh after webhook fix.',
      ),
      (
        title: 'Permission / configuration problem',
        body:
            'Problem → UNAUTHORIZED / FORBIDDEN when saving or running analysis.\n'
            'Cause → Wrong role (only College Admin configures credentials; CADM/OADM/DADM run analysis), or Analysis Service cannot reach tenant Firestore.\n'
            'Fix → Sign in as correct admin; Hackz operator verifies Analysis Service IAM on tenant project (Auth Admin + Firestore access pattern).\n'
            'Verify → CADM saves credentials; eligible admin runs analysis successfully.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'AI Analysis',
          description:
              'Optional originality and AI-writing insights for submitted ideas. Each organisation connects its own licensed provider; Hackz stores credentials securely and shows capability-driven results to admins and judges.',
          lastUpdated: DateTime(2026, 9, 19),
          readingMinutes: 12,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: AiAnalysisSetupSections.infographic,
          title: 'Workflow Infographic',
          subtitle: 'Tap to enlarge. Visual summary — detailed sections below are authoritative.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.aiAnalysisWorkflow,
            maxHeight: 520,
            semanticLabel: 'Hackz AI Analysis workflow from provider setup to judge evaluation',
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.overview,
          title: 'Overview',
          subtitle: 'End-to-end flow from provider setup to judge decision-support.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTimeline(
                items: const <({String title, String body, Widget? pill})>[
                  (title: 'College Admin', body: 'Opens AI Analysis in the dashboard.', pill: null),
                  (
                    title: 'Select provider',
                    body: 'Choose Turnitin when implemented; DrillBit appears but is not available yet.',
                    pill: null,
                  ),
                  (
                    title: 'Configure credentials',
                    body: 'Organisation-owned TCA/API values — saved once server-side.',
                    pill: null,
                  ),
                  (
                    title: 'Test Connection',
                    body: 'Verifies provider reachability and discovers licensed capabilities.',
                    pill: null,
                  ),
                  (
                    title: 'Run Analysis',
                    body: 'Eligible admin explicitly runs analysis on a submitted idea.',
                    pill: null,
                  ),
                  (
                    title: 'Processing',
                    body: 'Pending / Processing until provider (and webhook when configured) completes.',
                    pill: null,
                  ),
                  (
                    title: 'Results',
                    body: 'Latest similarity, optional AI-writing and matching sources, optional full report.',
                    pill: null,
                  ),
                  (
                    title: 'Judge Evaluation',
                    body: 'Judges see latest completed analysis as reference only — scoring unchanged.',
                    pill: null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Organisation-owned licence',
                body:
                    'Each college or organisation uses its own provider account and licence. '
                    'Hackz does not supply Turnitin or other provider subscriptions.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Provider-neutral design',
                body:
                    'Hackz uses a normalized analysis result in the app. Turnitin is implemented today. '
                    'DrillBit is listed for future use but cannot be configured until Hackz ships a real adapter. '
                    'Idea Details and Judge Evaluation do not change when another provider is added.',
              ),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.whoConfigures,
          title: 'Who Configures It',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTable(
                headers: const <String>['Role', 'Access'],
                rows: const <List<String>>[
                  <String>[
                    'College Admin (CADM)',
                    'Configure provider credentials, Test Connection, enable provider, run/refresh idea analysis',
                  ],
                  <String>[
                    'Hackz orgAdmin (OADM)',
                    'Read-only AI Analysis screen — connection status and capabilities; credentials never shown',
                  ],
                  <String>[
                    'Department Admin (DADM)',
                    'Cannot configure credentials; may run/refresh analysis for in-scope submitted ideas when implemented',
                  ],
                  <String>[
                    'Judge',
                    'Read-only originality panel during evaluation; View Full Report when available',
                  ],
                  <String>[
                    'Team Member / Coordinator',
                    'No AI Analysis configuration or admin analysis actions',
                  ],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Credentials source',
                body:
                    'API keys and integration values normally come from the organisation\'s provider administrator '
                    '(for example the college Turnitin administrator). Hackz staff do not provide provider licences.',
              ),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.configureProvider,
          title: 'Configure Provider',
          subtitle: 'College Admin → AI Analysis',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bullets(context, <String>[
                'Select the analysis provider card (Turnitin when connecting).',
                'Choose Configure / Save securely and enter organisation-owned values.',
                'Run Test Connection before relying on analysis in production.',
                'When connected, public status and capabilities appear on the AI Analysis screen and in tenant Firestore config (non-secret fields only).',
              ]),
              const SizedBox(height: 16),
              Text(
                'Turnitin (implemented)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DocumentationCard(
                child: _bullets(context, <String>[
                  'Turnitin API base URL — region-specific TCA endpoint (example: https://app-us.turnitin.com/api/v1).',
                  'API key (TCA secret) — created in Turnitin Administrator → Integrations → Generate TCA Scope → Create key (copy once).',
                  'Integration name — use Hackz (X-Turnitin-Integration-Name).',
                  'Integration version — Hackz app integration version (defaults to 1.0.2 in the configure dialog).',
                ]),
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Turnitin-side setup',
                body:
                    'Your Turnitin administrator must enable the integration, appropriate product features for your licence, '
                    'and (for asynchronous completion) register the Hackz webhook URL provided by your Hackz platform operator. '
                    'Accept any required Turnitin EULA or integration policies in Turnitin admin before testing.',
              ),
              const SizedBox(height: 16),
              Text(
                'DrillBit (not implemented)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Not available yet',
                body:
                    'The DrillBit card is visible but disabled with “Pending provider API documentation”. '
                    'Do not expect DrillBit credentials or Test Connection until Hackz announces support.',
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.success,
                title: 'After save',
                body:
                    'Credentials are sent once to the Hackz Analysis Service and stored in Google Cloud Secret Manager. '
                    'They are never returned to the Flutter app or browser after a successful save.',
              ),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.capabilities,
          title: 'Available Capabilities',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTable(
                headers: const <String>['Capability', 'Meaning'],
                rows: const <List<String>>[
                  <String>['Similarity %', 'Overall similarity indicator from the provider'],
                  <String>['AI-Writing Indicator', 'Provider AI-writing metric when licensed'],
                  <String>['Matching Sources', 'Count of matching sources when provided'],
                  <String>['Full Report', 'Opens provider report viewer on demand (short-lived URL)'],
                ],
              ),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Hackz reads capabilities from Test Connection / provider feature discovery.',
                'Idea Details and Judge Evaluation show only capabilities your organisation has — no “N/A” placeholders.',
                'A Turnitin licence without AI-writing does not show AI-Writing Indicator; that is expected.',
              ]),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.runAnalysis,
          title: 'Run Idea Analysis',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Ideas only',
                body:
                    'Analysis applies to submitted ideas only. It is explicitly triggered by an authorised admin — '
                    'Hackz does not automatically scan every idea.',
              ),
              const SizedBox(height: 12),
              DocumentationTable(
                headers: const <String>['Status', 'Meaning'],
                rows: const <List<String>>[
                  <String>['Pending', 'Analysis record created; provider submission starting'],
                  <String>['Processing', 'Provider is working; use Refresh to pull latest status'],
                  <String>['Completed', 'Normalized metrics available; optional View Full Report'],
                  <String>['Failed', 'Provider or configuration error; message shown; Retry starts a new run'],
                ],
              ),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Idea Details → Originality & AI Analysis → Run Analysis.',
                'Refresh retrieves the latest status/result for the current analysis — it does not start another provider scan.',
                'Run Analysis or Retry after failure creates a new analysis run (history kept; UI shows latest).',
                'View Full Report fetches a provider viewer URL when fullReport capability and fullReportAvailable are true.',
              ]),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.judgeEvaluation,
          title: 'Judge Evaluation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bullets(context, <String>[
                'During scoring, judges see a compact Originality & AI Analysis card when a completed result exists.',
                'Shows latest completed metrics (processing banner if a newer run is in progress).',
                'View Full Report uses the same provider abstraction as Idea Details.',
                'If no analysis exists: “Originality analysis not available.”',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Decision-support only',
                body:
                    'Hackz does not automatically modify judge scores, penalize similarity or AI-writing indicators, '
                    'reject ideas, or treat AI-writing as proof of misconduct. Rubric scoring and feedback remain entirely under the judge.',
              ),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.security,
          title: 'Security & Multi-Tenancy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bullets(context, <String>[
                'Each organisation owns its provider licence and configuration.',
                'Credentials are stored server-side; they are not exposed back to the browser or mobile app after save.',
                'Analysis results for an organisation stay in that organisation\'s tenant data; one org cannot read another\'s configuration or results through Hackz.',
                'One centrally deployed Hackz Analysis Service handles provider API calls for all tenants using secure server-side storage and tenant routing.',
              ]),
            ],
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.troubleshooting,
          title: 'Troubleshooting',
          subtitle: 'Problem → Cause → Fix → Verify',
          child: DocumentationAccordion(items: _troubleshootingItems()),
        ),
        _section(
          id: AiAnalysisSetupSections.orgSetup,
          title: 'Per-Organisation Setup Summary',
          subtitle: 'What each college does — no infrastructure deployment.',
          child: DocumentationCard(
            child: _bullets(context, <String>[
              'Obtain Turnitin TCA credentials from your Turnitin administrator.',
              'College Admin → AI Analysis → Configure Turnitin → Save securely.',
              'Test Connection until Connected; note which capabilities appear.',
              'Turnitin admin: enable integration features and webhook URL from Hackz operator if using async completion.',
              'Submit a test idea → Idea Details → Run Analysis → Refresh → confirm metrics.',
              'Optional: Judge opens Evaluate and confirms decision-support panel matches Idea Details.',
            ]),
          ),
        ),
        _section(
          id: AiAnalysisSetupSections.platformOneTime,
          title: 'Hackz Platform Setup — One Time',
          subtitle: 'For Hackz operators / SysAdmin — NOT College Admin tenant onboarding.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'This is NOT per-tenant setup',
                body:
                    'Deploy the Analysis Service once. It serves all organisations. '
                    'A new college must NOT deploy another Cloud Run service or webhook backend. '
                    'Colleges only configure their provider under AI Analysis.',
              ),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Build and deploy the Hackz Analysis Service (Node/TypeScript) to Cloud Run or equivalent.',
                'Set Control Plane Firestore document hkzAnalysisConfig/hackz field invokeUrl to the public HTTPS base URL of that deployment.',
                'Enable Secret Manager API on the Control Plane (or secrets) GCP project.',
                'Grant the Analysis Service runtime service account Secret Manager access to create/read organisation credential secrets.',
                'Grant the same service account Firestore access on the Control Plane project to read hkzTenants and write hkzAnalysisRouting (webhook correlation).',
                'Grant the same service account on each tenant Firebase project: Firebase Authentication Admin (verify ID tokens) and Cloud Datastore User (read/write analysis records and public provider config) — same pattern as Hackz provisioning IAM on college projects.',
                'Configure environment: HACKZ_CONTROL_PLANE_PROJECT_ID, optional HACKZ_SECRETS_PROJECT_ID, optional HACKZ_INTEGRATION_NAME / HACKZ_INTEGRATION_VERSION defaults.',
                'Register Turnitin webhook URL: https://<analysis-service-host>/webhooks/turnitin (Turnitin administrator action per institution).',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Verify platform deployment',
                body:
                    'From a configured tenant, College Admin Test Connection succeeds; run analysis writes hkzIdeaAnalyses in tenant Firestore; '
                    'webhook updates status when Turnitin is configured. See Troubleshooting if registry or IAM errors appear in Cloud Run logs.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
