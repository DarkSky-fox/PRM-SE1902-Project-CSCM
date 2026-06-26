class PromotionModel {
  final int? promotionId;
  final String promotionName;
  final double discountPercent;
  final String startDate;
  final String endDate;

  PromotionModel({
    this.promotionId,
    required this.promotionName,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'PromotionID': promotionId,
      'PromotionName': promotionName,
      'DiscountPercent': discountPercent,
      'StartDate': startDate,
      'EndDate': endDate,
    };
  }

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      promotionId: map['PromotionID'] as int?,
      promotionName: map['PromotionName'] as String,
      discountPercent: map['DiscountPercent'] as double,
      startDate: map['StartDate'] as String,
      endDate: map['EndDate'] as String,
    );
  }
}