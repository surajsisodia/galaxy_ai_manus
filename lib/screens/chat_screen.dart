import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../providers/chat_provider.dart';
import '../routes/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_strings.dart';
import '../widgets/chat/chat_composer_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final GlobalKey _modelSelectorKey = GlobalKey();
  final GlobalKey<_ChatMessagesListState> _messagesListKey =
      GlobalKey<_ChatMessagesListState>();
  final Map<String, String> _modelOptions = {
    AppStrings.homeModelName: AppStrings.homeModelDes,
    AppStrings.homeModelNamePro: AppStrings.homeModelNameProDes,
    AppStrings.homeModelNameVision: AppStrings.homeModelNameVisionDes,
  };
  late String _selectedModelLabel;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _selectedModelLabel = AppStrings.homeModelName;
  }

  Future<void> _showModelDropdown() async {
    final selectorContext = _modelSelectorKey.currentContext;
    if (selectorContext == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = selectorContext.findRenderObject() as RenderBox;
    final targetOffset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final targetSize = box.size;

    final selectedLabel = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'Close model menu',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (dialogContext, _, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: targetOffset.dx,
              top: targetOffset.dy + targetSize.height + 8,
              child: _ModelDropdownMenu(
                selectedValue: _selectedModelLabel,
                options: _modelOptions,
                onSelected: (value) => Navigator.of(dialogContext).pop(value),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
        );
      },
    );
    if (selectedLabel != null && selectedLabel != _selectedModelLabel) {
      setState(() {
        _selectedModelLabel = selectedLabel;
      });
    }
  }

  void _onMessagesAtBottomChanged(bool isAtBottom) {
    final shouldShow = !isAtBottom;
    if (_showScrollToBottom == shouldShow) return;
    setState(() {
      _showScrollToBottom = shouldShow;
    });
  }

  void _scrollMessagesToBottom() {
    _messagesListKey.currentState?.scrollToBottom(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.chatId));
    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            children: [
              if (messages.isNotEmpty)
                Positioned.fill(
                  top: 56,
                  child: _ChatMessagesList(
                    key: _messagesListKey,
                    messages: messages,
                    isStreaming: chatState.isStreaming,
                    onAtBottomChanged: _onMessagesAtBottomChanged,
                  ),
                ),
              if (messages.isEmpty)
                Align(
                  alignment: const Alignment(0, -0.1),
                  child: Text(
                    AppStrings.homePrompt,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                top: 14,
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(RouteNames.home);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.homeTopText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      key: _modelSelectorKey,
                      borderRadius: BorderRadius.circular(8),
                      onTap: _showModelDropdown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedModelLabel,
                            style: const TextStyle(
                              color: AppColors.homeTopText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.homeTopText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const _CreditsPill(),
                  ],
                ),
              ),
              if (chatState.streamError != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 188,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatState.streamError!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(chatProvider(widget.chatId).notifier)
                                .retryLastRequest(
                                  AppConstants.geminiDefaultModel,
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (messages.isNotEmpty && _showScrollToBottom)
                Positioned(
                  right: 22,
                  bottom: 146,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _scrollMessagesToBottom,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xC62D2F36),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ChatComposerCard(chatId: widget.chatId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelDropdownMenu extends StatelessWidget {
  const _ModelDropdownMenu({
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  final String selectedValue;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF23252B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.homeHeaderPillBorder, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            final title = entry.key;
            final description = entry.value;

            final isSelected = title == selectedValue;
            return InkWell(
              onTap: () => onSelected(title),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.homeTopText,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.homeTopText.withValues(alpha: 0.72),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CreditsPill extends StatelessWidget {
  const _CreditsPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.homeHeaderPillBorder, width: 2),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.homeCredits,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 22,
            child: VerticalDivider(
              color: AppColors.homeHeaderPillBorder,
              thickness: 1.2,
            ),
          ),
          Text(
            AppStrings.homeUpgrade,
            style: const TextStyle(
              color: AppColors.homeUpgradeBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessagesList extends StatefulWidget {
  const _ChatMessagesList({
    super.key,
    required this.messages,
    required this.isStreaming,
    required this.onAtBottomChanged,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final ValueChanged<bool> onAtBottomChanged;

  @override
  State<_ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<_ChatMessagesList> {
  late final ScrollController _scrollController;
  bool _lastIsAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollPosition);
    if (widget.messages.isNotEmpty || widget.isStreaming) {
      _scrollToBottomAfterFrame();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyBottomState();
    });
  }

  @override
  void didUpdateWidget(covariant _ChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isStreaming) {
      final hasStreamJustStarted = !oldWidget.isStreaming && widget.isStreaming;
      final hasMessageChanged =
          _messageSignature(oldWidget.messages) !=
          _messageSignature(widget.messages);

      if (hasStreamJustStarted || hasMessageChanged) {
        _scrollToBottomAfterFrame();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyBottomState();
    });
  }

  String _messageSignature(List<ChatMessage> source) {
    if (source.isEmpty) return 'empty';
    final last = source.last;
    return '${source.length}|${last.id}|${last.text.length}|${last.isStreaming}';
  }

  void _scrollToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      try {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } on Object {
        // Ignore transient position issues during active layout changes.
      }
      _notifyBottomState();
    });
  }

  void _handleScrollPosition() {
    _notifyBottomState();
  }

  void _notifyBottomState() {
    if (!_scrollController.hasClients) return;
    const bottomTolerance = 28.0;
    final position = _scrollController.position;
    final isAtBottom =
        position.pixels >=
        (position.maxScrollExtent - bottomTolerance).clamp(
          0.0,
          double.infinity,
        );

    if (isAtBottom == _lastIsAtBottom) return;
    _lastIsAtBottom = isAtBottom;
    widget.onAtBottomChanged(isAtBottom);
  }

  void scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
    _notifyBottomState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.5,
      height: 1.35,
    );

    final markdownStyleSheet = MarkdownStyleSheet(
      p: baseTextStyle,
      h1: baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      h2: baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      h3: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h4: baseTextStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      strong: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
      listBullet: baseTextStyle,
      blockquote: baseTextStyle.copyWith(
        color: Colors.white.withValues(alpha: 0.86),
      ),
      code: baseTextStyle.copyWith(
        fontFamily: 'JetBrainsMono',
        fontSize: 13.5,
        color: const Color(0xFFE8E8E8),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: const Color(0x29000000),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        notification.disallowIndicator();
        return true;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 130),
        itemCount: widget.messages.length,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          final isUser = message.role == ChatRole.user;

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF26436A)
                    : AppColors.homeComposerBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.text.isEmpty && message.isStreaming
                  ? const Text('...', style: baseTextStyle)
                  : MarkdownBody(
                      data: message.text,
                      shrinkWrap: true,
                      styleSheet: markdownStyleSheet,
                    ),
            ),
          );
        },
      ),
    );
  }
}
