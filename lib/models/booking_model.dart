import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  String? b_id;
  String? p_id;
  String? u_id;
  DateTime? start_date_time;
  DateTime? end_date_time;
  double? b_total;
  DateTime? reg_date;
  bool? paid;
  String? paymentId;

  BookingModel({
    this.b_id,
    this.paid,
    this.paymentId,
    this.p_id,
    this.u_id,
    this.start_date_time,
    this.end_date_time,
    this.b_total,
    this.reg_date,
  });

  factory BookingModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return BookingModel(
      b_id: snapshot['b_id'],
      p_id: snapshot['p_id'],
      u_id: snapshot['u_id'],
      paid: snapshot['paid'],
      paymentId: snapshot['paymentId'],
      start_date_time: snapshot['start_date_time'].toDate(),
      end_date_time: snapshot['end_date_time'].toDate(),
      b_total: snapshot['b_total'],
      reg_date: snapshot['reg_date'].toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'b_id': b_id,
        'p_id': p_id,
        'u_id': u_id,
        'paid': paid,
        'paymentId': paymentId,
        'start_date_time': start_date_time,
        'end_date_time': end_date_time,
        'b_total': b_total,
        'reg_date': reg_date,
      };
}
