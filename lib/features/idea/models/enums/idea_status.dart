enum IdeaStatus {
  pendingSubmission('pendingSubmission'),
  submitted('submitted'),
  underReview('underReview'),
  evaluated('evaluated'),
  approved('approved'),
  rejected('rejected');

  const IdeaStatus(this.value);
  final String value;

  static IdeaStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    switch (normalized) {
      case 'pendingsubmission':
        return IdeaStatus.pendingSubmission;
      case 'underreview':
        return IdeaStatus.underReview;
      case 'evaluated':
        return IdeaStatus.evaluated;
      case 'approved':
        return IdeaStatus.approved;
      case 'rejected':
        return IdeaStatus.rejected;
      case 'submitted':
        return IdeaStatus.submitted;
      default:
        return IdeaStatus.submitted;
    }
  }
}
