# Copilot Instructions for Time Market Flutter App

## 프로젝트 개요
위치 기반 시간 거래 플랫폼의 Flutter 모바일 앱. 사용자가 시간을 판매/구매하고 지도에서 주변 거래를 찾을 수 있는 마켓플레이스 앱입니다.

## 핵심 아키텍처

### 폴더 구조와 역할
- `lib/models/`: 데이터 모델 (`Post`, `User`)
- `lib/services/`: API 통신 레이어 (`AuthService`, `TimePostService`, `UserService`)
- `lib/screens/`: UI 화면들, 각 화면은 `StatefulWidget`으로 구현
- `lib/providers/`: Provider 패턴용 (현재 비어있음)

### 상태 관리 패턴
- **현재**: 개별 `StatefulWidget`의 `setState()` 사용
- **Provider 미구현**: `user_provider.dart`가 비어있어 향후 Provider 패턴 도입 예정
- **로컬 상태**: 각 화면이 독립적으로 로딩 상태, 데이터 관리

### API 통신 아키텍처
**BaseURL 패턴**: 모든 서비스에서 `const String baseUrl = 'http://localhost:8000/api'` 사용

**인증 플로우**:
1. `AuthService`에서 JWT 토큰을 `FlutterSecureStorage`에 저장
2. 다른 서비스들이 `AuthService.getToken()`으로 토큰 조회
3. 모든 API 요청에 `Authorization: Bearer <token>` 헤더 추가

**HTTP 클라이언트 분화**:
- `AuthService`: Dio 사용 (FormData 지원)
- 다른 서비스들: http 패키지 사용

## 지도 시스템 구현

### 지도 라이브러리 혼용 주의
- `time_post_map_screen.dart`에서 **두 개의 다른 지도 패키지** 혼용:
  - `kakao_map_sdk` (카카오맵) - 현재 사용
  - `flutter_map` (OpenStreetMap) - 주석 처리됨
- 새 지도 기능 추가 시 일관된 패키지 사용 필요

### 마커 생성 패턴
```dart
Marker(
  width: 80,
  height: 80,
  point: LatLng(lat, lng),
  builder: (ctx) => GestureDetector(
    onTap: () => showDialog(...),
    child: Icon(Icons.location_pin, color: Colors.red, size: 40),
  ),
)
```

## 데이터 모델 규칙

### JSON 변환 패턴
```dart
factory Post.fromJson(Map<String, dynamic> json) {
  assert(json['user'] != null, "author 필드는 null일 수 없습니다");
  return Post(
    latitude: (json['latitude'] ?? 0).toDouble(),
    author: User.fromJson(json['user']), // 중첩 모델 변환
    createdAt: DateTime.parse(json['created_at']), // 스네이크 케이스 → 카멜 케이스
  );
}
```

## 네비게이션 패턴

### 화면 간 전환
- `pushReplacement()` 사용으로 뒤로가기 방지 (로그인→지도, 지도→목록)
- `Navigator.push()`로 새 화면 push 후 결과값 반환으로 데이터 갱신

### 인증 플로우
`main.dart`에서 `FutureBuilder<String?>`로 토큰 존재 여부 확인:
- 토큰 있음 → `TimePostMapScreen` (메인 화면)
- 토큰 없음 → `LoginScreen`

## 주요 개발 패턴

### API 서비스 에러 처리
```dart
try {
  final response = await dio.post(...);
  if (response.statusCode == 200) {
    // 성공 처리
    return true;
  }
} catch (e) {
  print('에러 로그: $e');
}
return false; // 실패시 기본 반환값
```

### 폼 데이터 vs JSON 데이터
- **회원가입**: `FormData` (이미지 업로드)
- **로그인/기타**: `JSON` 형태

### 화면별 AppBar 패턴
공통 AppBar 액션들:
- 로그아웃: `AuthService.logout()` → `LoginScreen`으로 이동
- 지도↔목록 전환: `Navigator.pushReplacement()`

## 의존성 관리

### 필수 패키지
- **지도**: `kakao_map_sdk: ^1.1.4`
- **HTTP**: `dio: ^5.8.0+1`, `http: ^0.13.6`
- **저장소**: `flutter_secure_storage: ^9.2.4`, `shared_preferences: ^2.2.2`
- **이미지**: `image_picker: ^0.8.7+4`

### 개발 시 주의사항
1. **일관된 HTTP 클라이언트 사용**: 새 서비스는 기존 패턴 따르기
2. **BaseURL 관리**: 하드코딩 대신 환경별 설정 필요
3. **지도 패키지 통일**: 카카오맵 또는 Flutter Map 중 선택
4. **Provider 패턴 도입**: 전역 상태 관리를 위한 준비 완료
5. **에러 처리 강화**: 네트워크 에러, 토큰 만료 등 예외 상황 대응

## 빌드 및 실행
```bash
flutter pub get
flutter run
# 또는 특정 플랫폼: flutter run -d chrome
```