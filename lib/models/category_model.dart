class CategoryModel {
  final int? categoryId;
  final String categoryName;

  CategoryModel({
    this.categoryId,
    required this.categoryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'CategoryID': categoryId,
      'CategoryName': categoryName,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['CategoryID'] as int?,
      categoryName: map['CategoryName'] as String,
    );
  }
}