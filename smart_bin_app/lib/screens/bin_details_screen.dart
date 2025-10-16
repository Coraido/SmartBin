import 'package:flutter/material.dart';
import 'package:smart_bin_app/models/bin_model.dart';
import 'package:smart_bin_app/services/firebase_service.dart';

class BinDetailsScreen extends StatelessWidget {
  final BinModel bin;

  const BinDetailsScreen({super.key, required this.bin});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    
    Color statusColor = bin.status == 'FULL'
        ? Colors.red
        : bin.status == 'OK'
            ? Colors.green
            : Colors.blue;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(bin.name),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu(context, firebaseService);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3F51B5), statusColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: bin.fillLevel / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${bin.fillLevel}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            bin.status,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Full in ${bin.estimatedFullTime}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Information Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bin Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Cards
                  _buildInfoCard(
                    'Fill Level',
                    '${bin.fillLevel}%',
                    Icons.water_drop,
                    statusColor,
                    'Current waste level',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Last Updated',
                    _formatDateTime(bin.lastUpdated),
                    Icons.update,
                    const Color(0xFF3F51B5),
                    _getTimeAgo(bin.lastUpdated),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Last Emptied',
                    _formatDateTime(bin.lastEmptied),
                    Icons.delete_sweep,
                    const Color(0xFF00897B),
                    _getTimeAgo(bin.lastEmptied),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Estimated Full',
                    bin.estimatedFullTime,
                    Icons.schedule,
                    const Color(0xFFFF6F00),
                    'Based on current fill rate',
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Mark as Emptied',
                          Icons.check_circle,
                          Colors.green,
                          () async {
                            await firebaseService.markBinAsEmptied(bin.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bin marked as emptied!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Delete Bin',
                          Icons.delete_forever,
                          Colors.red,
                          () {
                            _showDeleteConfirmation(context, firebaseService);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tips Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber[700], size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Smart Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getTipForStatus(bin.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[900],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getTipForStatus(String status) {
    switch (status) {
      case 'FULL':
        return '⚠️ This bin is full and needs immediate attention. Empty it soon to prevent overflow and maintain hygiene.';
      case 'OK':
        return '✓ This bin is at a healthy level. Continue monitoring and plan to empty when it reaches 80%.';
      default:
        return '✓ This bin is empty and ready for use. You can expect several days before it needs emptying.';
    }
  }

  void _showOptionsMenu(BuildContext context, FirebaseService firebaseService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF3F51B5)),
              title: const Text('Edit Bin Name'),
              onTap: () {
                Navigator.pop(context);
                // Add edit functionality here
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFFFF6F00)),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add notification settings here
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Bin'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, firebaseService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bin?'),
        content: Text('Are you sure you want to delete ${bin.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await firebaseService.deleteBin(bin.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bin deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
