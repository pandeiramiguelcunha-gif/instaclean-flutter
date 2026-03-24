import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'results_screen.dart';
import '../services/file_scanner_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final FileScannerService _scannerService = FileScannerService();
  
  double usedStorage = 0;
  double totalStorage = 0;
  double usedGB = 0;
  bool isAnalyzing = false;
  String scanStatus = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      // Obter informações de armazenamento
      final stat = await Directory('/storage/emulated/0').stat();
      
      // Estimar espaço usado (simplificado)
      // Em produção, usar um plugin como disk_space
      totalStorage = 128.0; // Valor exemplo
      usedGB = 86.4; // Valor exemplo
      usedStorage = (usedGB / totalStorage) * 100;
      
      _animation = Tween<double>(begin: 0, end: usedStorage / 100)
          .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward();
      
      setState(() {});
    } catch (e) {
      // Usar valores padrão
      totalStorage = 128.0;
      usedGB = 86.4;
      usedStorage = 67.5;
      
      _animation = Tween<double>(begin: 0, end: usedStorage / 100)
          .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward();
      
      setState(() {});
    }
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

    try {
      // Escanear ficheiros reais
      final results = await _scannerService.scanAllFiles(
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              scanStatus = status;
            });
          }
        },
      );

      // Encontrar duplicados para cada categoria
      Map<FileType, List<List<FileItem>>> duplicates = {};
      
      for (var type in [FileType.photo, FileType.screenshot, FileType.video, FileType.music]) {
        setState(() {
          scanStatus = 'A procurar duplicados em ${_getTypeName(type)}...';
        });
        
        final files = results[type] ?? [];
        if (files.isNotEmpty) {
          duplicates[type] = await _scannerService.findDuplicates(files);
        } else {
          duplicates[type] = [];
        }
      }

      if (mounted) {
        setState(() {
          isAnalyzing = false;
          scanStatus = '';
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              scannedFiles: results,
              duplicates: duplicates,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          scanStatus = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao analisar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTypeName(FileType type) {
    switch (type) {
      case FileType.photo: return 'Fotos';
      case FileType.screenshot: return 'Screenshots';
      case FileType.video: return 'Vídeos';
      case FileType.music: return 'Músicas';
      case FileType.contact: return 'Contactos';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Definições'),
                  backgroundColor: Color(0xFF2D2D2D),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Gauge circular de progresso
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
                              Text(
                                'A analisar...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
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
              
              // Botão Analisar Agora
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
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isAnalyzing
                        ? []
                        : [
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

// Painter para o gauge circular
class StorageGaugePainter extends CustomPainter {
  final double progress;
  final bool isAnalyzing;

  StorageGaugePainter({required this.progress, this.isAnalyzing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Fundo do arco
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

    // Gradiente do progresso
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: math.pi * 0.75,
        colors: [
          Color(0xFF00E676),
          Color(0xFF00BCD4),
          Color(0xFF2196F3),
        ],
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

    // Círculo de fundo interno
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
