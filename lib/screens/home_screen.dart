import 'dart:async';

import 'package:flutter/material.dart';
import '../providers/meeting_provider.dart';
import '../widgets/meeting_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_meeting_sort_bar.dart';
import '../theme/app_theme.dart';
import '../services/app_analytics_service.dart';
import 'meeting_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  /// 첫 프레임 렌더 후 1회 호출 (iOS viewDidAppear에 해당)
  final VoidCallback? onAppeared;

  const HomeScreen({super.key, this.onAppeared});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _didNotifyAppeared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MeetingProvider.shared.loadFavorites();
      if (!MeetingProvider.shared.hasLoadedMeetingsOnce) {
        MeetingProvider.shared.loadMeetings();
      }
      // 홈 UI가 실제로 그려진 뒤 스플래시 제거
      if (!_didNotifyAppeared) {
        _didNotifyAppeared = true;
        widget.onAppeared?.call();
        unawaited(AppAnalyticsService.log('home_viewed'));
      }
    });
  }

  Future<void> _openMeetingDetail(
    BuildContext context,
    MeetingProvider meetingProvider,
    String meetingId,
  ) async {
    unawaited(
      AppAnalyticsService.log(
        'meeting_detail_opened',
        properties: {'source': 'home'},
      ),
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailScreen(meetingId: meetingId),
      ),
    );
    if (result == true && context.mounted) {
      meetingProvider.loadMeetings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MeetingProvider.shared,
      builder: (context, _) {
        final meetingProvider = MeetingProvider.shared;
        if (meetingProvider.isLoading && meetingProvider.meetings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => meetingProvider.loadMeetings(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterBar(meetingProvider),
                        HomeMeetingSortBar(
                          selected: meetingProvider.homeSort,
                          onChanged: meetingProvider.setHomeSort,
                        ),
                        const _HomeLoadingSkeleton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        final meetings = meetingProvider.homeMeetings;

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
                      _buildFilterBar(meetingProvider),
                      HomeMeetingSortBar(
                        selected: meetingProvider.homeSort,
                        onChanged: meetingProvider.setHomeSort,
                      ),
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
                                  meetingProvider.homeSort ==
                                          HomeMeetingSort.startingToday
                                      ? '오늘 시작하는 모임이 없습니다'
                                      : '조건에 맞는 모임이 없습니다',
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
                            children: [
                              MeetingCard(
                                meeting: meetings.first,
                                variant: MeetingCardVariant.hero,
                                isFavorite: meetingProvider
                                    .isFavorite(meetings.first.id),
                                onToggleFavorite: () => meetingProvider
                                    .toggleFavorite(meetings.first.id),
                                onTap: () => _openMeetingDetail(
                                  context,
                                  meetingProvider,
                                  meetings.first.id,
                                ),
                              ),
                              ...meetings.skip(1).map((meeting) {
                                return MeetingCard(
                                  meeting: meeting,
                                  variant: MeetingCardVariant.compact,
                                  isFavorite:
                                      meetingProvider.isFavorite(meeting.id),
                                  onToggleFavorite: () => meetingProvider
                                      .toggleFavorite(meeting.id),
                                  onTap: () => _openMeetingDetail(
                                    context,
                                    meetingProvider,
                                    meeting.id,
                                  ),
                                );
                              }),
                            ],
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

  Widget _buildFilterBar(MeetingProvider meetingProvider) {
    return FilterBar(
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
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          _placeholder(height: 220),
          const SizedBox(height: 12),
          _placeholder(height: 120),
          const SizedBox(height: 12),
          _placeholder(height: 120),
        ],
      ),
    );
  }

  Widget _placeholder({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
