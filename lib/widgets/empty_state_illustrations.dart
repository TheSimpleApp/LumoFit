import 'package:flutter/material.dart';
import 'package:fittravel/theme.dart';

/// A collection of elegant line-art vector illustrations for empty states.
///
/// Uses CustomPaint to create simple, minimal illustrations that match
/// the dark luxury theme with gold accents. Each illustration is designed
/// to be used with [EmptyStateWidget].
class EmptyStateIllustrations {
  EmptyStateIllustrations._();

  /// Default size for illustrations
  static const double defaultSize = 120;

  /// Creates an illustration for empty trips state.
  /// Shows a stylized globe with travel elements.
  static Widget trips({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _TripsPainter(),
    );
  }

  /// Creates an illustration for empty activities state.
  /// Shows a stylized running figure with motion lines.
  static Widget activities({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _ActivitiesPainter(),
    );
  }

  /// Creates an illustration for empty challenges state.
  /// Shows a trophy or target with achievement elements.
  static Widget challenges({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _ChallengesPainter(),
    );
  }

  /// Creates an illustration for empty gyms state.
  /// Shows gym equipment like a dumbbell.
  static Widget gyms({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _GymsPainter(),
    );
  }

  /// Creates an illustration for empty food/restaurants state.
  /// Shows healthy food elements.
  static Widget food({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _FoodPainter(),
    );
  }

  /// Creates an illustration for empty trails state.
  /// Shows mountain/trail hiking elements.
  static Widget trails({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _TrailsPainter(),
    );
  }

  /// Creates an illustration for empty events state.
  /// Shows calendar or event elements.
  static Widget events({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _EventsPainter(),
    );
  }

  /// Creates an illustration for empty photos state.
  /// Shows camera or photo elements.
  static Widget photos({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _PhotosPainter(),
    );
  }

  /// Creates an illustration for empty reviews state.
  /// Shows star or review elements.
  static Widget reviews({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _ReviewsPainter(),
    );
  }

  /// Creates an illustration for empty saved places state.
  /// Shows bookmark or pin elements.
  static Widget savedPlaces({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _SavedPlacesPainter(),
    );
  }

  /// Creates an illustration for empty search results.
  /// Shows search/magnifying glass elements.
  static Widget search({double size = defaultSize}) {
    return _IllustrationContainer(
      size: size,
      painter: _SearchPainter(),
    );
  }
}

/// Container widget that wraps CustomPaint with proper sizing
class _IllustrationContainer extends StatelessWidget {
  final double size;
  final CustomPainter painter;

  const _IllustrationContainer({
    required this.size,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: painter,
      ),
    );
  }
}

/// Base class for illustration painters providing common utilities
abstract class _BasePainter extends CustomPainter {
  /// Get the gold accent paint for primary strokes
  Paint get accentPaint => Paint()
    ..color = AppColors.primary
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Get the muted paint for secondary strokes
  Paint get mutedPaint => Paint()
    ..color = AppColors.primary.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Get the fill paint for accents
  Paint get fillPaint => Paint()
    ..color = AppColors.primary.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trips illustration - Globe with airplane path
class _TripsPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    // Globe circle
    canvas.drawCircle(center, radius, accentPaint);

    // Latitude lines
    final latPaint = mutedPaint..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.3,
      2.5,
      false,
      latPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.5,
      2.5,
      false,
      latPaint,
    );

    // Longitude line
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius * 0.4,
      center.dy,
      center.dx,
      center.dy + radius,
    );
    canvas.drawPath(path, latPaint);

    // Airplane
    final planePaint = accentPaint..strokeWidth = 2.5;
    final planeX = center.dx + radius * 0.8;
    final planeY = center.dy - radius * 0.6;

    // Plane body
    final planePath = Path();
    planePath.moveTo(planeX - 10, planeY + 5);
    planePath.lineTo(planeX + 10, planeY - 5);
    canvas.drawPath(planePath, planePaint);

    // Plane wings
    planePath.reset();
    planePath.moveTo(planeX - 2, planeY);
    planePath.lineTo(planeX - 8, planeY + 8);
    planePath.moveTo(planeX - 2, planeY);
    planePath.lineTo(planeX - 8, planeY - 4);
    canvas.drawPath(planePath, planePaint);

    // Dotted flight path
    final flightPaint = mutedPaint..strokeWidth = 1.5;
    for (int i = 0; i < 5; i++) {
      final startX = planeX - 18 - (i * 8);
      final startY = planeY + 10 + (i * 3);
      canvas.drawCircle(Offset(startX, startY), 1.5, flightPaint);
    }
  }
}

