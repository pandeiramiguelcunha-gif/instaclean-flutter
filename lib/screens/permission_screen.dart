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
  bool _isChecking = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _permissionService.checkPermissions();
    
    if (hasPermissions) {
      _navigateToDashboard();
    } else {
      setState(() {
        _isChecking = false;
        _hasPermissions = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isChecking = true);
    
    final granted = await _permissionService.requestAllPermissions(context);
    
    if (granted) {
      _navigateToDashboard();
    } else {
      setState(() {
        _isChecking = false;
        _hasPermissions = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissões necessárias para continuar'),
            backgroundColor: Colors.red,
          ),
        );
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
              
              if (_isChecking) ...[
                const CircularProgressIndicator(
                  color: Color(0xFF00E676),
                ),
                const SizedBox(height: 24),
                const Text(
                  'A verificar permissões...',
                  style: TextStyle(color: Colors.white70),
                ),
              ] else ...[
                // Ícone de permissão
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
                _buildPermissionItem(Icons.contacts, 'Contactos'),
                
                const SizedBox(height: 32),
                
                // Botão de permitir
                GestureDetector(
                  onTap: _requestPermissions,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
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
