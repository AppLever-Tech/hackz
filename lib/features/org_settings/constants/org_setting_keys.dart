/// Centralized keys for the per-org settings document.
/// Stored under `hkzOrganizations/{orgId}/settings/org_settings`.
abstract final class OrgSettingKeys {
  OrgSettingKeys._();

  // Team — formation
  static const String minStudentsPerTeam = 'minStudentsPerTeam';
  static const String maxStudentsPerTeam = 'maxStudentsPerTeam';
  static const String maxTeamsPerFaculty = 'maxTeamsPerFaculty';

  // Team — edit
  static const String allowPendingSubmissionTeamEdit = 'allowPendingSubmissionTeamEdit';
  static const String freezeTeamAfterSubmitted = 'freezeTeamAfterSubmitted';
  static const String allowStudentSwitchAfterRejection = 'allowStudentSwitchAfterRejection';

  // Idea — submission
  static const String maxIdeasPerProblem = 'maxIdeasPerProblem';
  static const String allowIdeaResubmissionAfterRejection = 'allowIdeaResubmissionAfterRejection';
  static const String requirePaymentBeforeSubmission = 'requirePaymentBeforeSubmission';

  // Idea — evaluation
  static const String minJudgesPerIdea = 'minJudgesPerIdea';
  static const String maxJudgesPerIdea = 'maxJudgesPerIdea';
  static const String showJudgeCommentsToStudents = 'showJudgeCommentsToStudents';
  static const String allowFacultyAsJudges = 'allowFacultyAsJudges';

  // Problem
  static const String requireProblemCategoryTheme = 'requireProblemCategoryTheme';
  static const String maxProblemAttachments = 'maxProblemAttachments';
  static const String allowCrossDepartmentSubmissions = 'allowCrossDepartmentSubmissions';

  // Problem — submission limits
  // Default prefilled into the authoring "Max Ideas Allowed" field on new
  // problems. The hard upper bound the College Admin will accept when
  // authoring a problem; the field cannot exceed this.
  static const String defaultMaxIdeasPerProblem = 'defaultMaxIdeasPerProblem';
  static const String maxAllowedIdeasPerProblem = 'maxAllowedIdeasPerProblem';

  // Payment
  static const String coordinatorApprovalRequired = 'coordinatorApprovalRequired';
  static const String requirePaymentScreenshot = 'requirePaymentScreenshot';
  static const String requirePaymentAmount = 'requirePaymentAmount';

  // User / auth
  static const String accessCodeLength = 'accessCodeLength';
  static const String requireAccessCode = 'requireAccessCode';
  static const String allowDuplicateMobile = 'allowDuplicateMobile';

  // Leaderboard
  static const String enableLeaderboard = 'enableLeaderboard';
  static const String judgeScoreWeight = 'judgeScoreWeight';
  static const String innovationScoreWeight = 'innovationScoreWeight';

  // Ideathon
  static const String minShortlistedIdeasRequired = 'minShortlistedIdeasRequired';
  static const String prototypeSelectionThreshold = 'prototypeSelectionThreshold';

  // Upload
  static const String maxUploadSizeMB = 'maxUploadSizeMB';
  static const String allowedImageFormats = 'allowedImageFormats';
  static const String allowedDocumentFormats = 'allowedDocumentFormats';
  static const String allowedVideoFormats = 'allowedVideoFormats';
}
