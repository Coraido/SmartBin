import 'package:flutter/material.dart';
import 'package:smart_bin_app/services/settings_service.dart';
import 'package:smart_bin_app/services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  'Enable Notifications',
                  'Receive alerts about your bins',
                  Icons.notifications_active,
                  _settingsService.notificationsEnabled,
                  (value) async {
                    await _settingsService.setNotificationsEnabled(value);
                    if (value) {
                      await _firebaseService.initializeNotifications();
                    }
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Full Bin Alerts',
                  'Get notified when bins are full',
                  Icons.warning_amber_rounded,
                  _settingsService.fullBinAlerts,
                  (value) async {
                    await _settingsService.setFullBinAlerts(value);
                  },
                  enabled: _settingsService.notificationsEnabled,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Daily Summary',
                  'Daily report of all bins',
                  Icons.summarize,
                  _settingsService.dailySummary,
                  (value) async {
                    await _settingsService.setDailySummary(value);
                  },
                  enabled: _settingsService.notificationsEnabled,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Sound',
                  'Play sound with notifications',
                  Icons.volume_up,
                  _settingsService.soundEnabled,
                  (value) async {
                    await _settingsService.setSoundEnabled(value);
                  },
                  enabled: _settingsService.notificationsEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Alert Settings
          Text(
            'Alert Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alert Threshold',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      '${_settingsService.alertThreshold}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Get notified when bin reaches this level',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _settingsService.alertThreshold.toDouble(),
                  min: 50,
                  max: 95,
                  divisions: 9,
                  label: '${_settingsService.alertThreshold}%',
                  activeColor: theme.primaryColor,
                  onChanged: (value) async {
                    await _settingsService.setAlertThreshold(value.toInt());
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Settings
          Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSwitchTile(
              'Dark Mode',
              _settingsService.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
              Icons.dark_mode,
              _settingsService.isDarkMode,
              (value) async {
                await _settingsService.toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Data Management
          Text(
            'Data Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  'Export Data',
                  'Download your bin data',
                  Icons.download,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting data...')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  'Clear History',
                  'Remove old records',
                  Icons.history,
                  () {
                    _showClearHistoryDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  'Help & Support',
                  'Get help with SmartBin',
                  Icons.help_outline,
                  () {
                    // Help screen
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip,
                  () {
                    // Privacy policy
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  'About SmartBin',
                  'Version 1.0.0',
                  Icons.info_outline,
                  () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? theme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? theme.textTheme.bodyLarge?.color : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? theme.textTheme.bodySmall?.color : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will remove all historical data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SmartBin'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartBin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F51B5),
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'An IoT-based waste management system for smart homes and offices.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 SmartBin Team',
              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
