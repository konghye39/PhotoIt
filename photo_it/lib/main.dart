import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'gallery_saver.dart' if (dart.library.html) 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';

final deviceInfoPlugin = DeviceInfoPlugin();

// 백그라운드에서 실행할 이미지 처리 함수 (Top-level)
Future<Uint8List> _processImageInBackground(Map<String, dynamic> params) async {
  final Uint8List imageBytes = params['imageBytes'];
  final List<Map<String, dynamic>> blurPointsData = List<Map<String, dynamic>>.from(params['blurPoints']);
  final double scaleFactor = params['scaleFactor'];
  final int jpegQuality = params['jpegQuality'];
  final int blurRadius = params['blurRadius'];

  // 이미지 디코딩
  img.Image? originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    throw Exception('이미지를 읽을 수 없습니다');
  }

  // RGB 포맷으로 변환
  if (originalImage.numChannels == 4) {
    final srcImage = originalImage;
    originalImage = img.Image(
      width: srcImage.width,
      height: srcImage.height,
      numChannels: 3,
    );

    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final srcPixel = srcImage.getPixel(x, y);
        originalImage.setPixelRgb(x, y, srcPixel.r.toInt(), srcPixel.g.toInt(), srcPixel.b.toInt());
      }
    }
  }

  img.Image resultImage = originalImage;

  if (blurPointsData.isNotEmpty) {
    // 원본 이미지 복사
    final originalCopy = originalImage.clone();

    // 전체 이미지에 블러 적용
    final blurredFull = img.gaussianBlur(originalCopy, radius: blurRadius);

    // 블러 마스크 생성
    final mask = img.Image(
      width: originalImage.width,
      height: originalImage.height,
      numChannels: 1,
    );

    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }

    // 블러 포인트를 마스크에 표시
    for (var pointData in blurPointsData) {
      final x = (pointData['offsetX'] * originalImage.width).toInt();
      final y = (pointData['offsetY'] * originalImage.height).toInt();
      final radius = (pointData['size'] * originalImage.width / 2).toInt();

      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final px = x + dx;
          final py = y + dy;

          if (px >= 0 && px < mask.width && py >= 0 && py < mask.height) {
            final distance = (dx * dx + dy * dy).toDouble();
            if (distance <= radius * radius) {
              mask.setPixelRgb(px, py, 255, 255, 255);
            }
          }
        }
      }
    }

    // 마스크를 사용하여 원본과 블러 이미지 합성
    resultImage = originalImage.clone();

    for (int y = 0; y < resultImage.height; y++) {
      for (int x = 0; x < resultImage.width; x++) {
        final maskValue = mask.getPixel(x, y).r.toInt();

        if (maskValue > 0) {
          final blurPixel = blurredFull.getPixel(x, y);
          resultImage.setPixelRgb(x, y, blurPixel.r.toInt(), blurPixel.g.toInt(), blurPixel.b.toInt());
        }
      }
    }
  }

  // 이미지 크기 조정
  if (scaleFactor < 1.0) {
    resultImage = img.copyResize(
      resultImage,
      width: (resultImage.width * scaleFactor).toInt(),
      height: (resultImage.height * scaleFactor).toInt(),
      interpolation: img.Interpolation.average,
    );
  }

  // JPEG 인코딩
  final jpegBytes = img.encodeJpg(resultImage, quality: jpegQuality);

  return Uint8List.fromList(jpegBytes);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
      ),
      home: const PhotoItHomePage(),
    );
  }
}

class PhotoItHomePage extends StatefulWidget {
  const PhotoItHomePage({super.key});

  @override
  State<PhotoItHomePage> createState() => _PhotoItHomePageState();
}

