import 'package:flutter/material.dart';
import '../services/cleaner_service.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import 'dashboard_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final CleanerService _cleanerService = CleanerService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AdService _adService = AdService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // UMP/GDPR já inicializado no main.dart
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _cleanerService.checkPermission();
    if (hasPermission && mounted) {
      _navigateToDashboard();
    }
  }

  Future<void> _requestPermissions() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final granted = await _cleanerService.requestPermission();
    
    if (granted && mounted) {
      _analyticsService.logPermissaoConcedida();
      _navigateToDashboard();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, permita o acesso à galeria'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.cleaning_services,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Column(
                children: [
                  Text(
                    'InstaClean',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PMC',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.photo_library,
                  size: 60,
                  color: Color(0xFF00E676),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Acesso à Galeria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Para encontrar e limpar ficheiros duplicados, o InstaClean PMC precisa de acesso à sua galeria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildPermissionItem(Icons.photo, 'Fotos'),
              _buildPermissionItem(Icons.videocam, 'Vídeos'),
              _buildPermissionItem(Icons.screenshot, 'Screenshots'),
              
              const SizedBox(height: 32),
              
              GestureDetector(
                onTap: _isLoading ? null : _requestPermissions,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading 
                          ? [Colors.grey, Colors.grey.shade600]
                          : [const Color(0xFF00E676), const Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: _isLoading ? [] : [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Permitir Acesso',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
