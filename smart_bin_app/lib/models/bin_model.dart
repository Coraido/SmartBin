import 'package:cloud_firestore/cloud_firestore.dart';

class BinModel {
  final String id;
  final String name;
  final int fillLevel;
  final String status;
  final String estimatedFullTime;
  final DateTime lastEmptied;
  final DateTime lastUpdated;

  BinModel({
    required this.id,
    required this.name,
    required this.fillLevel,
    required this.status,
    required this.estimatedFullTime,
    required this.lastEmptied,
    required this.lastUpdated,
  });

  // Get status based on fill level
  static String getStatus(int fillLevel) {
    if (fillLevel >= 80) return 'FULL';
    if (fillLevel >= 40) return 'OK';
    return 'EMPTY';
  }

  // Get color based on status
  static String getStatusColor(String status) {
    switch (status) {
      case 'FULL':
        return 'red';
      case 'OK':
        return 'green';
      default:
        return 'blue';
    }
  }

  // Calculate estimated time until full
  static String calculateEstimatedTime(int fillLevel, DateTime lastEmptied) {
    if (fillLevel >= 95) return '1-2 hours';
    if (fillLevel >= 80) return '3-6 hours';
    if (fillLevel >= 50) return '1-2 days';
    if (fillLevel >= 30) return '3-5 days';
    return '7+ days';
  }

  // Convert from Firestore document
  factory BinModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int fillLevel = data['fillLevel'] ?? 0;
    
    return BinModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Bin',
      fillLevel: fillLevel,
      status: getStatus(fillLevel),
      estimatedFullTime: data['estimatedFullTime'] ?? 
          calculateEstimatedTime(fillLevel, (data['lastEmptied'] as Timestamp?)?.toDate() ?? DateTime.now()),
      lastEmptied: (data['lastEmptied'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'fillLevel': fillLevel,
      'status': status,
      'estimatedFullTime': estimatedFullTime,
      'lastEmptied': Timestamp.fromDate(lastEmptied),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
