import 'package:flutter/material.dart';
import 'package:smart_bin_app/widgets/bin_card.dart';
import 'package:smart_bin_app/models/bin_model.dart';
import 'package:smart_bin_app/services/firebase_service.dart';

class MyBinsScreen extends StatefulWidget {
  const MyBinsScreen({super.key});

  @override
  State<MyBinsScreen> createState() => _MyBinsScreenState();
}

class _MyBinsScreenState extends State<MyBinsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notifications
    await _firebaseService.initializeNotifications();
    
    // Create initial bins if needed (for first run)
    await _firebaseService.createInitialBins();
  }

  Color _getProgressColor(String status) {
    switch (status) {
      case 'FULL':
        return Colors.red;
      case 'OK':
        return Colors.green;
      default:
        return const Color(0xFF64B5F6); // Light blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8EAF6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVERVIEW',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'My Bins',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF3F51B5)),
              onPressed: () {
                // Show notification settings or history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications are enabled'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<BinModel>>(
        stream: _firebaseService.getBinsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final bins = snapshot.data ?? [];

          if (bins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No bins found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first SmartBin to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Find last emptied bin for the bottom section
          BinModel? lastEmptied;
          DateTime? mostRecentEmpty;
          
          for (var bin in bins) {
            if (mostRecentEmpty == null || bin.lastEmptied.isAfter(mostRecentEmpty)) {
              mostRecentEmpty = bin.lastEmptied;
              lastEmptied = bin;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bins.length,
                  itemBuilder: (context, index) {
                    final bin = bins[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: BinCard(
                        binId: bin.id,
                        binName: bin.name,
                        fillLevel: bin.fillLevel,
                        status: bin.status,
                        estimatedFullTime: bin.estimatedFullTime,
                        progressColor: _getProgressColor(bin.status),
                        onEmptied: () async {
                          await _firebaseService.markBinAsEmptied(bin.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${bin.name} marked as emptied'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              // Bottom info section
              if (lastEmptied != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LAST EMPTIED',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastEmptied.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeAgo(lastEmptied.lastEmptied),
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'ESTIMATED FULL IN',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastEmptied.estimatedFullTime,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
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
}
