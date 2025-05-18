enum ServiceState { pendent, accepted, in_progress, completed, cancelled }

enum PaymentMethod { cash, creadit_card, debit_card }

class Service {
  final String? id;
  final String clientRef;
  final String clienteRef;
  final DateTime date;
  final String address;
  final String description;
  final ServiceState state;
  final double price;
  final PaymentMethod paymentMethod;

  Service({
    this.id,
    required this.clientRef,
    required this.clienteRef,
    required this.date,
    required this.address,
    required this.description,
    required this.state,
    required this.price,
    required this.paymentMethod,
  });
}
