import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'camera_count.dart';
import 'pose_rules.dart';

enum CameraProblem { denied, failed }

/// The front camera with the pose drawn over it and the reps counted so far.
/// Frames are read in memory as they arrive; none is saved or sent.
class CameraPoseView extends StatefulWidget {
  const CameraPoseView({super.key, required this.count, required this.canStart, required this.onProblem});

  final CameraCount count;

  /// Whether a new rep may begin now: not while resting or paused.
  final bool Function() canStart;
  final ValueChanged<CameraProblem> onProblem;

  @override
  State<CameraPoseView> createState() => _CameraPoseViewState();
}

class _CameraPoseViewState extends State<CameraPoseView> {
  static const _deviceDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final _detector = PoseDetector(options: PoseDetectorOptions());
  final _clock = Stopwatch()..start();

  // The camera is let go while the app is hidden, as Android expects.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onHide: _close, onShow: _open);
  CameraController? _camera;
  bool _busy = false;
  bool _disposed = false;

  // Test builds log the pose rate and reading speed, to tune on real phones.
  int _logged = 0;
  Duration _logSince = Duration.zero;
  Duration _logBusy = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    _open();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    _close();
    _detector.close();
    super.dispose();
  }

  Future<void> _open() async {
    if (_camera != null || _disposed) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('NoCamera', null);
      final description = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      if (_camera != null || _disposed) return;
      final camera = _camera = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await camera.initialize();
      if (_camera != camera) return;
      await camera.startImageStream((image) => _read(camera, image));
      _logSince = _clock.elapsed;
      if (mounted) setState(() {});
    } catch (e) {
      _close();
      if (!_disposed) widget.onProblem(e is CameraException && e.code == 'CameraAccessDenied' ? CameraProblem.denied : CameraProblem.failed);
    }
  }

  void _close() {
    final camera = _camera;
    _camera = null;
    camera?.dispose();
    if (camera != null && mounted && !_disposed) setState(() {});
  }

  InputImageRotation? _rotation(CameraController camera) {
    final device = _deviceDegrees[camera.value.deviceOrientation];
    if (device == null) return null;
    final sensor = camera.description.sensorOrientation;
    final front = camera.description.lensDirection == CameraLensDirection.front;
    return InputImageRotationValue.fromRawValue(front ? (sensor + device) % 360 : (sensor - device + 360) % 360);
  }

  Future<void> _read(CameraController camera, CameraImage image) async {
    // Frames that arrive while one is being read are dropped, so the count
    // never falls behind the picture.
    if (_busy || _camera != camera) return;
    final rotation = _rotation(camera);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format != InputImageFormat.nv21 || image.planes.length != 1) return;
    _busy = true;
    final at = _clock.elapsed;
    try {
      final plane = image.planes.first;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final poses = await _detector.processImage(
        InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(size: size, rotation: rotation, format: format!, bytesPerRow: plane.bytesPerRow),
        ),
      );
      if (_camera != camera) return;
      final sideways = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
      widget.count.addFrame(
        PoseFrame(
          poses.isEmpty ? null : poses.first.landmarks,
          sideways ? size.flipped : size,
          mirrored: camera.description.lensDirection == CameraLensDirection.front,
        ),
        at,
        canStart: widget.canStart(),
      );
      if (!kReleaseMode) _log(at);
    } catch (_) {
      // A frame the detector cannot read is skipped.
    } finally {
      _busy = false;
    }
  }

  void _log(Duration started) {
    _logBusy += _clock.elapsed - started;
    if (++_logged < 30) return;
    final seconds = (started - _logSince).inMicroseconds / 1e6;
    final counter = widget.count.counter;
    debugPrint(
      'pose: ${(_logged / seconds).toStringAsFixed(1)} fps, '
      '${(_logBusy.inMicroseconds / 1000 / _logged).toStringAsFixed(0)} ms each, '
      'movement ${counter.movement?.toStringAsFixed(1)}, reps ${counter.reps}, best ${counter.peak?.toStringAsFixed(1)}',
    );
    _logged = 0;
    _logSince = started;
    _logBusy = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final preview = camera?.value.previewSize;
    if (camera == null || !camera.value.isInitialized || preview == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              Text(context.l10n.cameraStarting, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
    // The preview size is given landscape; held upright the picture is tall.
    final picture = MediaQuery.orientationOf(context) == Orientation.portrait ? preview.flipped : preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(
              size: picture,
              child: CustomPaint(
                foregroundPainter: _SkeletonPainter(widget.count.pose, Theme.of(context).colorScheme.primary),
                child: CameraPreview(camera),
              ),
            ),
          ),
        ),
        ListenableBuilder(listenable: widget.count, builder: (context, _) => _CountOverlay(count: widget.count)),
      ],
    );
  }
}

/// The reps so far, the best movement and a nudge when the patient is out of view.
class _CountOverlay extends StatelessWidget {
  const _CountOverlay({required this.count});

  final CameraCount count;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final counter = count.counter;
    final peak = counter.peak;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: count.seen ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.accessibility_new, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(l.cameraStepBack, style: text.bodyMedium?.copyWith(color: Colors.white))),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Pill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    l.repsCount(counter.reps),
                    key: ValueKey(counter.reps),
                    style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Spacer(),
              if (peak != null)
                _Pill(child: Text(l.cameraBest(peak.round()), style: text.bodyMedium?.copyWith(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(Brand.of(context).radius)),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: child),
  );
}

/// Draws the bones the detector sees clearly. Repaints on each new pose
/// without rebuilding anything.
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.frame, this.color) : super(repaint: frame);

  final ValueListenable<PoseFrame?> frame;
  final Color color;

  static const _bones = [
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel),
    (PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex),
    (PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
    (PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel),
    (PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex),
    (PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex),
  ];

  static const _joints = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;
    final points = f?.landmarks;
    if (f == null || points == null) return;
    final sx = size.width / f.size.width;
    final sy = size.height / f.size.height;
    Offset? at(PoseLandmarkType type) {
      final p = points[type];
      if (p == null || p.likelihood < minLikelihood) return null;
      return Offset((f.mirrored ? f.size.width - p.x : p.x) * sx, p.y * sy);
    }

    // The canvas is the full camera picture, scaled down to fit later.
    final bone = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = size.shortestSide * 0.012
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _bones) {
      final pa = at(a);
      final pb = at(b);
      if (pa != null && pb != null) canvas.drawLine(pa, pb, bone);
    }
    final joint = Paint()..color = color;
    for (final type in _joints) {
      final p = at(type);
      if (p != null) canvas.drawCircle(p, size.shortestSide * 0.018, joint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.frame != frame || old.color != color;
}

/// Shows where to put the phone before the camera starts. True to start.
Future<bool> showCameraGuide(BuildContext context, CameraPlacement placement) async =>
    await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final l = context.l10n;
        final theme = Theme.of(context);
        Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.cameraGuideTitle, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  line(Icons.stay_current_portrait, switch (placement) {
                    CameraPlacement.sideStanding => l.cameraPlaceSideStanding,
                    CameraPlacement.sideLying => l.cameraPlaceSideLying,
                    CameraPlacement.frontLying => l.cameraPlaceFrontLying,
                  }),
                  line(Icons.light_mode_outlined, l.cameraGuideTips),
                  line(Icons.lock_outline, l.cameraPrivacy),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(l.startCamera),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ) ??
    false;
