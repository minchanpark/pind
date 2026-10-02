import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/walking_route.dart';

void main() {
  // An L: ~111m north, then ~88m east (at 37.5°).
  const a = MapViewport(37.5000, 127.0000);
  const b = MapViewport(37.5010, 127.0000);
  const c = MapViewport(37.5010, 127.0010);
  final route = WalkingRoute.fromJson({
    'points': [
      [37.5000, 127.0000],
      [37.5010, 127.0000],
      [37.5010, 127.0010],
    ],
    'meters': 200,
    'seconds': 150,
  });

  test('parses points and totals', () {
    expect(route.points.map((p) => (p.latitude, p.longitude)), [
      (a.latitude, a.longitude),
      (b.latitude, b.longitude),
      (c.latitude, c.longitude),
    ]);
    expect((route.meters, route.seconds), (200, 150));
  });

  test('at the start the whole line remains', () {
    final p = route.progress(a);
    expect(p.remaining, hasLength(3));
    expect(p.offRoute, closeTo(0, .01));
    expect(p.meters, closeTo(distanceMeters(a, b) + distanceMeters(b, c), .01));
  });

  test('halfway up, beside the line: the walked half is gone', () {
    // 10m east of the first leg's midpoint.
    final p = route.progress(const MapViewport(37.5005, 127.000113));
    expect(p.segment, 0);
    expect(p.remaining.first.latitude, closeTo(37.5005, 1e-7));
    expect(p.remaining.first.longitude, closeTo(127.0, 1e-7));
    expect(p.remaining.skip(1).map((p) => (p.latitude, p.longitude)), [
      (b.latitude, b.longitude),
      (c.latitude, c.longitude),
    ]);
    expect(p.offRoute, closeTo(10, .5));
    expect(
      p.meters,
      closeTo(distanceMeters(a, b) / 2 + distanceMeters(b, c), .5),
    );
  });

  test('on the second leg, never back to the first', () {
    final p = route.progress(const MapViewport(37.5010, 127.0005));
    expect(p.segment, 1);
    expect(p.remaining, hasLength(2));
    expect(p.meters, closeTo(distanceMeters(b, c) / 2, .5));
    // Searching from segment 1 ignores the first leg even when nearer.
    final back = route.progress(const MapViewport(37.5005, 127.0), from: 1);
    expect(back.segment, 1);
  });

  test('at the end nothing remains', () {
    final p = route.progress(c);
    expect(p.meters, closeTo(0, .01));
  });
}