class _PhotoItHomePageState extends State<PhotoItHomePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('사진 촬영 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _openGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('갤러리 열기 중 오류가 발생했습니다: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'PhotoIt',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),

              // 이미지 미리보기 영역
              Expanded(
                child: _selectedImage != null
                    ? BlurEditWidget(
                        imageFile: _selectedImage!,
                        onSave: (savedPath) {
                          _showSuccessSnackBar('저장 완료: $savedPath');
                        },
                        onChangePhoto: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      )
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: Icon(
                            Icons.image_outlined,
                            size: 120,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
              ),

              // 버튼 영역 (이미지가 없을 때만 표시)
              if (_selectedImage == null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassmorphismButton(
                          onTap: _takePhoto,
                          icon: Icons.camera_alt,
                          label: '사진 촬영',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassmorphismButton(
                          onTap: _openGallery,
                          icon: Icons.photo_library,
                          label: '사진 열기',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlurEditWidget extends StatefulWidget {
  final File imageFile;
  final Function(String) onSave;
  final VoidCallback onChangePhoto;

  const BlurEditWidget({
    super.key,
    required this.imageFile,
    required this.onSave,
    required this.onChangePhoto,
  });

  @override
  State<BlurEditWidget> createState() => _BlurEditWidgetState();
}

class _BlurEditWidgetState extends State<BlurEditWidget> {
  final List<BlurPoint> _blurPoints = [];
  final GlobalKey _imageKey = GlobalKey();
  bool _isSaving = false;
  double _blurIntensity = 15.0;
  double _blurSize = 30.0;
  Offset? _currentTouchPosition;
  Size? _imageSize;

  void _addBlurPoint(Offset point, double normalizedSize) {
    if (kDebugMode) {
      print('블러 포인트 추가: offset=(${point.dx.toStringAsFixed(3)}, ${point.dy.toStringAsFixed(3)}), size=${normalizedSize.toStringAsFixed(4)}');
    }
    setState(() {
      _blurPoints.add(BlurPoint(
        offset: point,
        intensity: _blurIntensity,
        size: normalizedSize,
      ));
    });
  }

  // BoxFit.contain으로 렌더링된 이미지의 실제 영역 계산
  Rect _calculateImageRect(Size containerSize, Size imageSize) {
    final double containerAspect = containerSize.width / containerSize.height;
    final double imageAspect = imageSize.width / imageSize.height;

    double renderedWidth;
    double renderedHeight;

    if (containerAspect > imageAspect) {
      // 컨테이너가 이미지보다 넓음 (위아래 여백)
      renderedHeight = containerSize.height;
      renderedWidth = renderedHeight * imageAspect;
    } else {
      // 컨테이너가 이미지보다 높음 (좌우 여백)
      renderedWidth = containerSize.width;
      renderedHeight = renderedWidth / imageAspect;
    }

    final double offsetX = (containerSize.width - renderedWidth) / 2;
    final double offsetY = (containerSize.height - renderedHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
  }

  // 터치 위치를 이미지 좌표로 변환
  Offset? _convertTouchToImageCoordinate(Offset touchPosition, Size containerSize) {
    if (_imageSize == null) {
      if (kDebugMode) {
        print('경고: _imageSize가 null입니다!');
      }
      return null;
    }

    final imageRect = _calculateImageRect(containerSize, _imageSize!);

    if (kDebugMode) {
      print('좌표 변환: 터치=(${touchPosition.dx.toStringAsFixed(1)}, ${touchPosition.dy.toStringAsFixed(1)})');
      print('  컨테이너 크기: ${containerSize.width.toStringAsFixed(1)}x${containerSize.height.toStringAsFixed(1)}');
      print('  이미지 렌더 영역: ${imageRect.left.toStringAsFixed(1)}, ${imageRect.top.toStringAsFixed(1)}, ${imageRect.width.toStringAsFixed(1)}x${imageRect.height.toStringAsFixed(1)}');
    }

    // 터치가 이미지 영역 내에 있는지 확인
    if (!imageRect.contains(touchPosition)) {
      if (kDebugMode) {
        print('  결과: 이미지 영역 밖 (무시됨)');
      }
      return null;
    }

    // 이미지 영역 기준으로 정규화 (0.0 ~ 1.0)
    final normalizedX = (touchPosition.dx - imageRect.left) / imageRect.width;
    final normalizedY = (touchPosition.dy - imageRect.top) / imageRect.height;

    if (kDebugMode) {
      print('  결과: 정규화된 좌표=(${normalizedX.toStringAsFixed(3)}, ${normalizedY.toStringAsFixed(3)})');
    }

    return Offset(normalizedX, normalizedY);
  }

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
      if (kDebugMode) {
        print('이미지 크기 로드 완료: ${_imageSize!.width.toInt()}x${_imageSize!.height.toInt()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('이미지 크기 로드 실패: $e');
      }
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        try {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            // Android 13 이상
            final status = await Permission.photos.request();
            return status.isGranted;
          } else {
            // Android 12 이하
            final status = await Permission.storage.request();
            return status.isGranted;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Android 권한 요청 오류: $e');
          }
          // 권한 요청 실패 시 기본 저장 시도
          return true;
        }
      } else if (Platform.isIOS) {
        try {
          final status = await Permission.photos.request();
          return status.isGranted;
        } catch (e) {
          if (kDebugMode) {
            print('iOS 권한 요청 오류: $e');
          }
          return true;
        }
      }
      return true; // Windows 및 기타 플랫폼
    } catch (e) {
      if (kDebugMode) {
        print('권한 요청 중 오류: $e');
      }
      return true;
    }
  }

  Future<void> _showQualityDialog() async {
    final quality = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
        title: Text(
          '저장 품질 선택',
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption(
              '저화질',
              '빠른 저장, 작은 파일 (50% 크기, 품질 70%)',
              'low',
              Icons.speed,
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              '중간 품질',
              '균형잡힌 품질과 속도 (75% 크기, 품질 85%)',
              'medium',
              Icons.balance,
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              '원본 품질',
              '최고 품질, 느린 저장 (100% 크기, 품질 95%)',
              'high',
              Icons.high_quality,
            ),
          ],
        ),
      ),
    );

    if (quality != null) {
      _saveImage(quality);
    }
  }

  Widget _buildQualityOption(String title, String subtitle, String value, IconData icon) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImage(String quality) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  '이미지 처리 중...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    String? savedPath;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 품질 설정
      double scaleFactor;
      int jpegQuality;
      String qualityName;

      switch (quality) {
        case 'low':
          scaleFactor = 0.5;
          jpegQuality = 70;
          qualityName = '저화질';
          break;
        case 'medium':
          scaleFactor = 0.75;
          jpegQuality = 85;
          qualityName = '중간';
          break;
        case 'high':
        default:
          scaleFactor = 1.0;
          jpegQuality = 95;
          qualityName = '원본';
          break;
      }

      if (kDebugMode) {
        print('저장 시작: $timestamp ($qualityName 품질)');
        print('설정: 크기 ${(scaleFactor * 100).toInt()}%, JPEG 품질 $jpegQuality%');
      }

      // 이미지 읽기
      final bytes = await widget.imageFile.readAsBytes();

      // 블러 강도 계산
      final maxIntensity = _blurPoints.isNotEmpty
          ? _blurPoints.map((p) => p.intensity).reduce((a, b) => a > b ? a : b)
          : 15.0;
      final blurRadius = (maxIntensity * 11).toInt();

      if (kDebugMode) {
        print('블러 포인트 개수: ${_blurPoints.length}');
        print('블러 강도: UI sigma=$maxIntensity, 저장 radius=$blurRadius');
      }

      // 백그라운드에서 이미지 처리 (UI 멈춤 없음!)
      final jpegBytes = await compute<Map<String, dynamic>, Uint8List>(
        _processImageInBackground,
        {
          'imageBytes': bytes,
          'blurPoints': _blurPoints.map((p) => {
            'offsetX': p.offset.dx,
            'offsetY': p.offset.dy,
            'intensity': p.intensity,
            'size': p.size,
          }).toList(),
          'scaleFactor': scaleFactor,
          'jpegQuality': jpegQuality,
          'blurRadius': blurRadius,
        },
      );

      if (kDebugMode) {
        print('백그라운드 처리 완료: ${jpegBytes.length} bytes (${(jpegBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      }

      // 플랫폼별 저장
      if (Platform.isWindows) {
        if (kDebugMode) {
          print('Windows 저장 시작');
        }

        try {
          final directory = await getApplicationDocumentsDirectory();
          final documentsPath = directory.path;

          // Documents/PhotoIt 폴더에 저장
          final photosDir = Directory('$documentsPath\\PhotoIt');

          if (!await photosDir.exists()) {
            await photosDir.create(recursive: true);
          }

          final filePath = '${photosDir.path}\\photoit_$timestamp.jpg';
          final file = File(filePath);
          await file.writeAsBytes(jpegBytes);
          savedPath = filePath;

          if (kDebugMode) {
            print('Windows 저장 완료: $savedPath');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Windows 저장 오류: $e');
          }
          throw Exception('Windows 저장 실패: $e');
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        if (kDebugMode) {
          print('모바일 저장 시작');
        }

        try {
          // 권한 요청
          final hasPermission = await _requestPermissions();
          if (!hasPermission) {
            throw Exception('저장 권한이 거부되었습니다');
          }

          // 임시 파일 생성
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/photoit_$timestamp.jpg');
          await tempFile.writeAsBytes(jpegBytes);

          if (kDebugMode) {
            print('임시 파일 생성: ${tempFile.path}');
          }

          // 갤러리에 저장
          await GallerySaver.saveImage(tempFile.path);
          savedPath = '갤러리에 저장됨';

          if (kDebugMode) {
            print('갤러리 저장 완료');
          }

          // 임시 파일 삭제
          try {
            await tempFile.delete();
          } catch (e) {
            if (kDebugMode) {
              print('임시 파일 삭제 실패: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('모바일 저장 오류: $e');
          }
          throw Exception('갤러리 저장 실패: $e');
        }
      } else {
        // 기타 플랫폼
        if (kDebugMode) {
          print('기타 플랫폼 저장');
        }

        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/photoit_$timestamp.jpg';
        final file = File(filePath);
        await file.writeAsBytes(jpegBytes);
        savedPath = filePath;
      }

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      // 성공 메시지
      if (savedPath != null && mounted) {
        widget.onSave(savedPath);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('저장 중 오류 발생: $e');
        print('Stack trace: $stackTrace');
      }

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 아이콘 버튼 + 슬라이더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // 아이콘 버튼 3개
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassIconButton(
                    icon: Icons.refresh,
                    onTap: widget.onChangePhoto,
                  ),
                  const SizedBox(width: 16),
                  GlassIconButton(
                    icon: Icons.clear,
                    onTap: () {
                      setState(() {
                        _blurPoints.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  GlassIconButton(
                    icon: _isSaving ? Icons.hourglass_empty : Icons.save,
                    onTap: _isSaving ? () {} : _showQualityDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 슬라이더 2개 (세로 배치)
              CompactSlider(
                label: '강도',
                value: _blurIntensity,
                min: 1,
                max: 30,
                onChanged: (value) {
                  setState(() {
                    _blurIntensity = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              CompactSlider(
                label: '크기',
                value: _blurSize,
                min: 10,
                max: 100,
                onChanged: (value) {
                  setState(() {
                    _blurSize = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 이미지 편집 영역
        Expanded(
          child: GestureDetector(
            onPanStart: (details) {
              final RenderBox? renderBox =
                  _imageKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null && _imageSize != null) {
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                final size = renderBox.size;

                setState(() {
                  _currentTouchPosition = localPosition;
                });

                final normalizedOffset = _convertTouchToImageCoordinate(localPosition, size);
                if (normalizedOffset != null) {
                  // 블러 크기를 렌더링된 이미지 크기 대비 비율로 정규화
                  final imageRect = _calculateImageRect(size, _imageSize!);
                  final normalizedSize = _blurSize / imageRect.width;
                  _addBlurPoint(normalizedOffset, normalizedSize);
                }
              }
            },
            onPanUpdate: (details) {
              final RenderBox? renderBox =
                  _imageKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null && _imageSize != null) {
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                final size = renderBox.size;

                setState(() {
                  _currentTouchPosition = localPosition;
                });

                final normalizedOffset = _convertTouchToImageCoordinate(localPosition, size);
                if (normalizedOffset != null) {
                  // 블러 크기를 렌더링된 이미지 크기 대비 비율로 정규화
                  final imageRect = _calculateImageRect(size, _imageSize!);
                  final normalizedSize = _blurSize / imageRect.width;
                  _addBlurPoint(normalizedOffset, normalizedSize);
                }
              }
            },
            onPanEnd: (details) {
              setState(() {
                _currentTouchPosition = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // 원본 이미지
                    SizedBox(
                      key: _imageKey,
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 블러된 이미지 레이어
                    Positioned.fill(
                      child: ClipPath(
                        clipper: BlurClipper(_blurPoints, _imageSize),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: _blurIntensity,
                            sigmaY: _blurIntensity,
                          ),
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // 브러쉬 크기 미리보기
                    if (_currentTouchPosition != null)
                      Positioned(
                        left: _currentTouchPosition!.dx - _blurSize / 2,
                        top: _currentTouchPosition!.dy - _blurSize / 2,
                        child: IgnorePointer(
                          child: Container(
                            width: _blurSize,
                            height: _blurSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class BlurPoint {
  final Offset offset;
  final double intensity;
  final double size;

  BlurPoint({
    required this.offset,
    required this.intensity,
    required this.size,
  });
}

class BlurClipper extends CustomClipper<Path> {
  final List<BlurPoint> blurPoints;
  final Size? imageSize;

  BlurClipper(this.blurPoints, this.imageSize);

  // BoxFit.contain으로 렌더링된 이미지의 실제 영역 계산
  Rect _calculateImageRect(Size containerSize, Size imageSize) {
    final double containerAspect = containerSize.width / containerSize.height;
    final double imageAspect = imageSize.width / imageSize.height;

    double renderedWidth;
    double renderedHeight;

    if (containerAspect > imageAspect) {
      renderedHeight = containerSize.height;
      renderedWidth = renderedHeight * imageAspect;
    } else {
      renderedWidth = containerSize.width;
      renderedHeight = renderedWidth / imageAspect;
    }

    final double offsetX = (containerSize.width - renderedWidth) / 2;
    final double offsetY = (containerSize.height - renderedHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
  }

  @override
  Path getClip(Size size) {
    final path = Path();

    if (imageSize == null) {
      return path;
    }

    // 이미지의 실제 렌더 영역 계산
    final imageRect = _calculateImageRect(size, imageSize!);

    for (var point in blurPoints) {
      // 이미지 렌더 영역 기준으로 좌표 계산
      final actualPoint = Offset(
        imageRect.left + point.offset.dx * imageRect.width,
        imageRect.top + point.offset.dy * imageRect.height,
      );
      // 이미지 렌더 영역 너비 기준으로 크기 계산
      final actualRadius = (point.size * imageRect.width) / 2;
      path.addOval(Rect.fromCircle(
        center: actualPoint,
        radius: actualRadius,
      ));
    }

    return path;
  }

  @override
  bool shouldReclip(BlurClipper oldClipper) => true;
}

class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const CompactSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.white.withOpacity(0.6),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: Colors.white.withOpacity(0.9),
                      overlayColor: Colors.white.withOpacity(0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    value.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassmorphismButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const GlassmorphismButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  State<GlassmorphismButton> createState() => _GlassmorphismButtonState();
}

class _GlassmorphismButtonState extends State<GlassmorphismButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
