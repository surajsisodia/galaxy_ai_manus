import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_strings.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  Future<void> _performDemoSignIn(WidgetRef ref, String provider) async {
    await ref
        .read(authProvider.notifier)
        .signIn(email: 'suraj@gmail.com', password: '1234');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 58),
                                SvgPicture.asset(
                                  AppConstants.splashHandLogoAsset,
                                  width: 86,
                                  fit: BoxFit.contain,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  AppStrings.authWelcomeTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 56),
                                _AuthActionButton(
                                  icon: const _FacebookLogo(),
                                  label: AppStrings.authContinueFacebook,
                                  onTap: authState.isLoading
                                      ? null
                                      : () =>
                                            _performDemoSignIn(ref, 'facebook'),
                                ),
                                const SizedBox(height: 14),
                                _AuthActionButton(
                                  icon: const _GoogleLogo(),
                                  label: AppStrings.authContinueGoogle,
                                  onTap: authState.isLoading
                                      ? null
                                      : () => _performDemoSignIn(ref, 'google'),
                                ),
                                const SizedBox(height: 14),
                                _AuthActionButton(
                                  icon: const _MicrosoftLogo(),
                                  label: AppStrings.authContinueMicrosoft,
                                  onTap: authState.isLoading
                                      ? null
                                      : () => _performDemoSignIn(
                                          ref,
                                          'microsoft',
                                        ),
                                ),
                                const SizedBox(height: 14),
                                _AuthActionButton(
                                  icon: const Icon(
                                    Icons.apple,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                  label: AppStrings.authContinueApple,
                                  onTap: authState.isLoading
                                      ? null
                                      : () => _performDemoSignIn(ref, 'apple'),
                                ),
                                const SizedBox(height: 30),
                                const _OrDivider(),
                                const SizedBox(height: 30),
                                _AuthActionButton(
                                  icon: const Icon(
                                    Icons.mail_outline,
                                    color: Colors.white,
                                    size: 33,
                                  ),
                                  label: AppStrings.authContinueEmail,
                                  onTap: authState.isLoading
                                      ? null
                                      : () => _performDemoSignIn(ref, 'email'),
                                ),
                                if (authState.errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    authState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 26, bottom: 8),
                              child: _AuthLegalFooter(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (authState.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authButtonBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 18,
                child: SizedBox(width: 40, child: Center(child: icon)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.authDivider, thickness: 1.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppStrings.authOrLabel,
            style: const TextStyle(
              color: AppColors.authMutedText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.authDivider, thickness: 1.3),
        ),
      ],
    );
  }
}

class _AuthLegalFooter extends StatelessWidget {
  const _AuthLegalFooter();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: const TextStyle(
          color: AppColors.authMutedText,
          fontSize: 12.5,
          height: 1.35,
        ),
        children: [
          const TextSpan(text: AppStrings.authLegalPrefix),
          const TextSpan(
            text: AppStrings.authTermsLabel,
            style: TextStyle(decoration: TextDecoration.underline),
          ),
          const TextSpan(text: AppStrings.authAndHaveRead),
          const TextSpan(
            text: AppStrings.authPrivacyLabel,
            style: TextStyle(decoration: TextDecoration.underline),
          ),
          const TextSpan(text: AppStrings.authCopyrightSuffix),
        ],
      ),
    );
  }
}

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.facebookIconAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.googleIconAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.microsoftIconAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}
