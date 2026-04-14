import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/account.dart';
import '../../providers/app_provider.dart';
import '../../services/sqlite_service.dart';
import '../../services/firebase_service.dart'; // Added this import
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // FIX 1: Look at FirebaseService if AppProvider is empty!
    final account = context.read<AppProvider>().currentAccount ??
        FirebaseService.instance.currentAccount;

    if (account != null) {
      _displayNameController.text = account.displayName ?? '';
      _emailController.text = account.email;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1 (UI): Look at FirebaseService if AppProvider is empty!
    final account = context.watch<AppProvider>().currentAccount ??
        FirebaseService.instance.currentAccount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(account),
            const SizedBox(height: 24),
            _buildEditForm(),
            const SizedBox(height: 32),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic account) {
    final displayName = account?.displayName ?? 'User';
    final email = account?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primaryCyan.withOpacity(0.1),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryCyan,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (account?.role != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                account.role == 'admin' ? 'Admin' : 'Employee',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!_isEditing)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Display Name',
              filled: true,
              fillColor: _isEditing ? Colors.white : AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FIX 2: Email is now Read-Only so Firebase doesn't throw security errors
          TextField(
            controller: _emailController,
            enabled: false, // Locked to false
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email (Cannot be changed)',
              filled: true,
              fillColor: AppTheme.backgroundLight, // Always looks greyed out
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _loadUserData();
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newDisplayName = _displayNameController.text.trim();

      // Only update Name now (Email update logic removed to prevent crashes)
      if (newDisplayName.isNotEmpty && newDisplayName != user.displayName) {
        try {
          await user.updateDisplayName(newDisplayName);

          await FirebaseDatabase.instance.ref('users/${user.uid}').update({
            'displayName': newDisplayName,
          });

          // Sync it back to the local provider
          final provider = context.read<AppProvider>();
          final currentAcc = provider.currentAccount ?? FirebaseService.instance.currentAccount;

          if (currentAcc != null) {
            provider.setCurrentAccount(Account(
              uid: currentAcc.uid,
              email: currentAcc.email,
              role: currentAcc.role,
              displayName: newDisplayName,
            ));
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile name updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print("Name update failed: $e");
        }
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      await SqliteService.instance.clearAllData();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}