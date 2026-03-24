import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final CleanerService _cleanerService = CleanerService();
  final AdService _adService = AdService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  double usedStorage = 67.5;
  double totalStorage = 128.0;
  double usedGB = 86.4;
  bool isAnalyzing = false;
  String scanStatus = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: usedStorage / 100)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    
    // Carregar anúncio intersticial
    _adService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startAnalysis() async {
    setState(() {
      isAnalyzing = true;
      scanStatus = 'A iniciar análise...';
    });

    _analyticsService.logScanIniciado();

    await _cleanerService.scanAllMedia(
      onProgress: (status, progress) {
        if (mounted) {
          setState(() {
            scanStatus = status;
          });
        }
      },
    );

    if (mounted) {
      // Registar scan concluído
      int totalFiles = 0;
      _cleanerService.allMedia.forEach((k, v) => totalFiles += v.length);
      _analyticsService.logScanConcluido(
        totalFicheiros: totalFiles,
        duplicadosEncontrados: _cleanerService.totalDuplicatesCount,
      );

      setState(() {
        isAnalyzing = false;
        scanStatus = '';
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ResultsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'InstaClean',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'PMC',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Gauge circular
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(250, 250),
                    painter: StorageGaugePainter(
                      progress: _animation.value,
                      isAnalyzing: isAnalyzing,
                    ),
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAnalyzing) ...[
                              const CircularProgressIndicator(
                                color: Color(0xFF00E676),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A analisar...',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ] else ...[
                              Text(
                                '${usedStorage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${usedGB.toStringAsFixed(1)} GB de ${totalStorage.toStringAsFixed(0)} GB',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Text(
                isAnalyzing ? scanStatus : 'Espaço Utilizado',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Botão Analisar
              GestureDetector(
                onTap: isAnalyzing ? null : _startAnalysis,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAnalyzing
                          ? [Colors.grey.shade700, Colors.grey.shade600]
                          : [const Color(0xFF00E676), const Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isAnalyzing ? [] : [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isAnalyzing
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'A Analisar...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Analisar Agora',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class StorageGaugePainter extends CustomPainter {
  final double progress;
  final bool isAnalyzing;

  StorageGaugePainter({required this.progress, this.isAnalyzing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: math.pi * 0.75,
        colors: [Color(0xFF00E676), Color(0xFF00BCD4), Color(0xFF2196F3)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );

    final innerCirclePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 30, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant StorageGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isAnalyzing != isAnalyzing;
  }
}
