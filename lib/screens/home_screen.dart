import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // 인증 없이도 모임 목록 로드 가능
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meetingProvider = context.read<MeetingProvider>();
      if (meetingProvider.meetings.isEmpty && !meetingProvider.isLoading) {
        meetingProvider.loadMeetings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        // 로딩 중이면 로딩 표시
        if (meetingProvider.isLoading && meetingProvider.meetings.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final meetings = meetingProvider.filteredMeetings;
        
        final interests = meetingProvider.meetings
            .expand((m) => m.interests)
            .toSet()
            .toList()
          ..sort();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 필터 영역
              FilterBar(
                selectedAgeMin: meetingProvider.selectedAgeMin,
                selectedAgeMax: meetingProvider.selectedAgeMax,
                selectedLocation: meetingProvider.selectedLocation,
                selectedInterest: meetingProvider.selectedInterest,
                selectedFormat: meetingProvider.selectedFormat,
                availableInterests: interests,
                onAgeRangeChanged: (min, max) {
                  meetingProvider.setAgeRangeFilter(min, max);
                },
                onLocationChanged: (location) {
                  meetingProvider.setLocationFilter(location);
                },
                onInterestChanged: (interest) {
                  meetingProvider.setInterestFilter(interest);
                },
                onFormatChanged: (format) {
                  meetingProvider.setFormatFilter(format);
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
                                AppTheme.textTertiaryColor.withOpacity(0.1),
                                AppTheme.textTertiaryColor.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off,
                            size: 56,
                            color: AppTheme.textTertiaryColor.withOpacity(0.5),
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
                        isFavorite: meetingProvider.isFavorite(meeting.id),
                        onToggleFavorite: () => meetingProvider.toggleFavorite(meeting.id),
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
        );
        },
    );
  }
}
