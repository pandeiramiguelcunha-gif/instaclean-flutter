import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InstaClean'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bem-vindo ao InstaClean',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O que deseja fazer hoje?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildServiceCard(
                context,
                icon: Icons.cleaning_services,
                title: 'Agendar Limpeza',
                subtitle: 'Marque um serviço de limpeza',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildServiceCard(
                context,
                icon: Icons.history,
                title: 'Histórico',
                subtitle: 'Veja os seus agendamentos',
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildServiceCard(
                context,
                icon: Icons.person,
                title: 'Minha Conta',
                subtitle: 'Gerir perfil e definições',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildServiceCard(
                context,
                icon: Icons.support_agent,
                title: 'Suporte',
                subtitle: 'Precisa de ajuda?',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendar nova limpeza')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Limpeza'),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title - Em desenvolvimento')),
          );
        },
      ),
    );
  }
}
