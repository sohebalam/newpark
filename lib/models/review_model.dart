import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  late String r_id; // Unique identifier for the review
  late String b_id; // ID of the business being reviewed
  late String u_id; // ID of the user who wrote the review
  late String description; // Text description of the review
  late int rating; // Overall rating (1-5 stars)
  late int safetyRating; // Safety rating (1-5 stars)
  late DateTime date; // Date and time the review was created

  Review({
    required this.r_id,
    required this.b_id,
    required this.u_id,
    required this.description,
    required this.rating,
    required this.safetyRating,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      r_id: json['r_id'],
      b_id: json['b_id'],
      u_id: json['u_id'],
      description: json['description'],
      rating: json['rating'],
      safetyRating: json['safety_rating'],
      date: DateTime.parse(json['reg_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'r_id': r_id,
        'b_id': b_id,
        'u_id': u_id,
        'description': description,
        'rating': rating,
        'safety_rating': safetyRating,
        'reg_date': date.toIso8601String(),
      };
}
