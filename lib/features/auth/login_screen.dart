import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      print('Login button pressed, calling userProvider.login');
      
      final errorMessage = await userProvider.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        print('Login completed, errorMessage: $errorMessage, isLoggedIn: ${userProvider.isLoggedIn}');
        
        if (errorMessage != null) {
          // Show error message if login failed
          Utils.showSnackBar(
            context, 
            'Login failed: $errorMessage', 
            isError: true
          );
        } else if (!userProvider.isLoggedIn) {
          // This is a fallback in case login fails but no error is returned
          Utils.showSnackBar(
            context, 
            'Login failed. Please try again.', 
            isError: true
          );
        } else {
          // Explicitly navigate to dashboard if login succeeded
          print('Login successful, navigating to dashboard');
          context.go(AppConstants.routeDashboard);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.4),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and welcome animation
                      _buildHeaderSection(context),
                      
                      // Form content section
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Password field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                        ? Icons.visibility_outlined 
                                        : Icons.visibility_off_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Forgot password functionality
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8, 
                                      horizontal: 8
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Login button
                              _buildLoginButton(context),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Social login section
                      _buildSocialLoginSection(context),
                      
                      const SizedBox(height: 24),
                      
                      // Sign up section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppConstants.routeSignup),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8, 
                                horizontal: 8
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          // Logo - can be replaced with your app's actual logo
          Hero(
            tag: 'app_logo',
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.forum_outlined,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome Back!',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue your debate journey',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }
  
  Widget _buildLoginButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.primary.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
  
  Widget _buildSocialLoginSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata_rounded,
              color: Colors.red.shade400,
              onPressed: () {},
            ),
            const SizedBox(width: 20),
            _buildSocialButton(
              icon: Icons.facebook_rounded,
              color: Colors.blue.shade700,
              onPressed: () {},
            ),
            const SizedBox(width: 20),
            _buildSocialButton(
              icon: Icons.apple_rounded,
              color: Colors.black87,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
