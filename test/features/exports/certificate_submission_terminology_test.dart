import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_submission_terminology.dart';

void main() {
  group('CertificateSubmissionTerminology', () {
    test('presenting phrases', () {
      expect(CertificateSubmissionTerminology.presentingPhrase('Idea'), 'and presenting the idea');
      expect(CertificateSubmissionTerminology.presentingPhrase('Prototype'), 'and presenting the prototype');
      expect(
        CertificateSubmissionTerminology.presentingPhrase('Paper'),
        'and presenting the research paper',
      );
    });

    test('for-the phrases', () {
      expect(CertificateSubmissionTerminology.forThePhrase('Idea'), 'for the idea');
      expect(CertificateSubmissionTerminology.forThePhrase('Prototype'), 'for the prototype');
      expect(CertificateSubmissionTerminology.forThePhrase('Paper'), 'for the research paper');
    });
  });
}
