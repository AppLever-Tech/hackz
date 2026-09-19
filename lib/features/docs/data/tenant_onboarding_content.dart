import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/firebase/hackz_provisioning_identity.dart';
import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_mermaid_diagram.dart';
import '../widgets/documentation_primitives.dart';
import 'docs_asset_paths.dart';

/// Hackz production Firebase Hosting site id ([firebase.json] → hosting.site).
const String _hackzHostingSiteId = 'hackze';

/// Primary Hackz web origins tenants must allow for Phone Auth on web.
const List<String> _hackzAuthorizedDomainExamples = <String>[
  'hackze.web.app',
  'hackze.firebaseapp.com',
];

/// Hackz Control Plane Firebase project (catalog / hosting bootstrap).
const String _controlPlaneProjectId = 'hackz-a17b6';

/// Hackz Android application id (Control Plane bootstrap; tenant projects register the same package).
const String _hackzAndroidPackage = 'com.alt.hackz';

/// Exact Storage rules from repository root [storage.rules] (tenant projects only).
const String _tenantStorageRules = r'''rules_version = '2';
// Tenant Firebase projects only. Isolation is the project.
// hackz-a17b6 already allowed signed-in uploads before multi-tenancy.
// New college projects default to deny-all until these rules are published.
service firebase.storage {
  match /b/{bucket}/o {
    function signedIn() {
      return request.auth != null;
    }

    match /payments/{id}/{fileName} {
      allow read, write: if signedIn();
    }
    match /ideas/{id}/{fileName} {
      allow read, write: if signedIn();
    }
    match /problems/{id}/{fileName} {
      allow read, write: if signedIn();
    }
    match /orgs/{orgId}/{allPaths=**} {
      allow read, write: if signedIn();
    }
    match /users/{orgId}/{allPaths=**} {
      allow read, write: if signedIn();
    }
    match /feedback/{id}/{fileName} {
      allow read, write: if signedIn();
    }
  }
}''';

const String _exampleFirebaseConfig = r'''const firebaseConfig = {
  apiKey: "AIzaSy…",
  authDomain: "nitk-hackz.firebaseapp.com",
  projectId: "nitk-hackz",
  storageBucket: "nitk-hackz.firebasestorage.app",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456"
};''';

abstract final class TenantOnboardingSections {
  static const String architecture = 'architecture';
  static const String checklist = 'onboarding-checklist';
  static const String phase1Infographic = 'phase1-infographic';
  static const String step01 = 'step-01-firebase-project';
  static const String step02 = 'step-02-blaze';
  static const String step03 = 'step-03-firestore';
  static const String step04 = 'step-04-storage';
  static const String firebaseRules = 'firebase-security-rules';
  static const String step05 = 'step-05-phone-auth';
  static const String step06 = 'step-06-sms-region';
  static const String step07 = 'step-07-authorized-domains';
  static const String step08 = 'step-08-web-app';
  static const String step09 = 'step-09-android';
  static const String step10 = 'step-10-firebase-config';
  static const String phase2Infographic = 'phase2-infographic';
  static const String step11 = 'step-11-provisioning';
  static const String step12 = 'step-12-register-tenant';
  static const String step13 = 'step-13-org-provisioning';
  static const String step14 = 'step-14-prepare-tenant';
  static const String step15 = 'step-15-verify-login';
  static const String verifyTenantSetup = 'verify-tenant-setup';
  static const String readiness = 'final-readiness-checklist';
  static const String manualAudit = 'new-tenant-configuration-audit';
  static const String previousFixes = 'previous-tenant-setup-fixes';
  static const String troubleshooting = 'troubleshooting';
  static const String warnings = 'important-warnings';
  static const String references = 'official-references';
  static const String optionalAiAnalysis = 'optional-ai-analysis';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: architecture, title: 'Multi-Tenant Architecture'),
    DocSectionSpec(id: checklist, title: 'Onboarding Checklist (Steps 1–15)'),
    DocSectionSpec(id: phase1Infographic, title: 'Phase 1 Infographic'),
    DocSectionSpec(id: step01, title: 'Step 1 — Create Firebase Project'),
    DocSectionSpec(id: step02, title: 'Step 2 — Enable Blaze Plan'),
    DocSectionSpec(id: step03, title: 'Step 3 — Create Cloud Firestore'),
    DocSectionSpec(id: step04, title: 'Step 4 — Create Cloud Storage'),
    DocSectionSpec(id: firebaseRules, title: 'Firebase Security & Storage Rules'),
    DocSectionSpec(id: step05, title: 'Step 5 — Phone Authentication'),
    DocSectionSpec(id: step06, title: 'Step 6 — SMS Region Policy'),
    DocSectionSpec(id: step07, title: 'Step 7 — Authorized Domains'),
    DocSectionSpec(id: step08, title: 'Step 8 — Register Web App'),
    DocSectionSpec(id: step09, title: 'Step 9 — Register Android App'),
    DocSectionSpec(id: step10, title: 'Step 10 — Firebase Configuration'),
    DocSectionSpec(id: phase2Infographic, title: 'Phase 2 Infographic'),
    DocSectionSpec(id: step11, title: 'Step 11 — Authorize Hackz Provisioning'),
    DocSectionSpec(id: step12, title: 'Step 12 — Register Tenant in Hackz'),
    DocSectionSpec(id: step13, title: 'Step 13 — Organisation & Admin Provisioning'),
    DocSectionSpec(id: step14, title: 'Step 14 — Prepare Your Tenant'),
    DocSectionSpec(id: step15, title: 'Step 15 — Verify Real Login'),
    DocSectionSpec(
      id: verifyTenantSetup,
      title: 'Verify Tenant Setup (Checklist Step 15)',
    ),
    DocSectionSpec(id: readiness, title: 'Final Readiness Checklist'),
    DocSectionSpec(id: manualAudit, title: 'New Tenant Final Configuration Audit'),
    DocSectionSpec(id: previousFixes, title: 'Previous Tenant Setup Fixes'),
    DocSectionSpec(id: troubleshooting, title: 'Troubleshooting'),
    DocSectionSpec(id: warnings, title: 'Important Warnings'),
    DocSectionSpec(id: optionalAiAnalysis, title: 'Optional — Enable AI Analysis'),
    DocSectionSpec(id: references, title: 'Official Firebase References'),
  ];

  static List<String> get searchCorpus => const <String>[
        'tenant onboarding firebase blaze firestore storage phone otp sms region',
        'authorized domains hackze web.app provisioning service account iam',
        'register tenant organisation code college admin orgAdmin hkzTenants',
        'storage rules payments ideas problems orgs users feedback signedIn',
        'firebaseConfig apiKey authDomain storageBucket appIdWeb appIdAndroid',
        'hostname match referer api key localhost reCAPTCHA tenant resolution',
        'departments problems teams csv sih import event ideathon hackathon',
      ];
}

