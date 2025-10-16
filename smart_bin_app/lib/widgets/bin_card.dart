import 'package:flutter/material.dart';

class BinCard extends StatelessWidget {
  final String binId;
  final String binName;
  final int fillLevel;
  final String status;
  final String estimatedFullTime;
  final Color progressColor;
  final VoidCallback? onEmptied;

  const BinCard({
    super.key,
    required this.binId,
    required this.binName,
    required this.fillLevel,
    required this.status,
    required this.estimatedFullTime,
    required this.progressColor,
    this.onEmptied,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: fillLevel / 100,
                      strokeWidth: 10,
                      backgroundColor: progressColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$fillLevel%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Bin Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    binName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fill level: $fillLevel%',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated full in $estimatedFullTime',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusTextColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'FULL':
        return const Color(0xFFFFEBEE); // Light red
      case 'OK':
        return const Color(0xFFE8F5E9); // Light green
      default:
        return const Color(0xFFE3F2FD); // Light blue
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'FULL':
        return const Color(0xFFD32F2F); // Dark red
      case 'OK':
        return const Color(0xFF388E3C); // Dark green
      default:
        return const Color(0xFF1976D2); // Dark blue
    }
  }
}
