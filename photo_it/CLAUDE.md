# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhotoIt is a Flutter application built with Dart SDK ^3.9.2 following MVVM + Riverpod + Clean Architecture patterns. The project implements a layered architecture with clear separation of concerns through Repository and UseCase patterns.

## Essential Commands

### Development
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run the app in release mode
- `flutter hot-reload` - Hot reload changes (press 'r' in running app)
- `flutter hot-restart` - Hot restart the app (press 'R' in running app)

### Building
- `flutter build apk` - Build APK for Android
- `flutter build appbundle` - Build Android App Bundle
- `flutter build ios` - Build for iOS (macOS only)
- `flutter build web` - Build for web

### Testing and Quality
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter analyze` - Run static analysis (linting)
- `dart format .` - Format all Dart files
- `flutter doctor` - Check Flutter installation and dependencies

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub outdated` - Check for outdated dependencies

### Code Generation
- `dart run build_runner build` - Generate code (Freezed, JSON serialization, Riverpod)
- `dart run build_runner build --delete-conflicting-outputs` - Force regenerate code
- `dart run build_runner watch` - Watch and regenerate code automatically

## Code Structure

- `lib/main.dart` - Main application entry point with MyApp and MyHomePage widgets
- `test/widget_test.dart` - Basic widget tests for the counter functionality
- `pubspec.yaml` - Project configuration and dependencies
- `analysis_options.yaml` - Dart analyzer configuration using flutter_lints

## Architecture Overview

### MVVM + Riverpod + Clean Architecture

The project follows a layered architecture with clear separation of concerns:

#### Layer Structure
```
lib/
├── presentation/           # UI Layer (Views + ViewModels)
│   ├── pages/             # Screen widgets
│   ├── widgets/           # Reusable UI components
│   └── viewmodels/        # Riverpod providers for state management
├── domain/                # Business Logic Layer
│   ├── entities/          # Business objects
│   ├── repositories/      # Abstract repository contracts
│   └── usecases/          # Business logic use cases
├── data/                  # Data Layer
│   ├── datasources/       # API clients, local storage
│   ├── models/            # Data models with JSON serialization
│   └── repositories/      # Repository implementations
└── core/                  # Shared utilities
    ├── constants/         # App constants
    ├── errors/            # Custom exceptions
    ├── network/           # HTTP client configuration
    └── utils/             # Helper functions
```

#### Key Patterns

**MVVM (Model-View-ViewModel)**
- Views: Flutter widgets that build UI
- ViewModels: Riverpod providers that manage state
- Models: Domain entities and data models

**Riverpod State Management**
- Use `Provider` for simple state
- Use `StateNotifierProvider` for complex state management
- Use `FutureProvider` for async data loading
- Use `StreamProvider` for real-time data

**Clean Architecture Principles**
- Dependency inversion: Domain layer doesn't depend on external layers
- Repository pattern: Abstract data access in domain, implement in data layer
- UseCase pattern: Encapsulate business logic in single-responsibility classes

#### Implementation Guidelines

**ViewModels with Riverpod**
```dart
final userViewModelProvider = StateNotifierProvider<UserViewModel, UserState>((ref) {
  return UserViewModel(ref.read(getUserUseCaseProvider));
});
```

**Repository Pattern**
```dart
// Domain layer - abstract
abstract class UserRepository {
  Future<User> getUser(String id);
}

// Data layer - implementation
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  // Implementation
}
```

**UseCase Pattern**
```dart
class GetUserUseCase {
  final UserRepository repository;

  Future<Either<Failure, User>> call(String userId) async {
    return await repository.getUser(userId);
  }
}
```

## Linting and Analysis

The project uses `flutter_lints` package with standard Flutter linting rules. Analysis options are configured in `analysis_options.yaml` with the standard Flutter lint set enabled.

## Dependencies

### Core Dependencies
- `flutter_riverpod` - State management with Riverpod
- `riverpod_annotation` - Code generation for Riverpod providers
- `freezed` - Immutable data classes and unions
- `json_annotation` - JSON serialization annotations

### Data & Network
- `dio` - HTTP client for API calls
- `retrofit` - Type-safe HTTP client generator
- `hive` / `shared_preferences` - Local storage solutions

### Development Dependencies
- `flutter_lints` ^5.0.0 - Recommended lints for Flutter
- `build_runner` - Code generation tool
- `freezed` - Code generation for data classes
- `json_serializable` - JSON serialization code generation
- `riverpod_generator` - Riverpod provider code generation
- `flutter_test` - Testing framework

### Recommended Additional Packages
- `dartz` - Functional programming (Either, Option types)
- `equatable` - Value equality without code generation
- `get_it` - Dependency injection (if needed alongside Riverpod)
- `flutter_screenutil` - Screen adaptation utilities
- `cached_network_image` - Image caching and loading

## Platform Support

The project includes Android configuration with:
- Package name: `com.kong.photo_it`
- Kotlin-based MainActivity
- Standard Android build configuration