/// Activities illustration - Running figure with motion lines
class _ActivitiesPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Running figure - stylized
    final figurePaint = accentPaint..strokeWidth = 2.5;

    // Head
    canvas.drawCircle(Offset(cx + 5, cy - 18), 8, figurePaint);

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(cx + 5, cy - 10);
    bodyPath.lineTo(cx, cy + 5);
    canvas.drawPath(bodyPath, figurePaint);

    // Arms
    final armsPath = Path();
    armsPath.moveTo(cx - 12, cy - 8);
    armsPath.lineTo(cx + 2, cy - 5);
    armsPath.lineTo(cx + 15, cy - 12);
    canvas.drawPath(armsPath, figurePaint);

    // Front leg
    final frontLegPath = Path();
    frontLegPath.moveTo(cx, cy + 5);
    frontLegPath.lineTo(cx + 18, cy + 5);
    frontLegPath.lineTo(cx + 22, cy + 18);
    canvas.drawPath(frontLegPath, figurePaint);

    // Back leg
    final backLegPath = Path();
    backLegPath.moveTo(cx, cy + 5);
    backLegPath.lineTo(cx - 15, cy + 15);
    backLegPath.lineTo(cx - 20, cy + 8);
    canvas.drawPath(backLegPath, figurePaint);

    // Motion lines
    final motionPaint = mutedPaint..strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final y = cy - 10 + (i * 12);
      canvas.drawLine(
        Offset(cx - 25 - (i * 3), y),
        Offset(cx - 35 - (i * 3), y),
        motionPaint,
      );
    }
  }
}

/// Challenges illustration - Trophy with stars
class _ChallengesPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Trophy cup
    final trophyPaint = accentPaint..strokeWidth = 2.5;

    // Cup body
    final cupPath = Path();
    cupPath.moveTo(cx - 15, cy - 15);
    cupPath.lineTo(cx - 12, cy + 5);
    cupPath.quadraticBezierTo(cx, cy + 12, cx + 12, cy + 5);
    cupPath.lineTo(cx + 15, cy - 15);
    canvas.drawPath(cupPath, trophyPaint);

    // Cup rim
    canvas.drawLine(
      Offset(cx - 18, cy - 15),
      Offset(cx + 18, cy - 15),
      trophyPaint,
    );

    // Handles
    final handlePath = Path();
    handlePath.moveTo(cx - 15, cy - 10);
    handlePath.quadraticBezierTo(cx - 25, cy - 5, cx - 15, cy + 2);
    canvas.drawPath(handlePath, mutedPaint);

    handlePath.reset();
    handlePath.moveTo(cx + 15, cy - 10);
    handlePath.quadraticBezierTo(cx + 25, cy - 5, cx + 15, cy + 2);
    canvas.drawPath(handlePath, mutedPaint);

    // Base
    canvas.drawLine(
      Offset(cx, cy + 10),
      Offset(cx, cy + 18),
      trophyPaint,
    );
    canvas.drawLine(
      Offset(cx - 10, cy + 18),
      Offset(cx + 10, cy + 18),
      trophyPaint,
    );

    // Stars
    _drawStar(canvas, Offset(cx - 22, cy - 25), 5, mutedPaint);
    _drawStar(canvas, Offset(cx + 22, cy - 22), 4, mutedPaint);
    _drawStar(canvas, Offset(cx, cy - 30), 6, accentPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    // Simple 4-point star
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }
}

