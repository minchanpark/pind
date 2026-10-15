import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/post_photo_service.dart';
import '../components/pind_glass.dart';
import '../components/pind_pressable.dart';
import '../components/pind_skeleton.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';

/// Front captures come back unmirrored while the preview is mirrored; flip
/// them so the shot matches what the user framed.
/// ponytail: one knob for both platforms, split per platform if a device
/// disagrees.
const mirrorFrontCapture = true;

/// Two shots in a row, composed into one 2:3 photo: PiP (back, then front in
/// a box movable before and after shooting) or split (top, then bottom, each
/// half with its own lens). Pops with the composed [PostPhoto].
class PostCameraScreen extends StatefulWidget {
  const PostCameraScreen({super.key, required this.layout});
  final CameraLayout layout;

  @override
  State<PostCameraScreen> createState() => _PostCameraScreenState();
}

class _PostCameraScreenState extends State<PostCameraScreen>
    with WidgetsBindingObserver {
  late final lenses = switch (widget.layout) {
    CameraLayout.pip => [CameraLensDirection.back, CameraLensDirection.front],
    CameraLayout.split => [CameraLensDirection.back, CameraLensDirection.back],
  };

  /// Each shot's full JPEG for composing, and a screen-sized decode for show.
  final shots = <(Uint8List, ImageProvider shown, bool mirror)>[];
  List<CameraDescription> cameras = [];
  CameraController? camera;
  Offset inset = clampInset(const Offset(.2, .55));
  bool busy = false, failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    busy = true;
    start().whenComplete(() {
      if (mounted) setState(() => busy = false);
    });
  }

  Future<void> start() async {
    try {
      cameras = await availableCameras();
    } on CameraException {
      cameras = [];
    }
    if (cameras.isEmpty) {
      if (mounted) setState(() => failed = true);
      return;
    }
    await open();
  }

  /// Opens the lens for the next shot; only one camera runs at a time.
  Future<void> open() async {
    final lens = shots.length < 2 ? lenses[shots.length] : null;
    final old = camera;
    // Split's halves usually share a lens: keep it running, no blank swap.
    if (old != null && old.description.lensDirection == lens) return;
    if (mounted) setState(() => camera = null);
    await old?.dispose();
    if (!mounted || lens == null) return;
    final next = CameraController(
      cameras.firstWhere(
        (c) => c.lensDirection == lens,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await next.initialize();
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      // Auto flash meters before every shot and fires in dim rooms; lenses
      // without a flash refuse the call.
      await next
          .setFlashMode(FlashMode.off)
          .onError<CameraException>((_, _) {});
    } on CameraException {
      await next.dispose();
      if (mounted) setState(() => failed = true);
      return;
    }
    if (!mounted) return next.dispose();
    setState(() => camera = next);
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> shoot() => run(() async {
    final c = camera;
    if (c == null || !c.value.isInitialized) return;
    HapticFeedback.lightImpact();
    try {
      final bytes = await (await c.takePicture()).readAsBytes();
      if (!mounted) return;
      // Decoded at screen size before it shows, so the shot lands whole
      // instead of blank-then-pop. A square bound fits either EXIF rotation.
      final screen =
          MediaQuery.sizeOf(context) * MediaQuery.devicePixelRatioOf(context);
      final side = screen.longestSide.round();
      final shown = ResizeImage(
        MemoryImage(bytes),
        width: side,
        height: side,
        policy: ResizeImagePolicy.fit,
      );
      await precacheImage(shown, context);
      final front = c.description.lensDirection == CameraLensDirection.front;
      setState(() => shots.add((bytes, shown, front && mirrorFrontCapture)));
    } on CameraException {
      return message(l10n.errPhotoLoad);
    }
    await open();
  });

  Future<void> flip(int slot) => run(() async {
    lenses[slot] = lenses[slot] == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    if (slot == shots.length) {
      await open();
    } else {
      setState(() {});
    }
  });

  Future<void> retake() => run(() async {
    shots.clear();
    await open();
  });

  Future<void> use() => run(() async {
    final images = <ui.Image>[];
    try {
      for (final (bytes, _, _) in shots) {
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetHeight: cameraShotSize.height.toInt(),
        );
        try {
          images.add((await codec.getNextFrame()).image);
        } finally {
          codec.dispose();
        }
      }
      final photo = await composeCameraShot(widget.layout, inset, [
        for (final (i, (_, _, mirror)) in shots.indexed) (images[i], mirror),
      ]);
      if (mounted) Navigator.pop(context, photo);
    } catch (_) {
      message(l10n.errPhotoLoad);
    } finally {
      for (final image in images) {
        image.dispose();
      }
    }
  });

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The plugin doesn't release the camera in the background.
    if (cameras.isEmpty || busy) return;
    if (state == AppLifecycleState.inactive) {
      final old = camera;
      setState(() => camera = null);
      old?.dispose();
    } else if (state == AppLifecycleState.resumed && camera == null) {
      run(open);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([]);
    camera?.dispose();
    super.dispose();
  }

  /// What a slot shows under its preview or shot; breathes while its
  /// camera opens.
  Widget placeholder(int index) {
    final box = ColoredBox(
      color: Colors.white10,
      child: Center(
        child: Icon(
          lenses[index] == CameraLensDirection.front
              ? Icons.face_outlined
              : Icons.photo_camera_outlined,
          color: Colors.white54,
        ),
      ),
    );
    return index == shots.length && camera == null
        ? PindSkeleton(child: box)
        : box;
  }

  Widget slot(int index) {
    final c = camera;
    return Stack(
      fit: StackFit.expand,
      children: [
        placeholder(index),
        if (index < shots.length)
          // Lands white and clears: the shutter's flash.
          TweenAnimationBuilder(
            key: ObjectKey(shots[index].$2),
            tween: Tween(begin: .85, end: 0.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, flash, child) => DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: flash),
              ),
              child: child,
            ),
            child: Transform.flip(
              flipX: shots[index].$3,
              child: Image(
                image: shots[index].$2,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          )
        else if (index == shots.length && c != null && c.value.isInitialized)
          // A fresh preview fades in over the placeholder.
          TweenAnimationBuilder(
            key: ObjectKey(c),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (_, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                // previewSize is landscape; the screen is locked portrait.
                child: SizedBox(
                  width: c.value.previewSize!.height,
                  height: c.value.previewSize!.width,
                  child: CameraPreview(c),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The round dark-glass chrome over the camera: close and flip.
  Widget glassButton(String label, IconData icon, VoidCallback? onTap) =>
      Semantics(
        button: true,
        label: label,
        child: PindGlass(
          tone: PindGlassTone.dark,
          radius: 20,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 38,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );

  Widget frame() => LayoutBuilder(
    builder: (_, box) {
      final (first, second) = cameraRects(widget.layout, box.biggest, inset);
      final corners = BorderRadius.circular(PindRadius.field);
      return Stack(
        children: [
          Positioned.fromRect(rect: first, child: slot(0)),
          Positioned.fromRect(
            rect: second,
            child: widget.layout == CameraLayout.pip
                ? GestureDetector(
                    onPanUpdate: (drag) => setState(
                      () => inset = clampInset(
                        inset +
                            Offset(
                              drag.delta.dx / box.maxWidth,
                              drag.delta.dy / box.maxHeight,
                            ),
                      ),
                    ),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: corners,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(borderRadius: corners, child: slot(1)),
                    ),
                  )
                : slot(1),
          ),
          if (widget.layout == CameraLayout.split)
            for (final (index, rect) in [first, second].indexed)
              if (index >= shots.length)
                Positioned(
                  right: 10,
                  bottom: box.maxHeight - rect.bottom + 10,
                  child: glassButton(
                    l10n.cameraFlip,
                    Icons.cameraswitch_outlined,
                    busy ? null : () => flip(index),
                  ),
                ),
        ],
      );
    },
  );

  Widget controls() {
    if (shots.length < 2) {
      final ready = !busy && camera != null;
      return Semantics(
        button: true,
        label: l10n.cameraShutter,
        child: PindPressable(
          scale: .9,
          child: GestureDetector(
            onTap: ready ? shoot : null,
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ready
                      ? PindColors.purple
                      : PindColors.purple.withValues(alpha: .45),
                ),
              ),
            ),
          ),
        ),
      );
    }
    // The theme's FilledButton is full-width (minimumSize fromHeight), so
    // each button needs a bounded share of the row.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: PindGlass(
              tone: PindGlassTone.dark,
              radius: PindRadius.sheet,
              child: InkWell(
                onTap: busy ? null : retake,
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
                      l10n.cameraRetake,
                      style: PindText.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : use,
              style: FilledButton.styleFrom(backgroundColor: PindColors.purple),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.cameraUse),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: glassButton(
                l10n.close,
                Icons.close,
                () => Navigator.maybePop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: failed
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        l10n.qrCameraDenied,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: PindType.body,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AspectRatio(
                        aspectRatio:
                            cameraShotSize.width / cameraShotSize.height,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(PindRadius.card),
                          child: frame(),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            height: 112,
            child: Center(
              child: failed
                  ? null
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: controls(),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
