import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _ProfileTopBar(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(RouteNames.home);
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
                child: Column(
                  children: [
                    _ProfileAvatar(
                      imageAsset: AppConstants.splashHandLogoAsset,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      AppStrings.profileName,
                      style: TextStyle(
                        color: Color(0xFFF0F1F4),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.profileEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.46),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _PlanCard(),
                    const SizedBox(height: 16),
                    const _SingleMenuCard(
                      icon: Icons.account_circle_outlined,
                      label: AppStrings.profileAccount,
                    ),
                    const SizedBox(height: 16),
                    const _MenuGroupCard(
                      items: [
                        _MenuItemData(
                          icon: Icons.calendar_month_outlined,
                          label: AppStrings.profileScheduledTasks,
                        ),
                        _MenuItemData(
                          icon: Icons.menu_book_outlined,
                          label: AppStrings.profileKnowledge,
                        ),
                        _MenuItemData(
                          icon: Icons.mark_email_unread_outlined,
                          label: AppStrings.profileMailManus,
                        ),
                        _MenuItemData(
                          icon: Icons.storage_outlined,
                          label: AppStrings.profileDataControls,
                        ),
                        _MenuItemData(
                          icon: Icons.web_outlined,
                          label: AppStrings.profileCloudBrowser,
                        ),
                        _MenuItemData(
                          icon: Icons.extension_outlined,
                          label: AppStrings.profileSkills,
                        ),
                        _MenuItemData(
                          icon: Icons.cable_outlined,
                          label: AppStrings.profileConnectors,
                        ),
                        _MenuItemData(
                          icon: Icons.cable_outlined,
                          label: AppStrings.profileIntegrations,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _MenuGroupCard(
                      items: [
                        _MenuItemData(
                          icon: Icons.language,
                          label: AppStrings.profileLanguage,
                        ),
                        _MenuItemData(
                          icon: Icons.palette_outlined,
                          label: AppStrings.profileAppearance,
                        ),
                        _MenuItemData(
                          icon: Icons.cleaning_services_outlined,
                          label: AppStrings.profileClearCache,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _MenuGroupCard(
                      items: [
                        _MenuItemData(
                          icon: Icons.menu_book_outlined,
                          label: AppStrings.profilePlaybook,
                        ),
                        _MenuItemData(
                          icon: Icons.star_outline_rounded,
                          label: AppStrings.profileRateThisApp,
                        ),
                        _MenuItemData(
                          icon: Icons.help_outline_rounded,
                          label: AppStrings.profileGetHelp,
                        ),
                        _MenuItemData(
                          icon: Icons.info_outline_rounded,
                          label: AppStrings.profileVersion,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _MenuGroupCard(
                      items: [
                        _MenuItemData(
                          icon: Icons.logout_rounded,
                          label: AppStrings.profileLogOut,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFE8E9EC),
                  size: 24,
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              AppStrings.homeBrandName,
              style: TextStyle(
                color: Color(0xFFEFEFF2),
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: 
                Icon(
                  Icons.notifications_none_rounded,
                  size: 30,
                  color: Colors.white.withValues(alpha: 0.92),
                )
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ClipOval(
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: const Color(0xFF2B2D33),
              child: const Icon(
                Icons.person_rounded,
                size: 62,
                color: Color(0xFFCACDD4),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF23252B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                AppStrings.profilePlan,
                style: TextStyle(
                  color: Color(0xFFF0F1F4),
                  fontSize: 42 / 2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  AppStrings.profileUpgrade,
                  style: TextStyle(
                    color: Color(0xFF16181D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFFE8E9ED),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                AppStrings.profileCredits,
                style: TextStyle(
                  color: Color(0xFFE9EAF0),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                AppStrings.profileCreditsValue,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.42),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SingleMenuCard extends StatelessWidget {
  const _SingleMenuCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23252B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _MenuRow(icon: icon, label: label, hasDivider: false),
    );
  }
}

class _MenuGroupCard extends StatelessWidget {
  const _MenuGroupCard({required this.items});

  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23252B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _MenuRow(
              icon: items[i].icon,
              label: items[i].label,
              hasDivider: i != items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.hasDivider,
  });

  final IconData icon;
  final String label;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFE7E8EC), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE6E7EC),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.44),
                size: 28,
              ),
            ],
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 55),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.06),
              height: 1,
              thickness: 1,
            ),
          ),
      ],
    );
  }
}
