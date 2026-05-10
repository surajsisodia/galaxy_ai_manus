import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_strings.dart';

class ChatComposerCard extends ConsumerStatefulWidget {
  const ChatComposerCard({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatComposerCard> createState() => _ChatComposerCardState();
}

class _ChatComposerCardState extends ConsumerState<ChatComposerCard> {
  late final TextEditingController _controller;

  Future<void> _openActionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ComposerActionSheet(),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.chatId));

    if (_controller.text != chatState.currentInput) {
      _controller.value = TextEditingValue(
        text: chatState.currentInput,
        selection: TextSelection.collapsed(
          offset: chatState.currentInput.length,
        ),
      );
    }

    final hasInput = chatState.currentInput.trim().isNotEmpty;
    const composerBorderRadius = BorderRadius.all(Radius.circular(30));

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            borderRadius: composerBorderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.homeComposerBackground.withValues(alpha: 0.38),
                AppColors.homeComposerBackground.withValues(alpha: 0.52),
                AppColors.homeComposerBackground.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                onChanged: ref
                    .read(chatProvider(widget.chatId).notifier)
                    .updateCurrentInput,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: AppStrings.homeComposerHint,
                  hintStyle: TextStyle(
                    color: AppColors.homeComposerHint,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  ref
                      .read(chatProvider(widget.chatId).notifier)
                      .sendCurrentInput(AppConstants.geminiDefaultModel);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: _openActionsSheet,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.homeIcon,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Icon(
                    Icons.hub_outlined,
                    color: AppColors.homeIcon,
                    size: 24,
                  ),
                  const Spacer(),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.homeIcon.withValues(alpha: 0.28),
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.homeIcon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.homeIcon,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: chatState.isStreaming
                        ? ref
                              .read(chatProvider(widget.chatId).notifier)
                              .cancelStreaming
                        : (hasInput
                              ? () => ref
                                    .read(chatProvider(widget.chatId).notifier)
                                    .sendCurrentInput(
                                      AppConstants.geminiDefaultModel,
                                    )
                              : null),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chatState.isStreaming || hasInput
                            ? AppColors.homeSendBackground
                            : AppColors.homeSendBackground.withValues(
                                alpha: 0.4,
                              ),
                      ),
                      child: Icon(
                        chatState.isStreaming
                            ? Icons.stop_rounded
                            : Icons.arrow_upward_rounded,
                        color: AppColors.homeIcon,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerActionSheet extends StatelessWidget {
  const _ComposerActionSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2024),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: const [
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.image_outlined,
                            label: 'Picture',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.attach_file_rounded,
                            label: 'File',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    _SheetActionRow(
                      icon: Icons.desktop_windows_outlined,
                      label: 'Connect My Computer',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.extension_outlined,
                      label: 'Add Skills',
                    ),
                    SizedBox(height: 12),
                    Divider(color: Color(0xFF31343C), thickness: 1),
                    SizedBox(height: 12),
                    _SheetActionRow(
                      icon: Icons.web_asset_outlined,
                      label: 'Build website',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.phone_android_outlined,
                      label: 'Develop apps',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Create slides',
                      badge: 'Image 2',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Create image',
                      badge: 'Image 2',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.auto_fix_high_outlined,
                      label: 'Edit image',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.travel_explore_outlined,
                      label: 'Wide Research',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Scheduled tasks',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.table_chart_outlined,
                      label: 'Create spreadsheet',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.ondemand_video_outlined,
                      label: 'Create video',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.graphic_eq_rounded,
                      label: 'Generate audio',
                    ),
                    SizedBox(height: 6),
                    _SheetActionRow(
                      icon: Icons.copy_all_outlined,
                      label: 'Playbook',
                      trailingIcon: Icons.open_in_new_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFF0F2F7), size: 29),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8EAF0),
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.icon,
    required this.label,
    this.badge,
    this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFEDEFF6), size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE3E5EB),
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF353840),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFC8CBD3),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badge!,
                      style: const TextStyle(
                        color: Color(0xFFC8CBD3),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (trailingIcon != null)
              Icon(trailingIcon, color: const Color(0xFF7B7E87), size: 18),
          ],
        ),
      ),
    );
  }
}
