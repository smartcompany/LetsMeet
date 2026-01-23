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
    // 화면이 처음 로드될 때 모임 목록 가져오기
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
        final meetings = meetingProvider.filteredMeetings;
        
        final locations = meetingProvider.meetings
            .map((m) => m.location)
            .toSet()
            .toList()
          ..sort();
        
        final interests = meetingProvider.meetings
            .expand((m) => m.interests)
            .toSet()
            .toList()
          ..sort();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 문구 (토스 스타일)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF5F7FA),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘 이런 대화는 어때요?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        height: 1.2,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '소규모 · 주제 중심 · 질문 기반',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
              
              // 필터 영역
              FilterBar(
                selectedLocation: meetingProvider.selectedLocation,
                selectedInterest: meetingProvider.selectedInterest,
                selectedFormat: meetingProvider.selectedFormat,
                availableLocations: locations,
                availableInterests: interests,
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MeetingDetailScreen(
                                meetingId: meeting.id,
                              ),
                            ),
                          );
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
