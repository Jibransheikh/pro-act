import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PenaltyWheelScreen extends StatefulWidget {
  const PenaltyWheelScreen({super.key});

  @override
  State<PenaltyWheelScreen> createState() => _PenaltyWheelScreenState();
}

class _PenaltyWheelScreenState extends State<PenaltyWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  final List<String> _penalties = [
    "50 Burpees",
    "Cold Shower",
    "100 Pushups",
    "No Phone 2h",
    "5 Mile Run",
    "Read 50 Pages",
    "Plank 5 Mins",
    "No Carbs Today",
  ];

  double _rotation = 0;
  String? _selectedPenalty;

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
        _rotation = _animation.value * 2 * math.pi * 5;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateResult();
      }
    });
  }

  void _calculateResult() {
    final normalizedRotation = (_rotation % (2 * math.pi)) / (2 * math.pi);
    final index = ((1 - normalizedRotation) * _penalties.length).floor() % _penalties.length;
    setState(() {
      _selectedPenalty = _penalties[index];
    });
    
    _showPenaltyDialog();
  }

  void _showPenaltyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'PAY THE PRICE',
          style: AppTextStyles.label.copyWith(color: AppColors.danger),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedPenalty!.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'You failed your vow. This is the only way back to honor. Do it now.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I WILL PAY'),
          ),
        ],
      ),
    );
  }

  void _spinWheel() {
    if (_controller.isAnimating) return;
    setState(() {
      _selectedPenalty = null;
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
        title: const Text('WHEEL OF DISCOMFORT'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'A vow broken is a debt owed. Spin for your penalty.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 60),
          
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _rotation,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: PenaltyWheelPainter(penalties: _penalties),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.danger, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.warning, color: AppColors.danger, size: 20),
                  ),
                ),
                Positioned(
                  top: -10,
                  child: Icon(Icons.arrow_drop_down, color: AppColors.danger, size: 40),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80),
          
          ElevatedButton(
            onPressed: _spinWheel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('PAY THE DEBT'),
          ),
        ],
      ),
    );
  }
}

class PenaltyWheelPainter extends CustomPainter {
  final List<String> penalties;
  PenaltyWheelPainter({required this.penalties});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / penalties.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < penalties.length; i++) {
      paint.color = i % 2 == 0 ? AppColors.surface : AppColors.surfaceRaised;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle,
        segmentAngle,
        true,
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: penalties[i].toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * segmentAngle + segmentAngle / 2);
      textPainter.paint(canvas, Offset(radius * 0.35, -textPainter.height / 2));
      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = AppColors.danger.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}