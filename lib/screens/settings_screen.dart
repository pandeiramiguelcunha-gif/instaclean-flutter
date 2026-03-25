import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String privacyPolicyUrl =
      'https://pandeiramiguelcunha-gif.github.io/instaclean-flutter/privacy-policy.html';

  void _resetConsent(BuildContext context) {
    ConsentInformation.instance.reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consentimento reiniciado. Reinicie o app para ver o formulario novamente.'),
        backgroundColor: Color(0xFF2D2D2D),
      ),
    );
  }

  Future<void> _openPrivacyOnline() async {
    final uri = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Definicoes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cleaning_services, color: Color(0xFF00E676), size: 40),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'InstaClean PMC',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Versao 1.0.0',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSettingsTile(
              icon: Icons.shield,
              title: 'Politica de Privacidade',
              subtitle: 'RGPD e protecao dos seus dados',
              color: const Color(0xFF00E676),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.open_in_new,
              title: 'Privacidade Online',
              subtitle: 'Abrir politica no navegador',
              color: const Color(0xFF7C4DFF),
              onTap: _openPrivacyOnline,
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.ads_click,
              title: 'Consentimento de Anuncios',
              subtitle: 'Alterar preferencias de publicidade',
              color: const Color(0xFF00BCD4),
              onTap: () => _resetConsent(context),
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.folder_open,
              title: 'Permissoes',
              subtitle: 'Gerir acesso ao armazenamento',
              color: const Color(0xFF2196F3),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pode gerir as permissoes nas Definicoes do Android -> Apps -> InstaClean PMC'),
                    backgroundColor: Color(0xFF2D2D2D),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
            ),

            const Spacer(),

            Text(
              'Feito com dedicacao em Portugal',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'com.instaclean.pmc',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
