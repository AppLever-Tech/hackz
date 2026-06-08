import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';

/// Stable ids for the built-in templates. Used as `ScoreModel.templateId` so
/// historical scores stay linked to their rubric across renames.
abstract final class DefaultEvaluationTemplateIds {
  DefaultEvaluationTemplateIds._();

  /// Round-one idea screening rubric.
  static const String ideaEvaluation = 'ideaEvaluation';

  /// Ideathon event rubric.
  static const String ideathon = 'ideathon';
  static const String research = 'research';
  static const String startup = 'startup';
}

/// Built-in evaluation templates seeded into every new org's `org_settings`
/// document. Reused by [OrgSettingsService.seedFor] and by the lazy bootstrap
/// inside [OrgSettingsService.ensureLoaded].
List<EvaluationTemplate> get defaultEvaluationTemplates => _templates;

final List<EvaluationTemplate> _templates = <EvaluationTemplate>[
  EvaluationTemplate(
    templateId: DefaultEvaluationTemplateIds.ideaEvaluation,
    templateName: 'Idea Evaluation Template',
    description: 'Default rubric for initial idea screening and department evaluation.',
    scoringScale: 10,
    isDefault: true,
    active: true,
    criteria: const <EvaluationCriterion>[
      EvaluationCriterion(
        criterionId: 'innovation',
        title: 'Innovation',
        description: 'Originality and novelty of the approach.',
        weight: 0.34,
        minScore: 1,
        maxScore: 10,
        displayOrder: 1,
      ),
      EvaluationCriterion(
        criterionId: 'feasibility',
        title: 'Feasibility',
        description: 'How realistically the idea can be delivered.',
        weight: 0.33,
        minScore: 1,
        maxScore: 10,
        displayOrder: 2,
      ),
      EvaluationCriterion(
        criterionId: 'impact',
        title: 'Impact',
        description: 'Scale and depth of the problem solved.',
        weight: 0.33,
        minScore: 1,
        maxScore: 10,
        displayOrder: 3,
      ),
    ],
  ),
  EvaluationTemplate(
    templateId: DefaultEvaluationTemplateIds.ideathon,
    templateName: 'Ideathon Evaluation Template',
    description:
        'Ideathon event rubric covering innovation, execution, impact, and communication.',
    scoringScale: 10,
    isDefault: false,
    active: true,
    criteria: const <EvaluationCriterion>[
      EvaluationCriterion(
        criterionId: 'innovation',
        title: 'Innovation',
        description: 'Originality and novelty of the approach.',
        weight: 0.20,
        minScore: 1,
        maxScore: 10,
        displayOrder: 1,
      ),
      EvaluationCriterion(
        criterionId: 'technicalImplementation',
        title: 'Technical Implementation',
        description: 'Quality of the engineering and code.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 2,
      ),
      EvaluationCriterion(
        criterionId: 'feasibility',
        title: 'Feasibility',
        description: 'How realistically the idea can be delivered.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 3,
      ),
      EvaluationCriterion(
        criterionId: 'impact',
        title: 'Impact',
        description: 'Scale and depth of the problem solved.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 4,
      ),
      EvaluationCriterion(
        criterionId: 'architectureDesign',
        title: 'Architecture & Design',
        description: 'System design clarity and trade-off awareness.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 5,
      ),
      EvaluationCriterion(
        criterionId: 'demoQuality',
        title: 'Demo Quality',
        description: 'Smoothness and credibility of the live demo.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 6,
      ),
      EvaluationCriterion(
        criterionId: 'communication',
        title: 'Communication & Presentation',
        description: 'Clarity of pitch and answers to questions.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 7,
      ),
      EvaluationCriterion(
        criterionId: 'documentation',
        title: 'Documentation',
        description: 'Completeness of supporting documentation.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 8,
      ),
    ],
  ),
  EvaluationTemplate(
    templateId: DefaultEvaluationTemplateIds.research,
    templateName: 'Research & Publication Evaluation',
    description: 'For research-oriented submissions with publication potential.',
    scoringScale: 10,
    isDefault: false,
    active: true,
    criteria: const <EvaluationCriterion>[
      EvaluationCriterion(
        criterionId: 'novelty',
        title: 'Novelty',
        description: 'Originality of the research contribution.',
        weight: 0.20,
        minScore: 1,
        maxScore: 10,
        displayOrder: 1,
      ),
      EvaluationCriterion(
        criterionId: 'researchDepth',
        title: 'Research Depth',
        description: 'Depth of analysis, literature review, methodology.',
        weight: 0.20,
        minScore: 1,
        maxScore: 10,
        displayOrder: 2,
      ),
      EvaluationCriterion(
        criterionId: 'validation',
        title: 'Validation',
        description: 'Soundness of experiments, results, and reproducibility.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 3,
      ),
      EvaluationCriterion(
        criterionId: 'documentation',
        title: 'Documentation',
        description: 'Quality of write-up and supporting material.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 4,
      ),
      EvaluationCriterion(
        criterionId: 'publicationPotential',
        title: 'Publication Potential',
        description: 'Likelihood of acceptance at a credible venue.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 5,
      ),
      EvaluationCriterion(
        criterionId: 'technicalAccuracy',
        title: 'Technical Accuracy',
        description: 'Correctness of claims, math, and citations.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 6,
      ),
    ],
  ),
  EvaluationTemplate(
    templateId: DefaultEvaluationTemplateIds.startup,
    templateName: 'Startup / Product Pitch Evaluation',
    description: 'For product-led ideas and startup pitches.',
    scoringScale: 10,
    isDefault: false,
    active: true,
    criteria: const <EvaluationCriterion>[
      EvaluationCriterion(
        criterionId: 'marketFit',
        title: 'Market Fit',
        description: 'Strength of the problem-solution-market alignment.',
        weight: 0.20,
        minScore: 1,
        maxScore: 10,
        displayOrder: 1,
      ),
      EvaluationCriterion(
        criterionId: 'scalability',
        title: 'Scalability',
        description: 'Ability to grow without proportional cost.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 2,
      ),
      EvaluationCriterion(
        criterionId: 'businessViability',
        title: 'Business Viability',
        description: 'Revenue model and unit economics.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 3,
      ),
      EvaluationCriterion(
        criterionId: 'innovation',
        title: 'Innovation',
        description: 'Defensible differentiation vs. existing solutions.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 4,
      ),
      EvaluationCriterion(
        criterionId: 'demo',
        title: 'Demo',
        description: 'Working product or prototype.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 5,
      ),
      EvaluationCriterion(
        criterionId: 'presentation',
        title: 'Presentation',
        description: 'Storytelling and pitch delivery.',
        weight: 0.10,
        minScore: 1,
        maxScore: 10,
        displayOrder: 6,
      ),
      EvaluationCriterion(
        criterionId: 'productReadiness',
        title: 'Product Readiness',
        description: 'How close the product is to launch.',
        weight: 0.15,
        minScore: 1,
        maxScore: 10,
        displayOrder: 7,
      ),
    ],
  ),
];

/// Firestore-shaped entries for the `evaluationTemplates` field of the
/// `org_settings` document.
List<Map<String, dynamic>> defaultEvaluationTemplatesFirestoreEntries() {
  return defaultEvaluationTemplates
      .map((EvaluationTemplate t) => t.toMap())
      .toList(growable: false);
}
