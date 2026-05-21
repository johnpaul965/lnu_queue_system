// lib/core/constants/document_requirements.dart

class DocumentRequirement {
  final String name;
  final List<String> requirements;
  final String estimatedProcessingTime;
  final String notes;
  final double baseFee;

  const DocumentRequirement({
    required this.name,
    required this.requirements,
    required this.estimatedProcessingTime,
    required this.notes,
    required this.baseFee,
  });
}

class DocumentRequirements {
  static const Map<String, DocumentRequirement> _data = {
    'Transcript of Records': DocumentRequirement(
      name: 'Transcript of Records',
      requirements: [
        'Accomplished Request Form (F-REG011)',
        'School ID (original)',
        'Proof of payment / OR from Cashier',
        'If with additional units: signature of VPSD & LIBRARY',
      ],
      estimatedProcessingTime: '5–7 working days',
      notes:
          'Processing time may vary depending on volume. Please indicate exact number of TOR sets needed.',
      baseFee: 150.00,
    ),
    'Certificate of Enrollment': DocumentRequirement(
      name: 'Certificate of Enrollment',
      requirements: [
        'School ID (original)',
        'Accomplished Request Form',
        'Proof of enrollment / registration form',
      ],
      estimatedProcessingTime: '1–2 working days',
      notes: 'Available same day for current semester enrollees.',
      baseFee: 50.00,
    ),
    'Certificate of Graduation': DocumentRequirement(
      name: 'Certificate of Graduation',
      requirements: [
        'School ID or any valid government-issued ID',
        'Accomplished Request Form',
        'Proof of payment / OR from Cashier',
        'Clearance form (if applicable)',
      ],
      estimatedProcessingTime: '3–5 working days',
      notes: 'Must present valid ID. Alumni must show graduation documents.',
      baseFee: 100.00,
    ),
    'Good Moral Certificate': DocumentRequirement(
      name: 'Good Moral Certificate',
      requirements: [
        'School ID (original)',
        'Accomplished Request Form',
        'Proof of payment / OR from Cashier',
        '2x2 ID photo with white background',
      ],
      estimatedProcessingTime: '2–3 working days',
      notes: 'For employment or scholarship use, state the purpose clearly.',
      baseFee: 50.00,
    ),
    'Diploma (Replacement)': DocumentRequirement(
      name: 'Diploma (Replacement)',
      requirements: [
        'Affidavit of Loss (notarized)',
        'Any valid government-issued ID',
        'Accomplished Request Form',
        'Proof of payment / OR from Cashier',
        'Notarized authorization letter (if representative)',
      ],
      estimatedProcessingTime: '7–14 working days',
      notes:
          'Lost diploma replacement requires notarized affidavit. Processing time may vary.',
      baseFee: 500.00,
    ),
    'Authentication of Documents': DocumentRequirement(
      name: 'Authentication of Documents',
      requirements: [
        'Original document to be authenticated',
        'School ID or valid government ID',
        'Accomplished Request Form',
        'Proof of payment / OR from Cashier',
      ],
      estimatedProcessingTime: '1–3 working days',
      notes: 'Bring original document. Authenticated copies only.',
      baseFee: 75.00,
    ),
    'Transfer Credentials': DocumentRequirement(
      name: 'Transfer Credentials',
      requirements: [
        'Honorable Dismissal request letter',
        'School ID (original)',
        'Accomplished Request Form',
        'Proof of payment / OR from Cashier',
        'Clearance from all departments',
        'Acceptance letter from the new school (if available)',
      ],
      estimatedProcessingTime: '5–7 working days',
      notes:
          'Clearance from all offices required before processing. Coordinate with the Office of the Registrar.',
      baseFee: 200.00,
    ),
  };

  static DocumentRequirement? forName(String name) => _data[name];

  static DocumentRequirement getDefault() => const DocumentRequirement(
        name: 'Document',
        requirements: ['Valid School ID', 'Accomplished Request Form'],
        estimatedProcessingTime: '3–5 working days',
        notes: 'Please check with the Registrar for specific requirements.',
        baseFee: 0,
      );
}
