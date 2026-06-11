import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/attendance_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scanCtrl = MobileScannerController();
  final LocationService _locationService = LocationService();
  bool _hasScanned = false;
  bool _isProcessing = false;
  String? _resultMessage;
  bool? _resultSuccess;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrData = barcode!.rawValue!;

    // Parse QR: format "sessionId:qrToken"
    final parts = qrData.split(':');
    if (parts.length < 2) {
      _showResult(false, 'QR Code tidak valid');
      return;
    }
    final sessionId = parts[0];
    final qrToken = parts.sublist(1).join(':');

    setState(() {
      _hasScanned = true;
      _isProcessing = true;
    });

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Get location
    double? lat, lng;
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      lat = position.latitude;
      lng = position.longitude;
    }

    final result = await context.read<AttendanceProvider>().checkIn(
          sessionId: sessionId,
          studentId: user.id,
          qrToken: qrToken,
          latitude: lat,
          longitude: lng,
        );

    _showResult(result.success, result.message);
  }

  void _showResult(bool success, String message) {
    setState(() {
      _isProcessing = false;
      _resultSuccess = success;
      _resultMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          if (!_hasScanned)
            MobileScanner(
              controller: _scanCtrl,
              onDetect: _handleScan,
            ),

          // Dark overlay when result shown
          if (_hasScanned)
            Container(color: AppColors.adminBg),

          // Result overlay
          if (_hasScanned && !_isProcessing && _resultMessage != null)
            _ResultOverlay(
              success: _resultSuccess ?? false,
              message: _resultMessage!,
              onDismiss: () => context.pop(),
              onRetry: () {
                setState(() {
                  _hasScanned = false;
                  _resultMessage = null;
                  _resultSuccess = null;
                });
              },
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: AppColors.adminBg,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text('Memverifikasi absensi...', style: AppTextStyles.body.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Text('Scan QR Absensi', style: AppTextStyles.h3),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _scanCtrl.toggleTorch(),
                        icon: const Icon(
                          Icons.flashlight_on_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scan frame overlay
                if (!_hasScanned) ...[
                  const Spacer(),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dimmed overlay
                        Container(
                          width: double.infinity,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ).animate(
                          onPlay: (ctrl) => ctrl.repeat(reverse: true),
                        ).custom(
                          duration: 1500.ms,
                          builder: (ctx, val, child) => Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.5 + val * 0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        // Corner indicators
                        _ScanCorner(top: true, left: true),
                        _ScanCorner(top: true, left: false),
                        _ScanCorner(top: false, left: true),
                        _ScanCorner(top: false, left: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Arahkan kamera ke QR Code\nyang ditampilkan oleh dosen',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanCorner extends StatelessWidget {
  final bool top;
  final bool left;
  const _ScanCorner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: AppColors.accentLight, width: 4)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: AppColors.accentLight, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: AppColors.accentLight, width: 4)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: AppColors.accentLight, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  final bool success;
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const _ResultOverlay({
    required this.success,
    required this.message,
    required this.onDismiss,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.danger;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 50,
              ),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              success ? 'Absensi Berhasil!' : 'Absensi Gagal',
              style: AppTextStyles.h2.copyWith(color: color),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.grey600),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  success ? 'Selesai' : 'Kembali',
                  style: AppTextStyles.button,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            if (!success) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Scan Ulang',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.adminPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
