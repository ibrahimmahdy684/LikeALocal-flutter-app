import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _authMode = 0; // 0 = login, 1 = signup
  UserRole _selectedRole = UserRole.tourist;
  String? _errorMessage;

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == 0 ? 1 : 0;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _errorMessage = null);

    try {
      if (_authMode == 0) {
        // Login
        await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Sign up
        await authProvider.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      String msg = error.toString().replaceAll('Exception: ', '');
      if (msg.contains('CONFIGURATION_NOT_FOUND') || msg.contains('internal-error')) {
        msg = 'Firebase Auth not enabled. Go to Firebase Console > Authentication > Sign-in method > Enable Email/Password.';
      } else if (msg.contains('email-already-in-use')) {
        msg = 'This email is already registered. Try signing in.';
      } else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        msg = 'Invalid email or password.';
      } else if (msg.contains('user-not-found')) {
        msg = 'No account found. Please sign up first.';
      } else if (msg.contains('weak-password')) {
        msg = 'Password too weak. Use at least 6 characters.';
      }
      setState(() {
        _errorMessage = msg;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                _authMode == 0 ? 'Welcome Back' : 'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _authMode == 0
                    ? 'Sign in to continue exploring'
                    : 'Join the LikeALocal community',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.destructive,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Name field (sign up only)
              if (_authMode == 1) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.muted),
                  ),
                  validator: (value) {
                    if (_authMode == 1 &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.muted),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: AppColors.muted),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Role selection (sign up only)
              if (_authMode == 1) ...[
                Text(
                  'I am a...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.tourist),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.tourist
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == UserRole.tourist
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _selectedRole == UserRole.tourist ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.explore,
                                color: _selectedRole == UserRole.tourist
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tourist',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedRole == UserRole.tourist
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.local),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.local
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == UserRole.local
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _selectedRole == UserRole.local ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_city,
                                color: _selectedRole == UserRole.local
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Local',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedRole == UserRole.local
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
              ],

              SizedBox(height: 8),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _authMode == 0 ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Toggle auth mode
              TextButton(
                onPressed: _toggleAuthMode,
                child: Text(
                  _authMode == 0
                      ? "Don't have an account? Sign Up"
                      : 'Already have an account? Sign In',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
