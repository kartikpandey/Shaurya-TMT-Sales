/// A sellable item from the product catalog.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.size,
    required this.grade,
    required this.unitPrice,
    this.unit = 'pcs',
    this.stock = 0,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String size;
  final String grade;
  final double unitPrice;
  final String unit;
  final int stock;
  final String? imageUrl;

  bool get inStock => stock > 0;

  Product copyWith({int? stock, double? unitPrice}) => Product(
    id: id,
    name: name,
    size: size,
    grade: grade,
    unitPrice: unitPrice ?? this.unitPrice,
    unit: unit,
    stock: stock ?? this.stock,
    imageUrl: imageUrl,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'grade': grade,
    'unitPrice': unitPrice,
    'unit': unit,
    'stock': stock,
    'imageUrl': imageUrl,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    size: json['size'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    unit: json['unit'] as String? ?? 'pcs',
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    imageUrl: json['imageUrl'] as String?,
  );
}
