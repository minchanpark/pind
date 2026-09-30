import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../model/profile_link.dart';

/// The first scanned value that is a Pind profile link.
ProfileLink? firstProfileLink(Iterable<String?> raws) {
  for (final raw in raws) {
    final link = raw == null ? null : ProfileLink.parse(raw);
    if (link != null) return link;
  }
  return null;
}

/// Full-screen camera; pops with the scanned [ProfileLink].
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool done = false, wrong = false;
  Timer? clear;

  void detected(BarcodeCapture capture) {
    if (done) return;
    final raws = capture.barcodes.map((b) => b.rawValue);
    final link = firstProfileLink(raws);
    if (link != null) {
      done = true;
      Navigator.pop(context, link);
    } else if (raws.any((r) => r != null)) {
      clear?.cancel();
      clear = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => wrong = false);
      });
      if (!wrong) setState(() => wrong = true);
    }
  }

  @override
  void dispose() {
    clear?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: detected,
            errorBuilder: (_, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  '카메라를 사용할 수 없어요. 설정에서 카메라 권한을 허용해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          const IgnorePointer(child: CustomPaint(painter: _Frame())),
          // Centered with the frame, so this lands just under it.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: _Frame.side + 64),
              child: Text(
                wrong ? 'Pind 친구 코드가 아니에요' : '친구의 Pind QR 코드를 네모 안에 맞춰 주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: wrong ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      '친구 코드 스캔',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything but a centered rounded square.
class _Frame extends CustomPainter {
  const _Frame();
  static const side = 250.0;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: side,
        height: side,
      ),
      const Radius.circular(24),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(hole),
      Paint()..color = const Color.fromRGBO(0, 0, 0, .55),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_Frame old) => false;
}
