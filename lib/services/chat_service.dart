import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;
  final String type; // 'user' | 'system'

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.type = 'user',
  });

  bool get isSystem => type == 'system';

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: (data['userName'] ?? data['userNickname']) ?? '알 수 없음',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      if (type != 'user') 'type': type,
    };
  }
}

class ChatRoom {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final String? meetingImageUrl;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final Map<String, String>? memberProfileUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.meetingId,
    required this.meetingTitle,
    this.meetingImageUrl,
    required this.memberIds,
    required this.memberNames,
    this.memberProfileUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  int get participantCount => memberIds.length;

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      meetingTitle: data['meetingTitle'] ?? '',
      meetingImageUrl: data['meetingImageUrl'] as String?,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(
        data['memberNames'] ?? data['memberNicknames'] ?? {},
      ),
      memberProfileUrls: data['memberProfileUrls'] != null
          ? Map<String, String>.from(data['memberProfileUrls'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      if (meetingImageUrl != null) 'meetingImageUrl': meetingImageUrl!,
      'memberIds': memberIds,
      'memberNames': memberNames,
      if (memberProfileUrls != null) 'memberProfileUrls': memberProfileUrls!,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class ChatService {
  // 명시적으로 기본 Firebase 앱의 Firestore 인스턴스 사용
  FirebaseFirestore get _firestore {
    final app = Firebase.app();
    print(
      '🔵 [ChatService] Firestore 인스턴스 확인 - 앱 이름: ${app.name}, 프로젝트 ID: ${app.options.projectId}',
    );
    return FirebaseFirestore.instanceFor(app: app);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase 프로젝트 정보 출력 (디버깅용)
  void printFirebaseInfo() {
    try {
      final app = Firebase.app();
      print('🔵 [ChatService] Firebase App 이름: ${app.name}');
      print('🔵 [ChatService] Firebase 프로젝트 ID: ${app.options.projectId}');
      print('🔵 [ChatService] Firebase 앱 ID: ${app.options.appId}');
      print('🔵 [ChatService] Firebase 데이터베이스 URL: ${app.options.databaseURL}');
      print(
        '🔵 [ChatService] Firebase Console 링크: https://console.firebase.google.com/project/${app.options.projectId}/firestore',
      );
    } catch (e) {
      print('⚠️ [ChatService] Firebase 정보 조회 오류: $e');
    }
  }

  /// 모임에 대한 채팅방이 있는지 확인
  Future<String?> getChatRoomId(String meetingId) async {
    try {
      final firestore = _firestore;
      print('🔵 [ChatService] getChatRoomId 시작 - meetingId: $meetingId');
      print(
        '🔵 [ChatService] getChatRoomId - Firestore 프로젝트: ${firestore.app.options.projectId}',
      );

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [ChatService] getChatRoomId: 로그인되지 않음');
        return null;
      }

      print('🔵 [ChatService] getChatRoomId - 현재 사용자 UID: ${currentUser.uid}');

      // meetingId와 memberIds를 함께 사용한 복합 쿼리
      // 이렇게 하면 보안 규칙과 쿼리 조건이 일치하여 쿼리가 허용됩니다
      final querySnapshot = await firestore
          .collection('chatRooms')
          .where('meetingId', isEqualTo: meetingId)
          .where('memberIds', arrayContains: currentUser.uid)
          .limit(1)
          .get();

      print(
        '🔵 [ChatService] getChatRoomId - 쿼리 결과: ${querySnapshot.docs.length}개 문서 발견',
      );

      if (querySnapshot.docs.isEmpty) {
        print('🔵 [ChatService] getChatRoomId - 채팅방 없음');
        return null;
      }

      final roomId = querySnapshot.docs.first.id;
      print('✅ [ChatService] getChatRoomId - 채팅방 발견: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      print('❌ [ChatService] 채팅방 조회 오류: $e');
      print('❌ [ChatService] 스택 트레이스: $stackTrace');
      if (e is FirebaseException) {
        print('❌ [ChatService] Firebase 오류 코드: ${e.code}');
        print('❌ [ChatService] Firebase 오류 메시지: ${e.message}');
        if (e.code == 'permission-denied') {
          print('⚠️ [ChatService] 권한 오류: Firestore 보안 규칙을 확인하세요!');
        }
      }
      return null;
    }
  }

  /// 채팅방 생성
  Future<String> createChatRoom({
    required String meetingId,
    required String meetingTitle,
    String? meetingImageUrl,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    Map<String, String>? memberProfileUrls,
  }) async {
    try {
      print('🔵 [ChatService] createChatRoom 시작');
      print('🔵 [ChatService] meetingId: $meetingId');
      print('🔵 [ChatService] memberIds: $memberIds');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [ChatService] 로그인되지 않음');
        throw Exception('로그인이 필요합니다');
      }

      print('🔵 [ChatService] 기존 채팅방 확인 중...');
      // 이미 채팅방이 있는지 확인
      final existingRoomId = await getChatRoomId(meetingId);
      if (existingRoomId != null) {
        print('✅ [ChatService] 기존 채팅방 발견: $existingRoomId');
        return existingRoomId;
      }

      print('🔵 [ChatService] 새 채팅방 생성 중...');

      final chatRoom = ChatRoom(
        id: '', // Firestore가 자동 생성
        meetingId: meetingId,
        meetingTitle: meetingTitle,
        meetingImageUrl: meetingImageUrl,
        memberIds: memberIds,
        memberNames: memberNames,
        memberProfileUrls: memberProfileUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🔵 [ChatService] Firestore에 데이터 추가 중...');
      final roomData = chatRoom.toMap();
      print('🔵 [ChatService] 저장할 데이터:');
      print('  - meetingId: ${roomData['meetingId']}');
      print('  - meetingTitle: ${roomData['meetingTitle']}');
      print('  - memberIds: ${roomData['memberIds']}');
      print('  - memberNames: ${roomData['memberNames']}');
      print('  - createdAt: ${roomData['createdAt']}');
      print('  - updatedAt: ${roomData['updatedAt']}');

      try {
        final firestore = _firestore;
        print(
          '🔵 [ChatService] createChatRoom - Firestore 프로젝트 ID: ${firestore.app.options.projectId}',
        );
        print('🔵 [ChatService] 저장할 컬렉션: chatRooms');
        final docRef = await firestore.collection('chatRooms').add(roomData);

        print('✅ [ChatService] Firestore에 추가 완료, 문서 ID: ${docRef.id}');

        // 저장 확인: 실제로 저장되었는지 확인
        final savedDoc = await docRef.get();
        if (!savedDoc.exists) {
          throw Exception('채팅방이 저장되지 않았습니다');
        }

        final savedData = savedDoc.data();
        print('✅ [ChatService] 저장 확인 완료');
        print('✅ [ChatService] 문서 ID: ${docRef.id}');
        print('✅ [ChatService] 문서 경로: ${savedDoc.reference.path}');
        print('✅ [ChatService] 저장된 memberIds: ${savedData?['memberIds']}');
        print('✅ [ChatService] 저장된 meetingId: ${savedData?['meetingId']}');
        print('✅ [ChatService] Firebase Console에서 확인:');
        print('   프로젝트: ${Firebase.app().options.projectId}');
        print('   컬렉션: chatRooms');
        print('   문서 ID: ${docRef.id}');

        return docRef.id;
      } catch (firestoreError) {
        print('❌ [ChatService] Firestore 저장 오류: $firestoreError');
        print('❌ [ChatService] 오류 타입: ${firestoreError.runtimeType}');
        if (firestoreError is FirebaseException) {
          print('❌ [ChatService] Firebase 오류 코드: ${firestoreError.code}');
          print('❌ [ChatService] Firebase 오류 메시지: ${firestoreError.message}');
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      print('❌ [ChatService] 채팅방 생성 오류: $e');
      print('❌ [ChatService] 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 채팅방 나가기
  Future<void> leaveChatRoom({required String roomId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final firestore = _firestore;
      final roomRef = firestore.collection('chatRooms').doc(roomId);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        throw Exception('채팅방을 찾을 수 없습니다');
      }

      final data = roomDoc.data();
      final memberIds = List<String>.from(data?['memberIds'] ?? []);
      final memberNames = Map<String, String>.from(
        data?['memberNames'] ?? data?['memberNicknames'] ?? {},
      );

      if (!memberIds.contains(currentUser.uid)) {
        throw Exception('이미 나간 채팅방입니다');
      }

      final leaverName = memberNames[currentUser.uid] ?? '알 수 없음';
      memberIds.remove(currentUser.uid);
      memberNames.remove(currentUser.uid);

      // 시스템 메시지 추가: "xxx님이 나갔습니다" (보안 규칙 통과 위해 userId는 본인 UID)
      await roomRef.collection('messages').add({
        'userId': currentUser.uid,
        'userName': leaverName,
        'message': '$leaverName님이 나갔습니다.',
        'type': 'system',
        'createdAt': Timestamp.now(),
      });

      await roomRef.update({
        'memberIds': memberIds,
        'memberNames': memberNames,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('채팅방 나가기 오류: $e');
      rethrow;
    }
  }

  /// 채팅방 멤버 추가
  Future<void> addMemberToChatRoom({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    try {
      final firestore = _firestore;
      print(
        '🔵 [ChatService] addMemberToChatRoom - Firestore 프로젝트 ID: ${firestore.app.options.projectId}',
      );
      final roomRef = firestore.collection('chatRooms').doc(roomId);

      await roomRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberNames.$userId': userName,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('멤버 추가 오류: $e');
      rethrow;
    }
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required String roomId,
    required String message,
    required String userName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final firestore = _firestore;
      print(
        '🔵 [ChatService] sendMessage - Firestore 프로젝트 ID: ${firestore.app.options.projectId}',
      );
      await firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .add({
            'userId': currentUser.uid,
            'userName': userName,
            'message': message,
            'createdAt': Timestamp.now(),
          });

      // 채팅방 업데이트 시간 갱신
      await _firestore.collection('chatRooms').doc(roomId).update({
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 메시지 스트림 (실시간 업데이트)
  Stream<List<ChatMessage>> getMessagesStream(String roomId) {
    final firestore = _firestore;
    print(
      '🔵 [ChatService] getMessagesStream - Firestore 프로젝트 ID: ${firestore.app.options.projectId}',
    );
    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  /// 1:1 채팅방 ID 생성 (두 사용자 UID를 정렬해 고정값 반환)
  String _getDirectChatRoomDocId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return 'dm_${sorted[0]}_${sorted[1]}';
  }

  /// 1:1 채팅방 생성 또는 조회
  /// (존재하지 않는 문서에 get()하면 보안 규칙에서 거부되므로, 쿼리로 기존 방 검색)
  Future<String> getOrCreateDirectChatRoom({
    required String otherUserId,
    required String otherUserName,
    String? otherProfileImageUrl,
    required String myUserName,
    String? myProfileImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다');
    }
    if (otherUserId == currentUser.uid) {
      throw Exception('본인에게 메시지를 보낼 수 없습니다');
    }

    final firestore = _firestore;

    // 본인이 멤버인 1:1 방만 쿼리 (보안 규칙 통과)
    final querySnapshot = await firestore
        .collection('chatRooms')
        .where('memberIds', arrayContains: currentUser.uid)
        .get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final meetingId = data['meetingId'] as String? ?? '';
      if (meetingId.isEmpty &&
          memberIds.length == 2 &&
          memberIds.contains(otherUserId)) {
        return doc.id;
      }
    }

    // 기존 방 없으면 새로 생성
    final docId = _getDirectChatRoomDocId(currentUser.uid, otherUserId);
    final docRef = firestore.collection('chatRooms').doc(docId);

    final memberIds = [currentUser.uid, otherUserId];
    final memberNames = {
      currentUser.uid: myUserName,
      otherUserId: otherUserName,
    };
    final memberProfileUrls = <String, String>{};
    if (myProfileImageUrl != null && myProfileImageUrl.isNotEmpty) {
      memberProfileUrls[currentUser.uid] = myProfileImageUrl;
    }
    if (otherProfileImageUrl != null && otherProfileImageUrl.isNotEmpty) {
      memberProfileUrls[otherUserId] = otherProfileImageUrl;
    }

    final roomData = {
      'meetingId': '', // 1:1 DM
      'meetingTitle': otherUserName,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'memberProfileUrls': memberProfileUrls,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    try {
      await docRef.set(roomData);
    } catch (e, stack) {
      print('❌ [ChatService] 1:1 채팅방 생성 실패: $e');
      print('❌ [ChatService] 스택: $stack');
      rethrow;
    }
    return docId;
  }

  /// 채팅방 정보 가져오기
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('chatRooms').doc(roomId).get();

      if (!doc.exists) {
        return null;
      }

      return ChatRoom.fromFirestore(doc);
    } catch (e) {
      print('채팅방 정보 조회 오류: $e');
      return null;
    }
  }

  /// 사용자가 참여한 채팅방 목록 가져오기 (스트림)
  Stream<List<ChatRoom>> getUserChatRoomsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ [ChatService] getUserChatRoomsStream: 로그인되지 않음');
      return Stream.value([]);
    }

    // Firebase 프로젝트 정보 출력
    printFirebaseInfo();

    print(
      '🔵 [ChatService] getUserChatRoomsStream: 현재 사용자 UID = ${currentUser.uid}',
    );

    // Firestore 인스턴스 확인 및 로그 출력
    final firestore = _firestore;
    print(
      '🔵 [ChatService] getUserChatRoomsStream - Firestore 프로젝트 ID: ${firestore.app.options.projectId}',
    );
    print(
      '🔵 [ChatService] 쿼리 실행: chatRooms 컬렉션에서 memberIds에 ${currentUser.uid} 포함된 문서 조회',
    );

    // 인덱스 없이도 작동하도록 먼저 필터링하고, 클라이언트에서 정렬
    return firestore
        .collection('chatRooms')
        .where('memberIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          print(
            '🔵 [ChatService] getUserChatRoomsStream: ${snapshot.docs.length}개의 채팅방 발견',
          );
          final rooms = snapshot.docs
              .map((doc) {
                final room = ChatRoom.fromFirestore(doc);
                print(
                  '🔵 [ChatService] 채팅방: id=${room.id}, meetingId=${room.meetingId}, memberIds=${room.memberIds}',
                );
                print(
                  '🔵 [ChatService] 사용자 UID가 memberIds에 포함되어 있는가? ${room.memberIds.contains(currentUser.uid)}',
                );
                return room;
              })
              .where(
                (room) => room.memberIds.contains(currentUser.uid),
              ) // 추가 필터링
              .toList();

          // 클라이언트에서 updatedAt 기준으로 정렬
          rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          print('🔵 [ChatService] 최종 채팅방 수: ${rooms.length}');
          return rooms;
        });
  }

  static const String _lastReadPrefix = 'chat_last_read_';

  static final _lastReadUpdatedController =
      StreamController<String>.broadcast(sync: true);

  /// 해당 채팅방의 읽지 않음 기준 시각 (SharedPreferences)
  Future<DateTime?> getLastReadAt(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('$_lastReadPrefix$roomId');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// 채팅방 진입 시 마지막 읽은 시각 갱신
  Future<void> updateLastRead(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_lastReadPrefix$roomId',
      DateTime.now().millisecondsSinceEpoch,
    );
    _lastReadUpdatedController.add(roomId);
  }

  /// 방별 읽지 않은 메시지 수 스트림 (본인 메시지 제외)
  /// updateLastRead 호출 시에도 재계산되도록 lastRead 갱신 스트림과 병합
  Stream<int> getRoomUnreadCountStream(String roomId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);
    final myUid = currentUser.uid;
    final firestore = _firestore;

    Future<int> computeCount(QuerySnapshot snapshot) async {
      final lastReadAt = await getLastReadAt(roomId);
      final cutoff = lastReadAt ?? DateTime(1970);
      int count = 0;
      for (final d in snapshot.docs) {
        final data = d.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final t = (data['createdAt'] as Timestamp?)?.toDate();
        final uid = data['userId'] as String? ?? '';
        if (t != null && t.isAfter(cutoff) && uid != myUid) count++;
      }
      return count;
    }

    final messagesStream = firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();

    final lastReadUpdates = _lastReadUpdatedController.stream
        .where((id) => id == roomId)
        .asyncMap((_) async {
      return await firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();
    });

    final controller = StreamController<int>.broadcast();
    StreamSubscription? sub1, sub2;

    void onData(QuerySnapshot snapshot) async {
      final count = await computeCount(snapshot);
      if (!controller.isClosed) controller.add(count);
    }

    sub1 = messagesStream.listen(onData);
    sub2 = lastReadUpdates.listen(onData);

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };

    return controller.stream;
  }

  /// 채팅방 삭제 (메시지 포함)
  Future<void> deleteChatRoom(String roomId) async {
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    try {
      // messages 하위 컬렉션 삭제
      while (true) {
        final snapshot = await roomRef
            .collection('messages')
            .limit(200)
            .get();
        if (snapshot.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await roomRef.delete();
    } catch (e, stack) {
      print('❌ [ChatService] 채팅방 삭제 실패: $e');
      print('❌ [ChatService] 스택: $stack');
      rethrow;
    }
  }

  /// 채팅방의 마지막 메시지 스트림 (리스트 부제목용)
  Stream<ChatMessage?> getLastMessageStream(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ChatMessage.fromFirestore(snapshot.docs.first);
        });
  }

  /// 채팅방의 마지막 메시지 가져오기
  Future<ChatMessage?> getLastMessage(String roomId) async {
    try {
      final firestore = _firestore;
      final querySnapshot = await firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ChatMessage.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('마지막 메시지 조회 오류: $e');
      return null;
    }
  }
}
