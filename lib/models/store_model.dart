class StoreModel {
  final int? storeId;
  final String storeName;
  final String? address;
  final String? phone;
  final String? status;
  final String? openTime;
  final String? closeTime;

  StoreModel({
    this.storeId,
    required this.storeName,
    this.address,
    this.phone,
    this.status,
    this.openTime,
    this.closeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'StoreID': storeId,
      'StoreName': storeName,
      'Address': address,
      'Phone': phone,
      'Status': status,
      'OpenTime': openTime,
      'CloseTime': closeTime,
    };
  }

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      storeId: map['StoreID'] as int?,
      storeName: map['StoreName'] as String,
      address: map['Address'] as String?,
      phone: map['Phone'] as String?,
      status: map['Status'] as String?,
      openTime: map['OpenTime'] as String?,
      closeTime: map['CloseTime'] as String?,
    );
  }
}