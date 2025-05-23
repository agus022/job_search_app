import 'package:job_search_oficial/entities/calification.dart';

enum ServiceState { pendent, accepted, inProgress, completed, cancelled }

enum PaymentMethod { cash, creditCard, debitCcard }

// Crear mapper
class Service {
  final String? id;
  final String clientRef;
  final String oficialRef;
  final DateTime date;
  final String address;
  final String description;
  final ServiceState state;
  final double price;
  final PaymentMethod paymentMethod;
  final List<Calification>? califications;

  Service({
    this.id,
    required this.clientRef,
    required this.oficialRef,
    required this.date,
    required this.address,
    required this.description,
    required this.state,
    required this.price,
    required this.paymentMethod,
    this.califications,
  });
}