/// Gyms illustration - Dumbbell
class _GymsPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final barPaint = accentPaint..strokeWidth = 3.0;
    final weightPaint = accentPaint..strokeWidth = 2.5;

    // Bar
    canvas.drawLine(
      Offset(cx - 28, cy),
      Offset(cx + 28, cy),
      barPaint,
    );

    // Left weights
    _drawWeight(canvas, cx - 22, cy, 8, 16, weightPaint);
    _drawWeight(canvas, cx - 30, cy, 6, 12, mutedPaint);

    // Right weights
    _drawWeight(canvas, cx + 22, cy, 8, 16, weightPaint);
    _drawWeight(canvas, cx + 30, cy, 6, 12, mutedPaint);

    // Decorative motion lines
    final motionPaint = mutedPaint..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cx - 8, cy - 18),
      Offset(cx - 5, cy - 25),
      motionPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - 20),
      Offset(cx, cy - 28),
      motionPaint,
    );
    canvas.drawLine(
      Offset(cx + 8, cy - 18),
      Offset(cx + 5, cy - 25),
      motionPaint,
    );
  }

  void _drawWeight(Canvas canvas, double cx, double cy, double width,
      double height, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: width, height: height),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);
  }
}

/// Food illustration - Fork, leaf, and bowl
class _FoodPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bowl
    final bowlPaint = accentPaint..strokeWidth = 2.5;
    final bowlPath = Path();
    bowlPath.moveTo(cx - 22, cy);
    bowlPath.quadraticBezierTo(cx, cy + 22, cx + 22, cy);
    canvas.drawPath(bowlPath, bowlPaint);

    // Bowl rim
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 12),
      3.14,
      3.14,
      false,
      bowlPaint,
    );

    // Leaf/salad element
    final leafPaint = accentPaint..strokeWidth = 2.0;
    final leafPath = Path();
    leafPath.moveTo(cx - 8, cy - 5);
    leafPath.quadraticBezierTo(cx - 15, cy - 18, cx, cy - 12);
    leafPath.quadraticBezierTo(cx + 15, cy - 18, cx + 8, cy - 5);
    canvas.drawPath(leafPath, leafPaint);

    // Leaf stem
    canvas.drawLine(
      Offset(cx, cy - 12),
      Offset(cx, cy - 3),
      mutedPaint,
    );

    // Steam lines
    final steamPaint = mutedPaint..strokeWidth = 1.5;
    _drawSteam(canvas, cx - 10, cy - 22, steamPaint);
    _drawSteam(canvas, cx + 10, cy - 20, steamPaint);
  }

  void _drawSteam(Canvas canvas, double x, double y, Paint paint) {
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x - 3, y - 6, x, y - 10);
    path.quadraticBezierTo(x + 3, y - 14, x, y - 18);
    canvas.drawPath(path, paint);
  }
}

/// Trails illustration - Mountain with path
class _TrailsPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Main mountain
    final mountainPaint = accentPaint..strokeWidth = 2.5;
    final mountainPath = Path();
    mountainPath.moveTo(cx - 28, cy + 15);
    mountainPath.lineTo(cx - 5, cy - 20);
    mountainPath.lineTo(cx + 5, cy - 10);
    mountainPath.lineTo(cx + 15, cy - 25);
    mountainPath.lineTo(cx + 30, cy + 15);
    canvas.drawPath(mountainPath, mountainPaint);

    // Snow cap
    final snowPath = Path();
    snowPath.moveTo(cx + 8, cy - 18);
    snowPath.lineTo(cx + 15, cy - 25);
    snowPath.lineTo(cx + 22, cy - 15);
    canvas.drawPath(snowPath, mutedPaint);

    // Trail path (dotted)
    final trailPaint = mutedPaint..strokeWidth = 2.0;
    final trailPath = Path();
    trailPath.moveTo(cx - 20, cy + 15);
    trailPath.quadraticBezierTo(cx - 10, cy + 5, cx, cy + 8);
    trailPath.quadraticBezierTo(cx + 10, cy + 10, cx + 5, cy);
    canvas.drawPath(trailPath, trailPaint);

    // Sun
    canvas.drawCircle(Offset(cx - 18, cy - 22), 6, mutedPaint);

    // Sun rays
    for (int i = 0; i < 4; i++) {
      final angle = i * 1.57;
      final startX = (cx - 18) + 9 * _cos(angle);
      final startY = (cy - 22) + 9 * _sin(angle);
      final endX = (cx - 18) + 13 * _cos(angle);
      final endY = (cy - 22) + 13 * _sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), mutedPaint);
    }
  }

  double _cos(double angle) => _cosValues[angle.toInt() % 4];
  double _sin(double angle) => _sinValues[angle.toInt() % 4];

  static const _cosValues = [1.0, 0.0, -1.0, 0.0];
  static const _sinValues = [0.0, 1.0, 0.0, -1.0];
}

