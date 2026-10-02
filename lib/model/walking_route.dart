import 'dart:math' as math;

import 'places.dart';

/// A TMAP walking route: the line to draw and its totals.
class WalkingRoute {
  const WalkingRoute(
    this.points, {
    required this.meters,
    required this.seconds,
  });
  final List<MapViewport> points;
  final int meters, seconds;

  factory WalkingRoute.fromJson(Map<String, dynamic> json) => WalkingRoute(
    [
      for (final p in json['points'] as List)
        MapViewport(
          ((p as List)[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        ),
    ],
    meters: (json['meters'] as num).round(),
    seconds: (json['seconds'] as num).round(),
  );

  /// Where [at] falls on the line: the walked part is dropped. Searches from
  /// segment [from] on, so a route that doubles back never jumps ahead.
  // ponytail: nearest segment wins; a loop crossing itself within a few
  // meters could still skip ahead. Window the search if that shows up.
  RouteProgress progress(MapViewport at, {int from = 0}) {
    var best = from, bestT = 0.0, bestOff = double.infinity;
    for (var i = from; i < points.length - 1; i++) {
      final (t, off) = _project(at, points[i], points[i + 1]);
      if (off < bestOff) (best, bestT, bestOff) = (i, t, off);
    }
    final a = points[best], b = points[best + 1];
    final on = MapViewport(
      a.latitude + (b.latitude - a.latitude) * bestT,
      a.longitude + (b.longitude - a.longitude) * bestT,
    );
    final rest = [on, ...points.skip(best + 1)];
    var left = 0.0;
    for (var i = 0; i < rest.length - 1; i++) {
      left += distanceMeters(rest[i], rest[i + 1]);
    }
    return RouteProgress(rest, segment: best, meters: left, offRoute: bestOff);
  }
}

class RouteProgress {
  const RouteProgress(
    this.remaining, {
    required this.segment,
    required this.meters,
    required this.offRoute,
  });

  /// From my spot on the line to the destination.
  final List<MapViewport> remaining;

  /// The segment I'm on; pass back as `from` next time.
  final int segment;
  final double meters;

  /// How far I am from the line.
  final double offRoute;
}

const _earth = 6371000.0;
double _rad(double d) => d * math.pi / 180;

/// Equirectangular meters; exact enough at walking scale.
double distanceMeters(MapViewport a, MapViewport b) {
  final x =
      _rad(b.longitude - a.longitude) *
      math.cos(_rad((a.latitude + b.latitude) / 2));
  final y = _rad(b.latitude - a.latitude);
  return math.sqrt(x * x + y * y) * _earth;
}

/// [p] onto segment a→b: (fraction along it, meters away).
(double, double) _project(MapViewport p, MapViewport a, MapViewport b) {
  final k = math.cos(_rad(p.latitude));
  final bx = (b.longitude - a.longitude) * k, by = b.latitude - a.latitude;
  final px = (p.longitude - a.longitude) * k, py = p.latitude - a.latitude;
  final len = bx * bx + by * by;
  final t = len == 0 ? 0.0 : ((px * bx + py * by) / len).clamp(0.0, 1.0);
  final on = MapViewport(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
  return (t, distanceMeters(p, on));
}
