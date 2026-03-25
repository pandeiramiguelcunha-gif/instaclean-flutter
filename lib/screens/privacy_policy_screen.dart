import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Politica de Privacidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.shield, color: Color(0xFF00E676), size: 48),
                  SizedBox(height: 12),
                  Text(
                    'InstaClean PMC',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A sua privacidade e importante para nos',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSection(
              'Recolha de Dados',
              Icons.storage,
              'O InstaClean PMC solicita acesso ao armazenamento do dispositivo exclusivamente para realizar a limpeza de ficheiros duplicados ou desnecessarios, por escolha do utilizador. Nao recolhemos nomes, contactos, enderecos de email ou quaisquer outros dados pessoais.',
            ),

            _buildSection(
              'Processamento Local',
              Icons.phone_android,
              'Todo o processamento de imagem, analise de duplicados e comparacao de ficheiros e realizado localmente no seu telemovel. As suas fotos, videos e ficheiros nunca saem do seu dispositivo e nunca sao enviados para servidores externos.',
            ),

            _buildSection(
              'Publicidade (AdMob)',
              Icons.ads_click,
              'Utilizamos o Google AdMob para exibir anuncios na aplicacao. Em conformidade com o Regulamento Geral de Protecao de Dados (RGPD), solicitamos o seu consentimento antes de utilizar dados de rastreio (ID de publicidade) para personalizar anuncios. Pode alterar as suas preferencias a qualquer momento.',
            ),

            _buildSection(
              'Transparencia',
              Icons.visibility,
              'Nenhum ficheiro do utilizador e enviado para servidores externos ou partilhado com terceiros. A unica comunicacao de rede que o app realiza e para carregar anuncios do Google AdMob e enviar dados anonimos de utilizacao ao Firebase Analytics.',
            ),

            _buildSection(
              'Firebase Analytics',
              Icons.analytics,
              'Utilizamos o Firebase Analytics para recolher dados anonimos de utilizacao, como numero de scans realizados e ficheiros eliminados. Estes dados ajudam-nos a melhorar a experiencia da aplicacao e nao contem informacoes pessoais identificaveis.',
            ),

            _buildSection(
              'Direitos do Utilizador',
              Icons.gavel,
              'O utilizador pode:\n\n- Revogar as permissoes de acesso aos ficheiros a qualquer momento nas definicoes do sistema Android.\n\n- Recusar o consentimento para anuncios personalizados atraves do formulario RGPD apresentado no inicio da aplicacao.\n\n- Desinstalar a aplicacao a qualquer momento, removendo todos os dados associados.',
            ),

            _buildSection(
              'Alteracoes a Politica',
              Icons.update,
              'Reservamo-nos o direito de atualizar esta politica de privacidade. Quaisquer alteracoes serao refletidas nesta pagina dentro da aplicacao.',
            ),

            const SizedBox(height: 16),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'InstaClean PMC v1.0.0',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contacto: pandeiramiguelcunha@gmail.com',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection(String title, IconData icon, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00BCD4), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
