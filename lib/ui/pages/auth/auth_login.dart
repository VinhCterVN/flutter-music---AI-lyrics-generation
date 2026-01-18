import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../../../provider/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _formAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnimController, curve: Curves.easeOutCubic));

    _formAnimController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _backgroundAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authController = ref.read(authenticationServiceProvider);
      final message = (_isLogin)
          ? authController.signIn(email: _emailController.text.trim(), password: _passwordController.text)
          : authController.signUp(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      if (!context.mounted) return;
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: await message ?? "An error occurred", toastLength: Toast.LENGTH_LONG);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primaryContainer;
    final primaryLighter = Color.lerp(primaryColor, Colors.white, 0.2)!;

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedGradientBackground(controller: _backgroundAnimController),

          ..._buildFloatingNotes(),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      _buildLogo(primaryColor, primaryLighter),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(colors: [primaryColor, primaryLighter, primaryColor]).createShader(bounds),
                        child: const Text(
                          'MusicAI',
                          style: TextStyle(
                            fontFamily: "SpotifyMixUI",
                            fontWeight: FontWeight.w700,
                            fontSize: 42,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isLogin ? 'Welcome back 🎵' : 'Exploring musics with AI ✨',
                          key: ValueKey(_isLogin),
                          style: TextStyle(
                            fontFamily: "SpotifyMixUI",
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildFormCard(Theme.of(context).colorScheme.primary,  primaryLighter),
                      const SizedBox(height: 24),
                      _buildToggleSection(primaryColor),
                      const SizedBox(height: 32),
                      _buildSocialLogin(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color primaryColor, Color primaryLighter) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryLighter],
        ),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5)],
      ),
      child: const HugeIcon(icon: HugeIconsStrokeRounded.audioWave02, color: Colors.white),
    );
  }

  Widget _buildFormCard(Color primaryColor, Color primaryLighter) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_isLogin
                      ? Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Username',
                              icon: Icons.person_rounded,
                              primaryColor: primaryColor,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  primaryColor: primaryColor,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a valid email address';
                    }
                    if (!value.contains('@')) {
                      return 'Email must contain "@" symbol';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  primaryColor: primaryColor,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),

                if (_isLogin) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(fontFamily: "SpotifyMixUI", color: primaryColor, fontSize: 14),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                _buildSubmitButton(primaryColor, primaryLighter),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontFamily: "SpotifyMixUI", color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: "SpotifyMixUI", color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        errorStyle: const TextStyle(fontFamily: "SpotifyMixUI", color: Color(0xFFFF6B6B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildSubmitButton(Color primaryColor, Color primaryLighter) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [primaryColor, primaryLighter]),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLogin ? 'Login' : 'Register',
                style: const TextStyle(
                  fontFamily: "SpotifyMixUI",
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleSection(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Need an account?' : 'Already have an account?',
          style: TextStyle(fontFamily: "SpotifyMixUI", color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          child: Text(
            _isLogin ? 'Register Now' : 'Login Here',
            style: TextStyle(
              fontFamily: "SpotifyMixUI",
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.3)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(fontFamily: "SpotifyMixUI", color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Google', onPressed: () {}),
            const SizedBox(width: 16),
            _SocialButton(icon: Icons.facebook_rounded, label: 'Facebook', onPressed: () {}),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildFloatingNotes() {
    return List.generate(5, (index) {
      return Positioned(
        left: (index * 80.0) + 20,
        top: 100 + (index * 120.0),
        child: AnimatedBuilder(
          animation: _backgroundAnimController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_backgroundAnimController.value * 2 * math.pi + index * 0.5) * 15,
                math.cos(_backgroundAnimController.value * 2 * math.pi + index * 0.3) * 20,
              ),
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  index.isEven ? Icons.music_note_rounded : Icons.audiotrack_rounded,
                  size: 30 + (index * 5.0),
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedGradientBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0D0D0D),
                  const Color(0xFF1A1A2E),
                  (math.sin(controller.value * 2 * math.pi) + 1) / 2,
                )!,
                Color.lerp(
                  const Color(0xFF121212),
                  const Color(0xFF16213E),
                  (math.cos(controller.value * 2 * math.pi) + 1) / 2,
                )!,
                const Color(0xFF0F0F0F),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: "SpotifyMixUI",
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
