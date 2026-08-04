class DealerSummary {
  final int dealerCode;
  final String name;

  const DealerSummary({
    required this.dealerCode,
    required this.name,
  });

  factory DealerSummary.fromMap(Map<String, dynamic> map) {
    return DealerSummary(
      dealerCode: map['dealer_code'] as int,
      name: map['name'] as String,
    );
  }
}