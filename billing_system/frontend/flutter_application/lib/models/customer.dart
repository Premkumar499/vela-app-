/// Customer model matching the Flask API response.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String area;
  final String gstin;
  final double creditLimit;
  final double balance;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email = '',
    this.area = '',
    this.gstin = '',
    this.creditLimit = 0,
    this.balance = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id:          json['id'].toString(),
      name:        json['name'] as String,
      phone:       json['phone'] as String? ?? '',
      address:     json['address'] as String? ?? '',
      email:       json['email'] as String? ?? '',
      area:        json['area'] as String? ?? '',
      gstin:       json['gstin'] as String? ?? '',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      balance:     (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'email': email,
        'area': area,
        'gstin': gstin,
        'credit_limit': creditLimit,
        'balance': balance,
      };

  /// Walk-in customer singleton used as default selection.
  static const Customer walkIn = Customer(
    id: '00000000-0000-0000-0000-000000000000',
    name: 'Walk-in Customer',
    phone: '',
    address: '',
    area: 'General',
  );

  @override
  String toString() => 'Customer($id, $name)';
}
