import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class BinData {
  final String id;
  final String name;
  final int fillLevel;
  final String status;
  final String estimatedFullIn;
  final DateTime? lastUpdated;

  BinData({
    required this.id,
    required this.name,
    required this.fillLevel,
    required this.status,
    required this.estimatedFullIn,
    this.lastUpdated,
  });

  factory BinData.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return BinData(
      id: snapshot.key ?? 'unknown',
      name: data['name'] ?? 'Unknown Bin',
      fillLevel: data['fill_level'] ?? 0,
      status: data['status'] ?? 'EMPTY',
      estimatedFullIn: data['estimated_full_in'] ?? '7+ days',
      lastUpdated: data['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['last_updated'])
          : null,
    );
  }

  Color getProgressColor() {
    if (fillLevel >= 80) {
      return Colors.red;
    } else if (fillLevel >= 50) {
      return Colors.orange;
    } else if (fillLevel >= 30) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
}
