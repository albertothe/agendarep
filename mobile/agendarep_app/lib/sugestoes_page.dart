import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'api_service.dart';

class SugestoesPage extends StatefulWidget {
  const SugestoesPage({super.key});

  @override
  State<SugestoesPage> createState() => _SugestoesPageState();
}

class _SugestoesPageState extends State<SugestoesPage> {
  final ApiService api = ApiService();
  String nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final token = await api.getToken();
    if (token != null) {
      final data = Jwt.parseJwt(token);
      setState(() {
        nomeUsuario = data['nome'] ?? 'Usuario';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header padronizado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AgendaRep',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366f1),
                    ),
                  ),
                  PopupMenuButton<String>(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6366f1),
                      child: Text(
                        nomeUsuario.isNotEmpty
                            ? nomeUsuario[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await api.setToken('');
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Sair'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Título e subtítulo padronizados
              const Text(
                'Sugestões de Visita',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Receba sugestões inteligentes de clientes para visitar baseadas no histórico e potencial.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6b7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Conteúdo em desenvolvimento
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            size: 40,
                            color: Color(0xFF6366f1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Em Desenvolvimento',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Esta funcionalidade está sendo desenvolvida e estará disponível em breve.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6b7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Funcionalidades Planejadas:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1f2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFeatureItem(
                                icon: Icons.analytics,
                                title: 'Análise de Padrões',
                                description:
                                    'Identificação de clientes com maior potencial',
                              ),
                              _buildFeatureItem(
                                icon: Icons.schedule,
                                title: 'Otimização de Rotas',
                                description:
                                    'Sugestões de visitas por proximidade',
                              ),
                              _buildFeatureItem(
                                icon: Icons.trending_up,
                                title: 'Priorização Inteligente',
                                description:
                                    'Ranking baseado em histórico de vendas',
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366f1),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
