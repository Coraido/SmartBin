import 'package:flutter/material.dart';
import 'package:smart_bin_app/widgets/bin_card.dart';
import 'package:smart_bin_app/models/bin_data.dart';
import 'package:smart_bin_app/services/firebase_service.dart';
import 'package:smart_bin_app/services/settings_service.dart';

class MyBinsScreen extends StatefulWidget {
  const MyBinsScreen({super.key});

  @override
  State<MyBinsScreen> createState() => _MyBinsScreenState();
}

class _MyBinsScreenState extends State<MyBinsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final SettingsService _settingsService = SettingsService();
  final Set<String> _notifiedBins = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notifications if enabled
    if (_settingsService.notificationsEnabled) {
      await _firebaseService.initializeNotifications();
    }
    
    // Create initial bin if needed (for first run)
    await _firebaseService.createInitialBin();
  }

  void _checkBinAlerts(List<BinData> bins) {
    if (!_settingsService.notificationsEnabled || !_settingsService.fullBinAlerts) {
      return;
    }

    for (var bin in bins) {
      if (_settingsService.shouldAlert(bin.fillLevel) && !_notifiedBins.contains(bin.id)) {
        // Send notification
        _firebaseService.sendBinAlert(bin);
        _notifiedBins.add(bin.id);
        
        // Show in-app notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${bin.name} is ${bin.fillLevel}% full!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to bin details
                },
              ),
            ),
          );
        }
      } else if (bin.fillLevel < _settingsService.alertThreshold) {
        // Remove from notified set if bin is no longer full
        _notifiedBins.remove(bin.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OVERVIEW',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'My Bins',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
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
              color: theme.cardTheme.color,
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
              icon: Icon(Icons.notifications_outlined, color: theme.primaryColor),
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
      body: StreamBuilder<List<BinData>>(
        stream: _firebaseService.getAllBinsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Check for alerts when data updates
            _checkBinAlerts(snapshot.data!);
          }
          
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

          // Find last emptied bin for the bottom section (simplified for now)
          
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
                        estimatedFullTime: bin.estimatedFullIn,
                        progressColor: bin.getProgressColor(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
