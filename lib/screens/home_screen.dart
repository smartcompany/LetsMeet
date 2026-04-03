import 'package:flutter/material.dart';
import '../providers/meeting_provider.dart';
import '../widgets/meeting_card.dart';
import '../widgets/filter_bar.dart';
import '../theme/app_theme.dart';
import 'meeting_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MeetingProvider.shared.loadFavorites();
      if (MeetingProvider.shared.meetings.isEmpty &&
          !MeetingProvider.shared.isLoading) {
        MeetingProvider.shared.loadMeetings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MeetingProvider.shared,
      builder: (context, _) {
        final meetingProvider = MeetingProvider.shared;
        // 로딩 중이면 로딩 표시
        if (meetingProvider.isLoading && meetingProvider.meetings.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final meetings = meetingProvider.filteredMeetings;

        return RefreshIndicator(
          onRefresh: () => meetingProvider.loadMeetings(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 필터 영역
                      FilterBar(
                        selectedAgeMin: meetingProvider.selectedAgeMin,
                        selectedAgeMax: meetingProvider.selectedAgeMax,
                        selectedLocation: meetingProvider.selectedLocation,
                        selectedCategory: meetingProvider.selectedCategory,
                        selectedFormat: meetingProvider.selectedFormat,
                        showMyMeetingsOnly: meetingProvider.showMyMeetingsOnly,
                        onAgeRangeChanged: (min, max) {
                          meetingProvider.setAgeRangeFilter(min, max);
                        },
                        onLocationChanged: (location) {
                          meetingProvider.setLocationFilter(location);
                        },
                        onCategoryChanged: (category) {
                          meetingProvider.setCategoryFilter(category);
                        },
                        onFormatChanged: (format) {
                          meetingProvider.setFormatFilter(format);
                        },
                        onMyMeetingsChanged: (value) {
                          meetingProvider.setShowMyMeetingsOnly(value);
                        },
                        onClear: () {
                          meetingProvider.clearFilters();
                        },
                      ),

                      // 모임 카드 리스트
                      if (meetings.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.textTertiaryColor
                                            .withOpacity(0.1),
                                        AppTheme.textTertiaryColor
                                            .withOpacity(0.05),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 56,
                                    color: AppTheme.textTertiaryColor
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '조건에 맞는 모임이 없습니다',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '필터를 조정해보세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textTertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          child: Column(
                            children: meetings.map((meeting) {
                              return MeetingCard(
                                meeting: meeting,
                                isFavorite:
                                    meetingProvider.isFavorite(meeting.id),
                                onToggleFavorite: () =>
                                    meetingProvider.toggleFavorite(meeting.id),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MeetingDetailScreen(
                                        meetingId: meeting.id,
                                      ),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    meetingProvider.loadMeetings();
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
