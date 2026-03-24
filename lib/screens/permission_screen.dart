import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import 'dashboard_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    try {
      final hasPermissions = await _permissionService.checkPermissions();
      if (hasPermissions && mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final granted = await _permissionService.requestAllPermissions(context);
      
      if (granted && mounted) {
        _navigateToDashboard();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, permita o acesso aos ficheiros para continuar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao pedir permissões: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              
              // Título
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
              
              // Ícone de pasta
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.folder_open,
                  size: 60,
                  color: Color(0xFF00E676),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Permissões Necessárias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Para analisar e limpar ficheiros duplicados, o InstaClean PMC precisa de acesso aos seus ficheiros.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Lista de permissões
              _buildPermissionItem(Icons.photo_library, 'Fotos e Imagens'),
              _buildPermissionItem(Icons.videocam, 'Vídeos'),
              _buildPermissionItem(Icons.music_note, 'Músicas'),
              
              const SizedBox(height: 32),
              
              // Botão de permitir
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
              
              const SizedBox(height: 16),
              
              // Botão para pular (desenvolvimento)
              TextButton(
                onPressed: _navigateToDashboard,
                child: Text(
                  'Continuar sem permissões (modo demo)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.check_circle,
            color: Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}
