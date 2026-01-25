import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// 지도 앱 선택 위젯
/// 사용 가능한 지도 앱(카카오맵, 네이버 지도, 구글 지도, 애플 지도)을 선택할 수 있는 다이얼로그를 제공합니다.
class MapAppSelector {
  /// 지도 앱 선택 다이얼로그를 표시하고 선택한 앱을 엽니다.
  ///
  /// [context] - BuildContext
  /// [query] - 검색어 (선택사항). 입력된 검색어가 있으면 지도 앱에서 해당 검색어로 검색합니다.
  /// [onLocationSelected] - 위치 선택 콜백 (선택사항). 지도 앱에서 위치를 선택한 후 호출됩니다.
  ///
  /// Returns: 선택한 지도 앱의 이름을 반환합니다. 취소하면 null을 반환합니다.
  ///
  /// Note: 현재는 지도 앱을 열기만 하며, 자동 리다이렉트는 지원하지 않습니다.
  /// 사용자는 지도 앱에서 위치를 찾은 후, 주소를 수동으로 앱에 입력해야 합니다.
  static Future<String?> showMapAppSelector(
    BuildContext context, {
    String? query,
    Function(String? address)? onLocationSelected,
  }) async {
    final mapApps = <Map<String, dynamic>>[];

    // 카카오맵
    mapApps.add({
      'name': '카카오맵',
      'icon': Icons.map,
      'color': Colors.yellow.shade700,
      'url': query != null && query.isNotEmpty
          ? 'kakaomap://search?q=${Uri.encodeComponent(query)}'
          : 'kakaomap://',
      'fallbackUrl': query != null && query.isNotEmpty
          ? 'https://map.kakao.com/link/search/${Uri.encodeComponent(query)}'
          : 'https://map.kakao.com',
    });

    // 네이버 지도
    mapApps.add({
      'name': '네이버 지도',
      'icon': Icons.map_outlined,
      'color': Colors.green,
      'url': query != null && query.isNotEmpty
          ? 'nmap://search?query=${Uri.encodeComponent(query)}'
          : 'nmap://',
      'fallbackUrl': query != null && query.isNotEmpty
          ? 'https://map.naver.com/v5/search/${Uri.encodeComponent(query)}'
          : 'https://map.naver.com',
    });

    // 구글 지도
    if (Platform.isIOS) {
      mapApps.add({
        'name': '구글 지도',
        'icon': Icons.map,
        'color': Colors.blue,
        'url': query != null && query.isNotEmpty
            ? 'comgooglemaps://?q=${Uri.encodeComponent(query)}'
            : 'comgooglemaps://',
        'fallbackUrl': query != null && query.isNotEmpty
            ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'
            : 'https://www.google.com/maps',
      });
    } else {
      mapApps.add({
        'name': '구글 지도',
        'icon': Icons.map,
        'color': Colors.blue,
        'url': query != null && query.isNotEmpty
            ? 'geo:0,0?q=${Uri.encodeComponent(query)}'
            : 'https://www.google.com/maps',
        'fallbackUrl': query != null && query.isNotEmpty
            ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'
            : 'https://www.google.com/maps',
      });
    }

    // 애플 지도 (iOS만)
    if (Platform.isIOS) {
      mapApps.add({
        'name': '애플 지도',
        'icon': Icons.map_outlined,
        'color': Colors.grey.shade700,
        'url': query != null && query.isNotEmpty
            ? 'maps://?q=${Uri.encodeComponent(query)}'
            : 'maps://',
        'fallbackUrl': query != null && query.isNotEmpty
            ? 'https://maps.apple.com/?q=${Uri.encodeComponent(query)}'
            : 'https://maps.apple.com',
      });
    }

    final selectedApp = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지도 앱 선택'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '지도 앱에서 위치를 찾은 후,\n주소를 복사해서 앱에 붙여넣어주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...mapApps.map((app) {
                return ListTile(
                  leading: Icon(app['icon'], color: app['color']),
                  title: Text(app['name']),
                  onTap: () => Navigator.pop(context, app),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (selectedApp != null) {
      final url = Uri.parse(selectedApp['url']);
      final appName = selectedApp['name'] as String;
      final fallbackUrl = selectedApp['fallbackUrl'] as String?;

      try {
        // 먼저 앱으로 열기 시도
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return appName;
        } else {
          // 앱이 없으면 웹 버전으로 fallback
          if (fallbackUrl != null) {
            final webUrl = Uri.parse(fallbackUrl);
            if (await canLaunchUrl(webUrl)) {
              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
              return appName;
            }
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$appName 앱을 열 수 없습니다. 앱이 설치되어 있는지 확인해주세요.'),
              ),
            );
          }
          return null;
        }
      } catch (e) {
        // 에러 발생 시 웹 버전으로 fallback 시도
        if (fallbackUrl != null) {
          try {
            final webUrl = Uri.parse(fallbackUrl);
            if (await canLaunchUrl(webUrl)) {
              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
              return appName;
            }
          } catch (_) {
            // 웹 버전도 실패하면 에러 표시
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('지도 앱을 열 수 없습니다: $e')));
        }
        return null;
      }
    }

    return null;
  }
}