/// Events illustration - Calendar with date
class _EventsPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final calPaint = accentPaint..strokeWidth = 2.5;

    // Calendar body
    final calRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 44, height: 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(calRect, calPaint);

    // Calendar header bar
    canvas.drawLine(
      Offset(cx - 22, cy - 10),
      Offset(cx + 22, cy - 10),
      calPaint,
    );

    // Calendar hooks
    final hookPaint = accentPaint..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(cx - 10, cy - 20),
      Offset(cx - 10, cy - 12),
      hookPaint,
    );
    canvas.drawLine(
      Offset(cx + 10, cy - 20),
      Offset(cx + 10, cy - 12),
      hookPaint,
    );

    // Date dots (simplified calendar grid)
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final x = cx - 10 + (col * 10);
        final y = cy + 2 + (row * 10);
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }

    // Highlighted date
    canvas.drawCircle(
      Offset(cx + 10, cy + 12),
      5,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + 10, cy + 12),
      5,
      accentPaint..strokeWidth = 1.5,
    );
  }
}

/// Photos illustration - Camera
class _PhotosPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final cameraPaint = accentPaint..strokeWidth = 2.5;

    // Camera body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 48, height: 32),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, cameraPaint);

    // Viewfinder bump
    final viewfinderPath = Path();
    viewfinderPath.moveTo(cx - 8, cy - 13);
    viewfinderPath.lineTo(cx - 5, cy - 20);
    viewfinderPath.lineTo(cx + 5, cy - 20);
    viewfinderPath.lineTo(cx + 8, cy - 13);
    canvas.drawPath(viewfinderPath, cameraPaint);

    // Lens
    canvas.drawCircle(Offset(cx, cy + 3), 10, cameraPaint);
    canvas.drawCircle(Offset(cx, cy + 3), 5, mutedPaint);

    // Flash
    canvas.drawCircle(Offset(cx + 16, cy - 5), 3, fillPaint);
    canvas.drawCircle(Offset(cx + 16, cy - 5), 3, mutedPaint);

    // Shutter sparkle
    _drawSparkle(canvas, cx - 25, cy - 18, 4, mutedPaint);
    _drawSparkle(canvas, cx + 28, cy - 15, 3, mutedPaint);
  }

  void _drawSparkle(
      Canvas canvas, double x, double y, double size, Paint paint) {
    canvas.drawLine(
      Offset(x - size, y),
      Offset(x + size, y),
      paint,
    );
    canvas.drawLine(
      Offset(x, y - size),
      Offset(x, y + size),
      paint,
    );
  }
}

