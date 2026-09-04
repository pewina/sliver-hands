import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../home/home_shell.dart';

class AadhaarVerificationScreen extends StatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  State<AadhaarVerificationScreen> createState() =>
      _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState
    extends State<AadhaarVerificationScreen> {
  final TextEditingController _aadhaarController =
      TextEditingController();

  final TextEditingController _otpController =
      TextEditingController();

  bool _busy = false;
  bool _otpSent = false;
  bool _verified = false;

  String? _error;

  // DEMO ONLY
  static const String _demoOtp = '123456';

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _aadhaar {
    return _aadhaarController.text.replaceAll(' ', '').trim();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    setState(() {
      _error = null;
    });

    if (!RegExp(r'^\d{12}$').hasMatch(_aadhaar)) {
      setState(() {
        _error = 'Please enter a valid 12-digit Aadhaar number.';
      });
      return;
    }

    setState(() {
      _busy = true;
    });

    // Simulate OTP sending for the hackathon demo.
    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    setState(() {
      _otpSent = true;
      _busy = false;
      _error = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo OTP sent. Use 123456 to verify.',
        ),
      ),
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    setState(() {
      _error = null;
    });

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _error = 'Please enter the 6-digit OTP.';
      });
      return;
    }

    if (otp != _demoOtp) {
      setState(() {
        _error = 'Invalid OTP. For this demo, use 123456.';
      });
      return;
    }

    setState(() {
      _busy = true;
    });

    // Simulate verification.
    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    setState(() {
      _verified = true;
      _busy = false;
      _error = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Identity verification completed successfully.',
        ),
      ),
    );

    // Show success briefly, then go home.
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    _goToHome();
  }

  // ============================================================
  // CHANGE AADHAAR
  // ============================================================

  void _changeAadhaar() {
    setState(() {
      _otpSent = false;
      _verified = false;
      _error = null;
      _otpController.clear();
    });
  }

  // ============================================================
  // GO TO HOME
  // ============================================================

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeShell(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        title: const Text('Identity Verification'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ======================================================
              // HEADER
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),

                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,

                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.verified_user_rounded,
                          size: 42,
                          color: AppColors.teal,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        _verified
                            ? 'Identity verified'
                            : 'Verify your identity',

                        textAlign: TextAlign.center,

                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _verified
                            ? 'Your identity has been verified successfully.'
                            : 'A verified profile helps businesses trust '
                                'SilverHands sellers.',

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ======================================================
              // MAIN CARD
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // AADHAAR STEP
                      // ==================================================

                      if (!_otpSent && !_verified) ...[
                        const Text(
                          'Aadhaar number',

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Enter your 12-digit Aadhaar number '
                          'for this demo verification.',

                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _aadhaarController,

                          keyboardType:
                              TextInputType.number,

                          maxLength: 12,

                          enabled: !_busy,

                          obscureText: true,

                          decoration:
                              const InputDecoration(
                            hintText: 'Enter 12 digits',

                            prefixIcon: Icon(
                              Icons.credit_card_rounded,
                            ),

                            counterText: '',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _privacyBox(),

                        if (_error != null)
                          _errorWidget(),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,

                          child: FilledButton.icon(
                            onPressed:
                                _busy ? null : _sendOtp,

                            icon: _busy
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.sms_rounded,
                                  ),

                            label: Text(
                              _busy
                                  ? 'Sending OTP...'
                                  : 'Send OTP',
                            ),

                            style:
                                FilledButton.styleFrom(
                              minimumSize:
                                  const Size.fromHeight(56),
                            ),
                          ),
                        ),
                      ],

                      // ==================================================
                      // OTP STEP
                      // ==================================================

                      if (_otpSent && !_verified) ...[
                        const Text(
                          'Enter OTP',

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Enter the 6-digit OTP sent to your '
                          'registered mobile number.',

                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _otpController,

                          keyboardType:
                              TextInputType.number,

                          maxLength: 6,

                          enabled: !_busy,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                          ),

                          decoration:
                              const InputDecoration(
                            hintText: '••••••',

                            prefixIcon: Icon(
                              Icons.sms_outlined,
                            ),

                            counterText: '',
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,

                          padding:
                              const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color:
                                AppColors.teal.withValues(
                              alpha: 0.08,
                            ),

                            borderRadius:
                                BorderRadius.circular(14),
                          ),

                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Icon(
                                Icons.science_outlined,
                                size: 21,
                                color: AppColors.teal,
                              ),

                              SizedBox(width: 9),

                              Expanded(
                                child: Text(
                                  'Hackathon demo: OTP delivery '
                                  'is simulated. Use 123456.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_error != null)
                          _errorWidget(),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,

                          child: FilledButton.icon(
                            onPressed:
                                _busy ? null : _verifyOtp,

                            icon: _busy
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified_user_rounded,
                                  ),

                            label: Text(
                              _busy
                                  ? 'Verifying OTP...'
                                  : 'Verify OTP',
                            ),

                            style:
                                FilledButton.styleFrom(
                              minimumSize:
                                  const Size.fromHeight(56),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,

                          child: TextButton(
                            onPressed:
                                _busy
                                    ? null
                                    : _changeAadhaar,

                            child: const Text(
                              'Change Aadhaar number',
                            ),
                          ),
                        ),
                      ],

                      // ==================================================
                      // VERIFIED
                      // ==================================================

                      if (_verified) ...[
                        Container(
                          width: double.infinity,

                          padding:
                              const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color:
                                AppColors.green.withValues(
                              alpha: 0.12,
                            ),

                            borderRadius:
                                BorderRadius.circular(14),
                          ),

                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: AppColors.green,
                                size: 30,
                              ),

                              SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  'Identity verified successfully!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,

                          child: FilledButton.icon(
                            onPressed: _goToHome,

                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                            ),

                            label: const Text(
                              'Continue to SilverHands',
                            ),

                            style:
                                FilledButton.styleFrom(
                              minimumSize:
                                  const Size.fromHeight(56),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ======================================================
              // SECURITY MESSAGE
              // ======================================================

              Card(
                color: AppColors.mist,

                child: const Padding(
                  padding: EdgeInsets.all(18),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.teal,
                        size: 25,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Privacy first: SilverHands never '
                          'publicly displays or shares the '
                          'complete Aadhaar number.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PRIVACY BOX
  // ================================================================

  Widget _privacyBox() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.teal.withValues(
          alpha: 0.08,
        ),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 21,
            color: AppColors.teal,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'SilverHands does not store your complete '
              'Aadhaar number. This is a demo verification flow.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR WIDGET
  // ================================================================

  Widget _errorWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),

      child: Text(
        _error!,

        style: const TextStyle(
          color: AppColors.rose,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}