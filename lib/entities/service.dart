import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_search_oficial/entities/entities.dart';

enum ServiceState { pendent, accepted, inProgress, completed, cancelled }

enum PaymentMethod { cash, creditCard, debitCard }

class Service {
  final String? id;
  final String clientRef;
  final String oficialRef;
  final DateTime date;
  final String address;
  final String description;
  final ServiceState state;
  final double price;
  final List<PaymentMethod> paymentMethods;
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
    required this.paymentMethods,
    this.califications,
  });

  factory Service.fromMap(Map<String, dynamic> map, {String? docId}) {
    List<PaymentMethod> parsedPayments = [];
    if (map['paymentMethods'] != null) {
      parsedPayments = (map['paymentMethods'] as List<dynamic>)
          .map((e) => PaymentMethod.values.firstWhere(
                (pm) => pm.name == e as String,
                orElse: () => PaymentMethod.cash,
              ))
          .toList();
    }

    List<Calification>? parsedCalifications;
    if (map['califications'] != null) {
      parsedCalifications = (map['califications'] as List<dynamic>)
          .map((e) => Calification.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Service(
      id: docId ?? map['id'] as String?,
      clientRef: map['clientRef'] as String,
      oficialRef: map['oficialRef'] as String,
      date: (map['date'] as Timestamp).toDate(),
      address: map['address'] as String,
      description: map['description'] as String,
      state: ServiceState.values.firstWhere(
        (s) => s.name == map['state'] as String,
        orElse: () => ServiceState.pendent,
      ),
      price: (map['price'] as num).toDouble(),
      paymentMethods: parsedPayments,
      califications: parsedCalifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'clientRef': clientRef,
      'oficialRef': oficialRef,
      'date': Timestamp.fromDate(date),
      'address': address,
      'description': description,
      'state': state.name,
      'price': price,
      'paymentMethods': paymentMethods.map((pm) => pm.name).toList(),
      if (califications != null)
        'califications': califications!.map((c) => c.toMap()).toList(),
    };
  }
}
