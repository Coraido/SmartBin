import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _fullBinAlerts = true;
  bool _dailySummary = false;
  bool _soundEnabled = true;
  int _alertThreshold = 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your profile',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                _buildSwitchTile(
                  'Enable Notifications',
                  'Receive alerts about your bins',
                  Icons.notifications_active,
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Full Bin Alerts',
                  'Get notified when bins are full',
                  Icons.warning_amber_rounded,
                  _fullBinAlerts,
                  (value) {
                    setState(() {
                      _fullBinAlerts = value;
                    });
                  },
                  enabled: _notificationsEnabled,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Daily Summary',
                  'Daily report of all bins',
                  Icons.summarize,
                  _dailySummary,
                  (value) {
                    setState(() {
                      _dailySummary = value;
                    });
                  },
                  enabled: _notificationsEnabled,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Sound',
                  'Play sound with notifications',
                  Icons.volume_up,
                  _soundEnabled,
                  (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  enabled: _notificationsEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Alert Settings
          const Text(
            'Alert Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: const Color(0xFF3F51B5)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Alert Threshold',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    Text(
                      '$_alertThreshold%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get notified when bin reaches this level',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _alertThreshold.toDouble(),
                  min: 50,
                  max: 95,
                  divisions: 9,
                  label: '$_alertThreshold%',
                  activeColor: const Color(0xFF3F51B5),
                  onChanged: (value) {
                    setState(() {
                      _alertThreshold = value.toInt();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Settings
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                _buildSettingTile(
                  'Theme',
                  'Light mode',
                  Icons.palette,
                  () {
                    // Theme settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  'Language',
                  'English',
                  Icons.language,
                  () {
                    // Language settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  'Units',
                  'Metric',
                  Icons.straighten,
                  () {
                    // Units settings
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Management
          const Text(
            'Data Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout functionality coming soon'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? const Color(0xFF3F51B5) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? const Color(0xFF212121) : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? const Color(0xFF757575) : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: const Color(0xFF3F51B5),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3F51B5)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
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
