/// Centralized Firestore keys for `hkzPlatformSettings/config`.
abstract final class PlatformSettingKeys {
  PlatformSettingKeys._();

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

  // Problem
  static const String requireProblemCategoryTheme = 'requireProblemCategoryTheme';
  static const String maxProblemAttachments = 'maxProblemAttachments';
  static const String allowCrossDepartmentSubmissions = 'allowCrossDepartmentSubmissions';

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

  // Upload
  static const String maxUploadSizeMB = 'maxUploadSizeMB';
  static const String allowedImageFormats = 'allowedImageFormats';
  static const String allowedDocumentFormats = 'allowedDocumentFormats';
  static const String allowedVideoFormats = 'allowedVideoFormats';
}
