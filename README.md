# PhotoIt

Flutter 기반 사진 관리 애플리케이션입니다.

## 프로젝트 개요

PhotoIt은 MVVM + Riverpod + Clean Architecture 패턴을 적용한 Flutter 애플리케이션입니다. 계층화된 아키텍처를 통해 관심사의 명확한 분리와 Repository, UseCase 패턴을 구현합니다.

## 기술 스택

- **Flutter** - 크로스 플랫폼 UI 프레임워크
- **Dart** ^3.9.2 - 프로그래밍 언어
- **Riverpod** - 상태 관리
- **Clean Architecture** - 아키텍처 패턴
- **MVVM** - 디자인 패턴

## 사전 요구사항

시작하기 전에 다음 항목들이 설치되어 있어야 합니다:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (최신 stable 버전)
- [Dart SDK](https://dart.dev/get-dart) ^3.9.2
- Android Studio / Xcode (모바일 개발용)
- Visual Studio Code 또는 Android Studio (IDE)

### Flutter 설치 확인

```bash
flutter doctor
```

이 명령어로 Flutter 개발 환경이 올바르게 설정되었는지 확인할 수 있습니다.

## 설치 및 실행

### 1. 저장소 클론

```bash
git clone <repository-url>
cd PhotoIt/photo_it
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 앱 실행

#### 디버그 모드로 실행
```bash
flutter run
```

#### 릴리즈 모드로 실행
```bash
flutter run --release
```

#### 특정 디바이스에서 실행
```bash
# 연결된 디바이스 확인
flutter devices

# 특정 디바이스 선택하여 실행
flutter run -d <device-id>
```

### 4. Hot Reload 사용

앱이 실행 중일 때:
- `r` 키를 누르면 Hot Reload (빠른 리로드)
- `R` 키를 누르면 Hot Restart (완전 재시작)

## 빌드

### Android APK 빌드
```bash
flutter build apk
```

### Android App Bundle 빌드 (Play Store 배포용)
```bash
flutter build appbundle
```

### iOS 빌드 (macOS만 가능)
```bash
flutter build ios
```

### Web 빌드
```bash
flutter build web
```

## 프로젝트 구조

```
lib/
├── presentation/           # UI 레이어 (Views + ViewModels)
│   ├── pages/             # 화면 위젯
│   ├── widgets/           # 재사용 가능한 UI 컴포넌트
│   └── viewmodels/        # Riverpod 상태 관리 프로바이더
├── domain/                # 비즈니스 로직 레이어
│   ├── entities/          # 비즈니스 객체
│   ├── repositories/      # 추상 리포지토리 인터페이스
│   └── usecases/          # 비즈니스 로직 유즈케이스
├── data/                  # 데이터 레이어
│   ├── datasources/       # API 클라이언트, 로컬 스토리지
│   ├── models/            # JSON 직렬화를 포함한 데이터 모델
│   └── repositories/      # 리포지토리 구현체
└── core/                  # 공유 유틸리티
    ├── constants/         # 앱 상수
    ├── errors/            # 커스텀 예외
    ├── network/           # HTTP 클라이언트 설정
    └── utils/             # 헬퍼 함수
```

## 아키텍처 패턴

### MVVM (Model-View-ViewModel)
- **View**: UI를 빌드하는 Flutter 위젯
- **ViewModel**: 상태를 관리하는 Riverpod 프로바이더
- **Model**: 도메인 엔티티와 데이터 모델

### Clean Architecture
- **의존성 역전**: 도메인 레이어는 외부 레이어에 의존하지 않음
- **Repository 패턴**: 도메인에서 데이터 접근을 추상화하고 데이터 레이어에서 구현
- **UseCase 패턴**: 단일 책임 원칙을 따르는 비즈니스 로직 캡슐화

## 개발

### 테스트 실행

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/widget_test.dart
```

### 코드 분석 및 포맷팅

```bash
# 정적 분석 (린팅)
flutter analyze

# 코드 포맷팅
dart format .
```

### 의존성 관리

```bash
# 의존성 업그레이드
flutter pub upgrade

# 오래된 의존성 확인
flutter pub outdated
```

### 코드 생성

프로젝트에서 Freezed, JSON 직렬화, Riverpod 코드 생성이 필요한 경우:

```bash
# 코드 생성
dart run build_runner build

# 충돌 파일 덮어쓰기
dart run build_runner build --delete-conflicting-outputs

# 자동 감시 및 재생성
dart run build_runner watch
```

## 주요 의존성

### 프로덕션
- `cupertino_icons` ^1.0.8 - iOS 스타일 아이콘

### 개발
- `flutter_test` - 테스트 프레임워크
- `flutter_lints` ^5.0.0 - Flutter 권장 린팅 규칙

## 플랫폼 지원

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Linux
- ✅ macOS
- ✅ Windows

## 설정 파일

- `pubspec.yaml` - 프로젝트 설정 및 의존성
- `analysis_options.yaml` - Dart 분석기 설정
- `.gitignore` - Git 버전 관리 제외 파일

## 문제 해결

### Flutter Doctor 문제
```bash
flutter doctor -v
```
위 명령어로 상세한 진단 정보를 확인하고 누락된 구성요소를 설치하세요.

### 의존성 충돌
```bash
flutter clean
flutter pub get
```

### 빌드 캐시 삭제
```bash
flutter clean
```

## 라이선스


## 참고 자료

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Dart 언어 가이드](https://dart.dev/guides)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Riverpod 문서](https://riverpod.dev/)

## 기여

프로젝트 기여 방법이나 개발 가이드라인이 필요한 경우 `CLAUDE.md` 파일을 참조하세요.
