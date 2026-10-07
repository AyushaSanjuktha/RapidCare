/// Maps to the response from POST /classify-injury:
///   { "injury_type": ..., "confidence": ..., "all_probabilities": {...} }
class InjuryClassification {
  final String injuryType;
  final double confidence;
  final Map<String, double> allProbabilities;

  InjuryClassification({
    required this.injuryType,
    required this.confidence,
    required this.allProbabilities,
  });

  factory InjuryClassification.fromJson(Map<String, dynamic> json) {
    final rawProbs = json['all_probabilities'] as Map<String, dynamic>?;
    final allProbs = rawProbs?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        {};

    return InjuryClassification(
      injuryType: json['injury_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      allProbabilities: allProbs,
    );
  }
}
