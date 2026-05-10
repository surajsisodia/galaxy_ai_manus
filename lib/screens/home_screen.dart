import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:galaxy_ai_assignment/utils/app_constants.dart';
import 'package:go_router/go_router.dart';

import '../providers/chat_provider.dart';
import '../routes/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<String> _filters = const [
    AppStrings.homeTabAll,
    AppStrings.homeTabAgent,
    AppStrings.homeTabScheduled,
    AppStrings.homeTabFavorites,
  ];
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = AppStrings.homeTabAll;
  }

  void _openChat(String chatId) {
    context.push(RouteNames.chatPath(chatId));
  }

  void _openProfile() {
    context.push(RouteNames.profile);
  }

  void _openNewDraftChat() {
    final draftChatId = '${DateTime.now().microsecondsSinceEpoch}';
    _openChat(draftChatId);
  }

  Future<void> _refreshChats() async {
    ref.invalidate(chatHeadersProvider);
    await ref.read(chatHeadersProvider.future);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final headersValue = ref.watch(chatHeadersProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 10),
        child: FloatingActionButton(
          onPressed: _openNewDraftChat,
          elevation: 0,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add_comment_outlined,
            color: Color(0xFF111216),
            size: 34,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: SvgPicture.asset(
                        AppConstants.profileIconAssets,
                        color: Color(0xFFE5E6EA),
                        height: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.homeBrandName,
                    style: const TextStyle(
                      color: Color(0xFFEFEFF2),
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.auto_stories_outlined,
                    color: Color(0xFFE5E6EA),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFE5E6EA),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = _filters[index];
                    final isSelected = item == _selectedFilter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = item;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF2F2F2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFF24262E),
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF15161B)
                                  : const Color(0xFF8C8F98),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 5),
                  itemCount: _filters.length,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshChats,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF1E2026),
                  child: headersValue.when(
                    data: (headers) {
                      if (headers.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No chats yet. Start a new conversation.',
                                style: TextStyle(
                                  color: Color(0xFF7A7D86),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: headers.length,
                        itemBuilder: (context, index) {
                          final header = headers[index];
                          return InkWell(
                            onTap: () => _openChat(header.id),
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E2026),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: const Icon(
                                      Icons.forum_rounded,
                                      color: Color(0xFFECECF0),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  header.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFFEDEEF2),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(header.updatedAt),
                                                style: const TextStyle(
                                                  color: Color(0xFF6E717A),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            header.preview,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF7A7D86),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          if (index == headers.length - 1) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 94),
                            child: Divider(
                              color: const Color(
                                0xFF2B2D34,
                              ).withValues(alpha: 0.92),
                              height: 6,
                              thickness: 1,
                            ),
                          );
                        },
                      );
                    },
                    error: (error, _) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Failed to load chats: $error',
                            style: const TextStyle(
                              color: Color(0xFFB8BAC1),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
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
