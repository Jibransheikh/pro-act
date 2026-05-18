import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  final List<String> _excuses = [
    "I'm too tired",
    "I'll start tomorrow",
    "It's too cold",
    "I don't have time",
    "One day won't hurt",
    "I'm not ready yet",
    "It's too hard",
    "Nobody is watching",
  ];

  double _rotation = 0;
  String? _selectedExcuse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    _controller.addListener(() {
      setState(() {
        _rotation = _animation.value * 2 * math.pi * 5; // 5 full rotations + extra
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateResult();
      }
    });
  }

  void _calculateResult() {
    // Determine which excuse the needle is pointing at
    final normalizedRotation = (_rotation % (2 * math.pi)) / (2 * math.pi);
    final index = ((1 - normalizedRotation) * _excuses.length).floor() % _excuses.length;
    setState(() {
      _selectedExcuse = _excuses[index];
    });
    
    // Show a dialog or snackbar with a "tough love" message
    _showToughLove();
  }

  void _showToughLove() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'EXCUSE FOUND',
          style: AppTextStyles.label.copyWith(color: AppColors.danger),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$_selectedExcuse"',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Does this sound like a man who keeps his word? Get back to work.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I UNDERSTAND'),
          ),
        ],
      ),
    );
  }

  void _spinWheel() {
    if (_controller.isAnimating) return;
    setState(() {
      _selectedExcuse = null;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('WHEEL OF EXCUSES'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Spin for an excuse. Then realize how weak it sounds.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 60),
          
          // The Wheel
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel segments
                Transform.rotate(
                  angle: _rotation,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: WheelPainter(excuses: _excuses),
                  ),
                ),
                
                // Center hub
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt, color: AppColors.accent, size: 20),
                  ),
                ),
                
                // The Needle
                Positioned(
                  top: -10,
                  child: Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 40),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80),
          
          ElevatedButton(
            onPressed: _spinWheel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('SPIN THE WHEEL'),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> excuses;
  WheelPainter({required this.excuses});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / excuses.length;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < excuses.length; i++) {
      paint.color = i % 2 == 0 ? AppColors.surface : AppColors.surfaceRaised;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: excuses[i],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * segmentAngle + segmentAngle / 2);
      textPainter.paint(canvas, Offset(radius * 0.4, -textPainter.height / 2));
      canvas.restore();
    }

    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}