class TenantOnboardingDocBody extends StatelessWidget {
  const TenantOnboardingDocBody({
    super.key,
    required this.sectionKeys,
    this.onPrint,
    this.onOpenPage,
  });

  final Map<String, GlobalKey> sectionKeys;
  final VoidCallback? onPrint;
  final ValueChanged<String>? onOpenPage;

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
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _checklist(BuildContext context, List<String> items) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('□ ', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _bodyText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _numberedSteps(BuildContext context, List<String> steps) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${i + 1}. ',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _link(BuildContext context, String label, String url) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13.5, height: 1.45, color: cs.onSurface),
          children: <InlineSpan>[
            TextSpan(text: '$label — '),
            TextSpan(
              text: url,
              style: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri? uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _iamRoleBullets() {
    return HackzProvisioningIdentity.minimumIamRoles
        .map(
          (ProvisioningIamRole r) =>
              '${r.title} (${r.role}) — ${r.reason}',
        )
        .toList(growable: false);
  }

  List<({String title, String body})> _previousSetupFixItems() {
    final String domains = _hackzAuthorizedDomainExamples.join(', ');
    return <({String title, String body})>[
      (
        title: 'Real OTP never arrives',
        body: 'Problem → SMS not received after Request OTP.\n'
            'Cause → Phone disabled, Blaze missing, SMS region blocked, wrong tenant Auth, or domain/API key restrictions.\n'
            'Where → Tenant Firebase: Authentication (Phone, SMS region, Authorized domains); Billing (Blaze).\n'
            'Fix → Enable Phone, upgrade Blaze, allow user country in SMS region policy, add Hackz hosts ($domains) and HTTP referrers on tenant web API key.\n'
            'Verify → Real mobile receives SMS; browser console shows no auth/unauthorized-domain errors.',
      ),
      (
        title: 'Hostname match / unauthorized-domain on web',
        body: 'Problem → Phone sign-in fails with hostname or referer errors.\n'
            'Cause → Tenant project does not authorize the Hackz origin or API key blocks referrers.\n'
            'Where → Tenant Firebase Authentication → Authorized domains; Google Cloud → Credentials → tenant web API key → HTTP referrers.\n'
            'Fix → Add production Hackz domains and https://HOST/* referrers; add localhost only for dev.\n'
            'Verify → Request OTP from the same URL users will use in production.',
      ),
      (
        title: 'Storage upload permission-denied',
        body: 'Problem → Attachments fail after login.\n'
            'Cause → Default deny-all Storage rules on new tenant buckets.\n'
            'Where → Tenant Firebase → Storage → Rules.\n'
            'Fix → Publish Hackz tenant Storage rules from this Help page (signed-in paths only).\n'
            'Verify → Upload a file in Hackz as an authenticated tenant user.',
      ),
      (
        title: 'OTP billed to wrong Firebase project',
        body: 'Problem → SMS usage appears on Control Plane instead of college project.\n'
            'Cause → OTP sent before tenant resolution / wrong FirebaseAuth instance.\n'
            'Where → Hackz login flow (organisation code first); Register Tenant catalog projectId.\n'
            'Fix → Ensure organisation code resolves tenant firebaseConfig before sendOtp; confirm tenant projectId in SysAdmin tenant record.\n'
            'Verify → Firebase Authentication usage/SMS metrics on the college project increase when testing OTP.',
      ),
      (
        title: 'College Admin / orgAdmin provisioning fails',
        body: 'Problem → Provision step errors or Validate Again fails.\n'
            'Cause → Missing IAM for Hackz provisioning service account or unreachable Auth/Firestore on tenant project.\n'
            'Where → Google Cloud IAM on tenant project; Hackz Organisation onboarding authorization panel.\n'
            'Fix → Grant roles/firebaseauth.admin and roles/datastore.user to the Hackz provisioning SA; re-run Validate Again.\n'
            'Verify → Provisioning Authorization shows verified; College Admin and orgAdmin provision succeed.',
      ),
      (
        title: 'Tenant registered but wrong Firebase at login',
        body: 'Problem → Data or Auth from unexpected project.\n'
            'Cause → Mismatch between organisation code mapping and registered firebaseConfig.\n'
            'Where → Control Plane hkzTenants / approved tenant catalog; Register Tenant fields.\n'
            'Fix → Correct projectId, apiKey, app IDs, storageBucket, authDomain; do not hand-edit identifiers away from console values.\n'
            'Verify → Login smoke test loads tenant dashboard and tenant Firestore data.',
      ),
    ];
  }

  List<({String title, String body})> _troubleshootingItems() {
    final String domains = _hackzAuthorizedDomainExamples.join(', ');
    final String defaultSa = 'hackz-provisioning@$_controlPlaneProjectId.iam.gserviceaccount.com';
    return <({String title, String body})>[
      (
        title: 'OTP is not arriving',
        body: 'Check: Phone provider enabled on the tenant project; Blaze enabled; SMS region policy '
            'allows the user\'s country; valid E.164 phone format; tenant project Authorized domains '
            'include your Hackz URL ($domains and any custom domain); Firebase quota/throttling; '
            'correct tenant Firebase project initialized after organisation code resolution.',
      ),
      (
        title: 'Firebase says SMS region is blocked',
        body: 'Firebase Console → Authentication → Settings → SMS region policy. Explicitly allow '
            'the country where users receive OTP (for example India for an Indian college).',
      ),
      (
        title: 'Phone Auth works with test numbers but not real numbers',
        body: 'Check Blaze plan, SMS region policy, SMS quota/throttling, billing account linked, and '
            'that OTP is sent from the tenant FirebaseAuth instance (not the Control Plane default).',
      ),
      (
        title: 'Who is charged for OTP?',
        body: 'The Firebase project whose FirebaseAuth sends the verification SMS consumes OTP quota '
            'and billing. In Hackz, the organisation code must resolve the tenant, initialize tenant '
            'Firebase, then use tenant FirebaseAuth before sendOtp.',
      ),
      (
        title: 'OTP is being charged to Hackz instead of tenant',
        body: 'Verify order: Organisation Code → resolve firebaseConfig → initialize tenant Firebase → '
            'tenant FirebaseAuth → send OTP. NOT: Hackz default FirebaseAuth → send OTP → resolve tenant.',
      ),
      (
        title: 'unauthorized-domain / reCAPTCHA / hostname match not found',
        body: 'On the tenant Firebase project: Authentication → Settings → Authorized domains — add '
            'the exact Hackz host you use ($domains or your custom domain). Web phone auth uses '
            'reCAPTCHA. Also check Google Cloud Console → APIs & Services → Credentials → tenant web '
            'API key → HTTP referrers — add https://YOUR-HACKZ-HOST/* (and http://localhost:* for '
            'local dev only).',
      ),
      (
        title: 'localhost does not work for development',
        body: 'Firebase projects created after 28 April 2025 do not automatically include localhost. '
            'Add localhost explicitly under Authorized domains on the tenant project for development '
            'only. Prefer one origin (localhost, not 127.0.0.1). Do not use localhost in production.',
      ),
      (
        title: 'Firestore does not load',
        body: 'Check correct projectId in registered firebaseConfig; Firestore database created in '
            'tenant project; user authenticated against tenant Auth; browser console for permission '
            'or network errors. Hackz does not ship tenant Firestore rules in this repository — use '
            'Firebase defaults unless your institution adds custom rules separately.',
      ),
      (
        title: 'Storage upload fails',
        body: 'Check Blaze enabled; Storage bucket created; storageBucket matches Firebase console; '
            'user signed in via tenant Auth; publish tenant Storage rules from this Help page '
            '(signed-in access on Hackz paths). Default deny-all buckets block uploads until rules '
            'are published.',
      ),
      (
        title: 'storageBucket looks different from older projects',
        body: 'New buckets commonly use PROJECT_ID.firebasestorage.app. Older projects may use '
            'PROJECT_ID.appspot.com. Copy the exact value from Firebase Project settings — do not '
            'guess or edit manually.',
      ),
      (
        title: 'Tenant registration succeeds but login uses wrong project',
        body: 'Verify organisation code → hkzTenants mapping; stored firebaseConfig projectId; '
            'tenant Firebase app initialization; FirebaseAuth.instanceFor(tenantApp) for OTP.',
      ),
      (
        title: 'College Admin / orgAdmin provisioning fails',
        body: 'Check tenant Firebase project; Hackz provisioning service authorized in Google Cloud '
            'IAM; service account email (configured in Control Plane hkzProvisioningConfig or default '
            '$defaultSa); roles/firebaseauth.admin and roles/datastore.user only; validate again from '
            'Organisation onboarding in Hackz SysAdmin.',
      ),
      (
        title: 'Permission denied during provisioning',
        body: 'Grant the Hackz provisioning service account on the tenant project via IAM & Admin → '
            'IAM. Use least privilege — not Owner, Editor, or Storage Admin.',
      ),
      (
        title: 'Duplicate orgAdmin or College Admin on retry',
        body: 'Provisioning is intended to be idempotent. Check existing hkzUsers before repeating '
            'provision steps; use Hackz organisation details to see current provisioning state.',
      ),
      (
        title: 'Team CSV import fails for department',
        body: 'Verify department names in CSV match Hackz departments. Unresolved legitimate '
            'departments can be created by orgAdmin during the import flow per current Hackz behavior.',
      ),
      (
        title: 'SIH import creates duplicates',
        body: 'Use source + sourceProblemId — Hackz uses these fields to avoid duplicate SIH imports.',
      ),
      (
        title: 'Team Leader logs in but cannot submit idea',
        body: 'Check tenant setup readiness, team membership / team leader role, active event, problem '
            'assignment, submission cutoff, commercial plan, and PER_IDEA payment requirements where '
            'applicable.',
      ),
      (
        title: 'Idea does not appear in event',
        body: 'PER_IDEA: payment validated by orgAdmin. PER_EVENT: event commercial access. ANNUAL: '
            'organisation contract validity.',
      ),
      (
        title: 'Android Phone Auth fails but web works',
        body: 'Register Android app in tenant Firebase with package $_hackzAndroidPackage; add SHA-1 '
            'and SHA-256; store Android app ID in Register Tenant (appIdAndroid). Hackz initializes '
            'tenant Firebase dynamically — do not replace Control Plane google-services.json for '
            'tenant credentials; ensure tenant Android app ID is in the Hackz tenant catalog.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const String provisioningSaDefault =
        'hackz-provisioning@$_controlPlaneProjectId.iam.gserviceaccount.com';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'Tenant Onboarding',
          description:
              'Complete Firebase setup guide for registering a new organisation as an isolated Hackz tenant.',
          lastUpdated: DateTime(2026, 9, 17),
          readingMinutes: 35,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: TenantOnboardingSections.architecture,
          title: 'Multi-Tenant Architecture',
          subtitle: 'How Hackz routes each organisation to its own Firebase project.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationMermaidDiagram(
                title: 'Request flow',
                source: '''
flowchart TD
  A[Hackz Web UI] --> B[Organisation Code]
  B --> C[Resolve Registered Tenant]
  C --> D[Tenant Firebase Project]
  D --> E[Authentication]
  D --> F[Firestore]
  D --> G[Storage]
''',
              ),
              const SizedBox(height: 14),
              _bullets(context, <String>[
                'Hackz has one application codebase, hosted on the Control Plane Firebase project '
                    '($_controlPlaneProjectId, site $_hackzHostingSiteId).',
                'Each organisation uses its own isolated Firebase project for Authentication, Firestore, '
                    'and Storage.',
                'Hackz Control Plane stores tenant registration and metadata only (for example '
                    'hkzTenants, approved firebaseConfig catalog).',
                'The tenant firebaseConfig is registered by Hackz SysAdmin; colleges never paste keys at login.',
                'Hackz provisioning service performs privileged operations only (initial College Admin / '
                    'orgAdmin setup) when the college authorizes it in Google Cloud IAM.',
                'Tenant business data is not copied to the Control Plane.',
              ]),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.checklist,
          title: 'Onboarding Checklist (Steps 1–15)',
          subtitle:
              'Use the table of contents (desktop) or section list to jump to each step. This checklist is documentation only — Hackz does not track setup progress.',
          child: DocumentationCard(
            child: _numberedSteps(
              context,
              <String>[
                'Create Firebase Project',
                'Upgrade to Blaze',
                'Create Firestore',
                'Create Storage',
                'Configure Authentication (Phone)',
                'Configure SMS Region Policy',
                'Configure Authorized Domains',
                'Register Web App',
                'Register Android App (if using mobile)',
                'Obtain Firebase Configuration',
                'Authorize Hackz Provisioning',
                'Register Tenant in Hackz',
                'Provision Organisation',
                'Verify Login',
                'Verify Tenant Setup',
              ],
            ),
          ),
        ),
        _section(
          id: TenantOnboardingSections.phase1Infographic,
          title: 'Tenant Onboarding — Phase 1',
          subtitle: 'Firebase project setup — Steps 1–10. Tap to enlarge.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.tenantOnboardingPhase1,
            maxHeight: 520,
            semanticLabel:
                'Infographic: Tenant onboarding phase one, Firebase project setup steps one through ten',
          ),
        ),
        _section(
          id: TenantOnboardingSections.step01,
          title: 'Step 1 — Create Firebase Project',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _numberedSteps(context, <String>[
                'Sign in to Firebase Console.',
                'Create a new Firebase project for the organisation.',
                'Choose a meaningful project name (example: NITK Hackz).',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Project ID',
                body: 'Example project ID: nitk-hackz. Project IDs are globally unique and cannot '
                    'simply be renamed later — choose carefully. Google Analytics is optional for Hackz '
                    'unless your institution requires it elsewhere.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Firebase Console', 'https://console.firebase.google.com/'),
              _link(context, 'Firebase Web Setup', 'https://firebase.google.com/docs/web/setup'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step02,
          title: 'Step 2 — Enable Blaze Plan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'Upgrade the tenant project to Blaze (pay-as-you-go). Real Phone Authentication SMS and '
                'Cloud Storage for Firebase require Blaze on tenant projects.',
              ),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Firebase Console → Project → Upgrade / Billing → Blaze.',
                'Select or link a Google Cloud billing account for this tenant project.',
                'Configure Google Cloud budget alerts (recommended).',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Not a fixed subscription',
                body: 'Blaze is pay-as-you-go based on actual billable usage — not a flat monthly fee. '
                    'SMS pricing varies by region; refer to current Firebase pricing documentation rather '
                    'than hard-coded rates.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Firebase pricing', 'https://firebase.google.com/pricing'),
              _link(
                context,
                'Firebase billing plans',
                'https://firebase.google.com/docs/projects/billing/firebase-pricing-plans',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step03,
          title: 'Step 3 — Create Cloud Firestore',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Firebase Console → Firestore Database → Create database.'),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Creates the tenant\'s primary database for organisation data.',
                'Choose a production location carefully — latency and change constraints apply; align with '
                    'other Hackz tenants at your institution where possible.',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Firestore security rules',
                body: 'This Hackz repository does not maintain tenant Firestore rules files. New tenants '
                    'use Firebase Console defaults unless your institution deploys custom rules separately. '
                    'Do not deploy permissive test rules in production.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Cloud Firestore quickstart', 'https://firebase.google.com/docs/firestore/quickstart'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step04,
          title: 'Step 4 — Create Cloud Storage',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Firebase Console → Storage → Get started → Create default bucket.'),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Blaze is required for Cloud Storage for Firebase.',
                'Select an appropriate bucket location.',
                'Hackz stores tenant-owned attachments under signed-in paths (payments, ideas, problems, orgs, users, feedback).',
                'New default buckets often use PROJECT_ID.firebasestorage.app; older projects may use PROJECT_ID.appspot.com.',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Never public buckets',
                body: 'Do not make Storage publicly readable or writable. Hackz expects authenticated access only.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Cloud Storage for Firebase', 'https://firebase.google.com/docs/storage/web/start'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.firebaseRules,
          title: 'Firebase Security & Storage Rules',
          subtitle: 'Required tenant Storage rules from the current Hackz repository.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'New Firebase Storage buckets default to deny-all. Each tenant Firebase project must publish '
                'the Hackz Storage rules below so signed-in users can upload and read attachments.',
              ),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Why: Hackz uploads require authenticated access on known path prefixes without public access.',
                'Where: Firebase Console → Storage → Rules (tenant project).',
                'Replace/update with the exact rules from storage.rules in the Hackz repository (copied below).',
                'Click Publish.',
                'Verify: Sign in as a tenant user and upload a test attachment in Hackz; confirm no permission-denied in browser console.',
                'Common error when missing: Storage upload fails with permission-denied or object-not-found on new buckets.',
              ]),
              const SizedBox(height: 12),
              DocumentationCodeBlock(
                title: 'Tenant Storage rules (publish on each tenant project)',
                language: 'rules',
                code: _tenantStorageRules,
              ),
              const SizedBox(height: 14),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Firestore rules',
                body: 'Not applicable as a Hackz-maintained artifact — no firestore.rules file ships with '
                    'this repository. Configure Firestore security through your institution\'s policy or '
                    'Firebase defaults; do not use allow read, write: if true.',
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Authentication configuration',
                body: 'Phone provider must be enabled; SMS region and Authorized domains must allow your '
                    'users and Hackz hosting origins (documented in Steps 5–7).',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step05,
          title: 'Step 5 — Enable Phone Authentication',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Firebase Console → Authentication → Sign-in method → Phone → Enable.'),
              const SizedBox(height: 12),
              _bodyText(
                context,
                'Hackz login: Organisation Code + Mobile Number → resolve tenant → tenant Firebase Auth → '
                'OTP → authenticated tenant user. The tenant Firebase project sends OTP after resolution; '
                'SMS quota and billing apply to that tenant project, not only the Control Plane host.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Web phone authentication', 'https://firebase.google.com/docs/auth/web/phone-auth'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step06,
          title: 'Step 6 — SMS Region Policy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Firebase Console → Authentication → Settings → SMS region policy.'),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'New projects may allow no SMS regions initially — this is mandatory for real OTP testing.',
                'Allow only countries where your users receive OTP (example: India for an Indian college).',
                'If Phone Auth is enabled but SMS never arrives, verify SMS region policy first.',
              ]),
              const SizedBox(height: 12),
              _link(context, 'Phone authentication docs', 'https://firebase.google.com/docs/auth/web/phone-auth'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step07,
          title: 'Step 7 — Authorized Domains',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Firebase Console → Authentication → Settings → Authorized domains.'),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Add every domain from which Hackz Phone Authentication is initiated on the tenant project.',
                'Production Hackz is hosted on Firebase Hosting site $_hackzHostingSiteId — authorize at minimum: '
                    '${_hackzAuthorizedDomainExamples.join(' and ')}.',
                'If you use a custom domain on the same Hosting site, add that host as well.',
                'Web phone auth uses reCAPTCHA verification.',
                'Projects created after 28 April 2025 do not automatically include localhost; add localhost '
                    'explicitly for local development only (not production).',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'API key HTTP referrers (web)',
                body: 'Hackz also documents tenant web API key restrictions: Google Cloud Console → '
                    'APIs & Services → Credentials → tenant web API key → HTTP referrers — add '
                    'https://YOUR-HACKZ-HOST/* and matching Authorized domains. For local dev add '
                    'http://localhost:* if needed.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Web phone authentication', 'https://firebase.google.com/docs/auth/web/phone-auth'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step08,
          title: 'Step 8 — Register Web App',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'Firebase Console → Project Settings → General → Your apps → Add app → Web. '
                'Example nickname: Hackz Web.',
              ),
              const SizedBox(height: 12),
              DocumentationCodeBlock(
                title: 'Example firebaseConfig shape',
                language: 'javascript',
                code: _exampleFirebaseConfig,
              ),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'This firebaseConfig identifies the tenant Firebase project/app for Hackz client initialization.',
                'Client config is not a Firebase Admin service-account private key — never paste service-account JSON into Register Tenant.',
              ]),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step09,
          title: 'Step 9 — Register Android App',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'If users sign in with the Hackz Android app, register an Android app in the tenant Firebase project.',
              ),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Firebase Console → Project Settings → General → Your apps → Add app → Android.',
                'Package name: $_hackzAndroidPackage (same as the published Hackz Android app).',
                'Add SHA-1 and SHA-256 from your signing keys (required for modern Phone Auth / Play Integrity).',
                'Copy the Android app ID into Hackz Register Tenant (Android app ID field).',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Dynamic multi-tenant initialization',
                body: 'Hackz binds tenant FirebaseOptions from the Control Plane catalog at runtime. The '
                    'android/app/google-services.json in the Hackz repo targets Control Plane project '
                    '$_controlPlaneProjectId for bootstrap — do not replace it with a college '
                    'google-services.json. Tenant Android credentials live in the Register Tenant catalog fields.',
              ),
              const SizedBox(height: 12),
              _link(context, 'Android Firebase setup', 'https://firebase.google.com/docs/android/setup'),
              _link(context, 'Android phone auth', 'https://firebase.google.com/docs/auth/android/phone-auth'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step10,
          title: 'Step 10 — Find Firebase Configuration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _numberedSteps(context, <String>[
                'Firebase Console → Project Settings → General → Your apps.',
                'Select the Web app → SDK setup and configuration → Config.',
                'Copy values exactly into Hackz SysAdmin Register Tenant (or paste the firebaseConfig snippet and use Fill fields).',
              ]),
              const SizedBox(height: 12),
              _bodyText(context, 'Register Tenant expects these fields (from ApprovedTenantProject):'),
              const SizedBox(height: 8),
              _bullets(context, <String>[
                'Label (display name)',
                'Project ID (required)',
                'API key (required)',
                'Web app ID',
                'Android app ID (when using Android)',
                'Messaging sender ID (required)',
                'Storage bucket (required)',
                'Auth domain (defaults to projectId.firebaseapp.com if empty)',
              ]),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Do not edit identifiers',
                body: 'Do not manually change projectId, authDomain, or storageBucket away from Firebase console values.',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.phase2Infographic,
          title: 'Tenant Onboarding — Phase 2',
          subtitle: 'Register, provision and get started with Hackz — Steps 11–15.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.tenantOnboardingPhase2,
            maxHeight: 520,
            semanticLabel:
                'Infographic: Tenant onboarding phase two, register provision and get started steps eleven through fifteen',
          ),
        ),
        _section(
          id: TenantOnboardingSections.step11,
          title: 'Step 11 — Authorize Hackz Provisioning',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'Hackz uses its provisioning service for privileged setup (initial College Administrator '
                'and Hackz orgAdmin in tenant Firestore / Auth). The college grants least-privilege IAM on '
                'the tenant Google Cloud project — ownership stays with the college.',
              ),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Google Cloud Console → select the tenant Firebase project.',
                'IAM & Admin → IAM → Grant Access.',
                'Principal: Hackz provisioning service account (Control Plane hkzProvisioningConfig document, '
                    'or default $provisioningSaDefault).',
                'Assign only the minimum roles Hackz requires (see below) → Save.',
                'In Hackz SysAdmin → Organisations → Setup & Provisioning, run Validate Again on '
                    'Provisioning Authorization (checks tenant project reachability, Auth, Firestore, and '
                    'documents the Hackz provisioning service account email for IAM).',
              ]),
              const SizedBox(height: 12),
              _bodyText(context, 'Minimum IAM roles (from HackzProvisioningIdentity):'),
              const SizedBox(height: 8),
              _bullets(context, _iamRoleBullets()),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'Does not transfer project ownership to Hackz.',
                'Access can be revoked anytime via Google Cloud IAM.',
                'No service-account private key is shared through the Hackz UI.',
                'Normal Hackz operations continue directly against tenant Firebase.',
              ]),
              const SizedBox(height: 12),
              _link(context, 'Grant IAM roles in Console', 'https://cloud.google.com/iam/docs/grant-role-console'),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step12,
          title: 'Step 12 — Register Tenant in Hackz',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'SysAdmin → Tenants → Register Tenant.'),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Enter tenant label and Firebase project identification.',
                'Paste firebaseConfig or fill API key, app IDs, sender ID, storage bucket, auth domain.',
                'Save — project is added to the approved tenant catalog on the Control Plane.',
              ]),
              const SizedBox(height: 12),
              _bodyText(
                context,
                'When creating an Organisation, Hackz runs live workspace checks (connection, tenant Auth, '
                'Firestore reachability, SysAdmin Control Plane access) via the organisation onboarding '
                'validator — resolve any failed checks before provisioning admins.',
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Organisation vs tenant',
                body: 'Organisation = customer/business entity. Tenant = organisation\'s technical Firebase '
                    'environment (registered project + firebaseConfig). Users log in with Organisation Code, '
                    'not Firebase project ID.',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step13,
          title: 'Step 13 — Organisation & Admin Provisioning',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'SysAdmin → Organisations — create and provision:'),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Create Organisation — associate/select registered tenant / workspace project.',
                'Assign active Hackz orgAdmin (Hackz operations user; exclusive organisation assignment).',
                'Authorize and validate college IAM when prompted.',
                'Provision College Admin (organisation-owned administrator).',
                'Provision Hackz orgAdmin into tenant hkzUsers.',
              ]),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'College Admin belongs to the organisation business model.',
                'orgAdmin is Hackz-controlled support/operations; provisioned into tenant hkzUsers.',
                'Tenant users authenticate via tenant Firebase Auth.',
                'Organisation must retain at least one active Hackz orgAdmin where required by Hackz policy.',
              ]),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step14,
          title: 'Step 14 — Prepare Your Tenant',
          subtitle: 'Use orgAdmin (or delegated admins) after provisioning.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Typical readiness sequence: Organisation → Departments → Problems → Teams → Event → Ready.'),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Departments',
                child: _bullets(context, <String>[
                  'Create required departments.',
                  'Unresolved departments from team CSV may be created by orgAdmin during import.',
                ]),
              ),
              const SizedBox(height: 10),
              DocumentationCard(
                title: 'Problems',
                child: _bullets(context, <String>[
                  'Import or manage problem statements.',
                  'Smart India Hackathon (SIH) import supported.',
                  'source + sourceProblemId prevents duplicate SIH imports.',
                ]),
              ),
              const SizedBox(height: 10),
              DocumentationCard(
                title: 'Teams',
                child: _bullets(context, <String>[
                  'Import Hackz Google Form CSV.',
                  'Department resolution must succeed (or create departments as supported).',
                ]),
              ),
              const SizedBox(height: 10),
              DocumentationCard(
                title: 'Events',
                child: _bullets(context, <String>[
                  'Create/configure IDEATHON, HACKATHON, or RESEARCH_PAPER as needed.',
                  'Configure DAY_EVENT / EVALUATION_EVENT appropriately.',
                ]),
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.step15,
          title: 'Step 15 — Verify Real Login',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(context, 'Smoke test with a real mobile number registered for the organisation:'),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Open Hackz.',
                'Enter Organisation Code.',
                'Enter registered mobile number.',
                'Request OTP.',
                'Verify real SMS arrives.',
                'Enter OTP.',
                'Confirm tenant dashboard loads.',
                'Verify expected tenant role.',
                'Verify Firestore tenant data loads.',
                'Verify Storage functionality where applicable (upload after rules are published).',
              ]),
              const SizedBox(height: 12),
              _bodyText(
                context,
                'Success proves: Organisation Code → tenant resolution → tenant Firebase init → tenant Auth → '
                'OTP → hkzUsers role → dashboard.',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.verifyTenantSetup,
          title: 'Verify Tenant Setup (Checklist Step 15)',
          subtitle:
              'After a successful real OTP login, confirm organisation readiness — distinct from the login smoke test in Step 15.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _bodyText(
                context,
                'Use orgAdmin (or Hackz SysAdmin) to confirm the tenant is operationally ready:',
              ),
              const SizedBox(height: 12),
              _numberedSteps(context, <String>[
                'Departments exist for all expected academic units.',
                'Problems are imported or authored and activated as needed.',
                'Teams are imported with departments resolved.',
                'Event is created and configured (type, evaluation phases, commercial access if applicable).',
                'Tenant setup / readiness indicators in Hackz show expected progress.',
                'Optional: Team Leader test login can reach innovation submission when event rules allow.',
              ]),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.readiness,
          title: 'Final Readiness Checklist',
          child: DocumentationCard(
            child: _checklist(context, <String>[
              'Firebase project created',
              'Blaze enabled',
              'Firestore created',
              'Storage bucket created',
              'Phone Authentication enabled',
              'SMS region policy configured',
              'Hackz domain(s) authorized on tenant project',
              'Web app registered',
              'Android configuration completed where required',
              'firebaseConfig obtained and registered',
              'Hackz provisioning service authorized in IAM',
              'Tenant registered in Hackz',
              'Organisation created',
              'College Admin provisioned',
              'Hackz orgAdmin provisioned',
              'Departments ready',
              'Problems ready',
              'Teams imported',
              'Event configured',
              'Real OTP login tested successfully',
            ]),
          ),
        ),
        _section(
          id: TenantOnboardingSections.manualAudit,
          title: 'New Tenant Final Configuration Audit',
          subtitle: 'Repeat every manual Firebase / Google Cloud step for each new tenant.',
          child: DocumentationCard(
            child: _checklist(context, <String>[
              'Blaze billing linked on tenant project',
              'Firestore database created (location chosen)',
              'Storage default bucket created',
              'Storage rules published (signed-in Hackz paths)',
              'Authentication → Phone enabled',
              'SMS region policy allows user countries',
              'Authorized domains: ${_hackzAuthorizedDomainExamples.join(", ")} (+ custom domain if used)',
              'Tenant web API key HTTP referrers allow Hackz origins (+ localhost for dev only)',
              'Web app registered; firebaseConfig copied',
              'Android app registered ($_hackzAndroidPackage) with SHA-1/SHA-256 if using mobile',
              'IAM: provisioning SA ($provisioningSaDefault or Control Plane config) with roles/firebaseauth.admin and roles/datastore.user',
              'Hackz SysAdmin: tenant registered in catalog',
              'Organisation created, IAM validated, admins provisioned',
              'Org setup: departments, problems, teams, event',
              'Real OTP login verified end-to-end',
            ]),
          ),
        ),
        _section(
          id: TenantOnboardingSections.previousFixes,
          title: 'Previous Tenant Setup Fixes',
          subtitle:
              'Repeatable manual fixes required by the current Hackz multi-tenant implementation (Problem → Cause → Where → Fix → Verify).',
          child: DocumentationAccordion(items: _previousSetupFixItems()),
        ),
        _section(
          id: TenantOnboardingSections.troubleshooting,
          title: 'Troubleshooting',
          subtitle: 'Expand a topic for checks and fixes.',
          child: DocumentationAccordion(items: _troubleshootingItems()),
        ),
        _section(
          id: TenantOnboardingSections.warnings,
          title: 'Important Warnings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Resource locations',
                body: 'Choose Firebase project and Firestore/Storage locations carefully — they are difficult or impossible to change later.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Real OTP and billing',
                body: 'Real OTP requires Blaze and generates billable SMS usage on the tenant project.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'SMS region before testing',
                body: 'Configure SMS region policy before expecting real OTP delivery.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Never expose service-account keys',
                body: 'Do not share Firebase Admin private keys in email, tickets, or the Register Tenant UI.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'firebaseConfig ≠ service-account key',
                body: 'The Web firebaseConfig object (apiKey, projectId, appId, etc.) is client SDK metadata. '
                    'It is not equivalent to a Firebase Admin service-account private key JSON file.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Do not edit Firebase identifiers',
                body: 'Copy projectId, authDomain, and storageBucket exactly from Firebase Console — '
                    'do not manually change them when registering a tenant.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Tenant catalog delete',
                body: 'Deleting a tenant registration in Hackz removes Control Plane catalog entry only — do not delete the college\'s external Firebase project by mistake.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'IAM least privilege',
                body: 'Grant Hackz provisioning only roles/firebaseauth.admin and roles/datastore.user — not Owner, Editor, or Storage Admin.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.success,
                title: 'Declare completion only after real login',
                body: 'Always test with a real tenant user OTP before declaring onboarding complete.',
              ),
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.optionalAiAnalysis,
          title: 'Optional — Enable AI Analysis',
          subtitle: 'Not required for tenant readiness or normal Hackz operation.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Optional feature',
                body:
                    'AI Analysis is optional. Your tenant is ready for innovation workflows without it. '
                    'When you need originality insights, the organisation must supply its own provider licence '
                    '(for example Turnitin).',
              ),
              const SizedBox(height: 12),
              _bullets(context, <String>[
                'College Admin → AI Analysis.',
                'Select provider → Configure organisation credentials → Test Connection.',
                'Verify which capabilities appear (Similarity %, AI-Writing Indicator, Matching Sources, Full Report).',
                'Only capabilities supported by your licence are shown in Hackz.',
              ]),
              if (onOpenPage != null) ...<Widget>[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => onOpenPage!('ai-analysis'),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('View AI Analysis Setup Guide'),
                  ),
                ),
              ],
            ],
          ),
        ),
        _section(
          id: TenantOnboardingSections.references,
          title: 'Official Firebase References',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _link(context, 'Firebase Console', 'https://console.firebase.google.com/'),
              _link(context, 'Firebase Web Setup', 'https://firebase.google.com/docs/web/setup'),
              _link(context, 'Cloud Firestore', 'https://firebase.google.com/docs/firestore/quickstart'),
              _link(context, 'Cloud Storage', 'https://firebase.google.com/docs/storage/web/start'),
              _link(context, 'Web Phone Authentication', 'https://firebase.google.com/docs/auth/web/phone-auth'),
              _link(context, 'Android Firebase Setup', 'https://firebase.google.com/docs/android/setup'),
              _link(context, 'Android Phone Authentication', 'https://firebase.google.com/docs/auth/android/phone-auth'),
              _link(context, 'Authentication Limits', 'https://firebase.google.com/docs/auth/limits'),
              _link(context, 'Firebase Pricing', 'https://firebase.google.com/pricing'),
              _link(context, 'Google Cloud IAM', 'https://cloud.google.com/iam/docs/grant-role-console'),
            ],
          ),
        ),
      ],
    );
  }
}
