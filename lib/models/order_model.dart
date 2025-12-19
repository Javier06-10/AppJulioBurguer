class Order {
  final String id;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      total: (data['total'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'].toDate(),
    );
  }
}