/// Reviews illustration - Star with quote bubble
class _ReviewsPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Quote bubble
    final bubblePaint = accentPaint..strokeWidth = 2.0;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 36),
      const Radius.circular(8),
    );
    canvas.drawRRect(bubbleRect, bubblePaint);

    // Bubble tail
    final tailPath = Path();
    tailPath.moveTo(cx - 5, cy + 18);
    tailPath.lineTo(cx - 12, cy + 26);
    tailPath.lineTo(cx + 2, cy + 18);
    canvas.drawPath(tailPath, bubblePaint);

    // Star inside bubble
    _drawStar5Point(canvas, Offset(cx, cy - 2), 12, accentPaint);

    // Small stars outside
    _drawStar5Point(canvas, Offset(cx - 28, cy - 15), 5, mutedPaint);
    _drawStar5Point(canvas, Offset(cx + 30, cy - 12), 4, mutedPaint);
  }

  void _drawStar5Point(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const angle = -1.5708; // Start at top

    for (int i = 0; i < 5; i++) {
      final outerAngle = angle + (i * 1.2566);
      final innerAngle = outerAngle + 0.6283;

      final outerX = center.dx + size * _cosAngle(outerAngle);
      final outerY = center.dy + size * _sinAngle(outerAngle);

      final innerX = center.dx + (size * 0.4) * _cosAngle(innerAngle);
      final innerY = center.dy + (size * 0.4) * _sinAngle(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cosAngle(double angle) {
    // Approximate cos for our angles
    return _cos(angle);
  }

  double _sinAngle(double angle) {
    // Approximate sin for our angles
    return _sin(angle);
  }

  // Simple sin/cos approximations
  double _cos(double x) {
    x = x % 6.2832;
    if (x < 0) x += 6.2832;
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }

  double _sin(double x) {
    return _cos(x - 1.5708);
  }
}

/// Saved Places illustration - Bookmark with heart/pin
class _SavedPlacesPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bookmark shape
    final bookmarkPaint = accentPaint..strokeWidth = 2.5;
    final bookmarkPath = Path();
    bookmarkPath.moveTo(cx - 15, cy - 25);
    bookmarkPath.lineTo(cx - 15, cy + 15);
    bookmarkPath.lineTo(cx, cy + 5);
    bookmarkPath.lineTo(cx + 15, cy + 15);
    bookmarkPath.lineTo(cx + 15, cy - 25);
    bookmarkPath.close();
    canvas.drawPath(bookmarkPath, bookmarkPaint);

    // Heart inside
    _drawHeart(canvas, Offset(cx, cy - 8), 10, accentPaint);

    // Location dots around
    final dotPaint = mutedPaint..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx - 25, cy - 10), 2, dotPaint);
    canvas.drawCircle(Offset(cx + 26, cy - 5), 2.5, dotPaint);
    canvas.drawCircle(Offset(cx - 22, cy + 12), 1.5, dotPaint);
    canvas.drawCircle(Offset(cx + 24, cy + 15), 2, dotPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;

    path.moveTo(x, y + size * 0.4);
    path.cubicTo(
      x - size,
      y - size * 0.2,
      x - size * 0.5,
      y - size * 0.8,
      x,
      y - size * 0.3,
    );
    path.cubicTo(
      x + size * 0.5,
      y - size * 0.8,
      x + size,
      y - size * 0.2,
      x,
      y + size * 0.4,
    );
    canvas.drawPath(path, paint);
  }
}

/// Search illustration - Magnifying glass with no results
class _SearchPainter extends _BasePainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final searchPaint = accentPaint..strokeWidth = 2.5;

    // Magnifying glass circle
    canvas.drawCircle(Offset(cx - 5, cy - 5), 18, searchPaint);

    // Handle
    canvas.drawLine(
      Offset(cx + 8, cy + 8),
      Offset(cx + 22, cy + 22),
      searchPaint..strokeWidth = 3.5,
    );

    // X inside (no results)
    final xPaint = mutedPaint..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(cx - 12, cy - 12),
      Offset(cx + 2, cy + 2),
      xPaint,
    );
    canvas.drawLine(
      Offset(cx + 2, cy - 12),
      Offset(cx - 12, cy + 2),
      xPaint,
    );

    // Question marks or dots around
    canvas.drawCircle(Offset(cx - 25, cy - 18), 1.5, mutedPaint);
    canvas.drawCircle(Offset(cx + 18, cy - 22), 2, mutedPaint);
    canvas.drawCircle(Offset(cx - 28, cy + 8), 2, mutedPaint);
  }
}
