import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _lembrarUsuario = false;
  String? erro;
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    _carregarUsuarioSalvo();
  }

  Future<void> _carregarUsuarioSalvo() async {
    final salvo = await api.getSavedUser();
    if (salvo != null) {
      setState(() {
        _loginController.text = salvo;
        _lembrarUsuario = true;
      });
    }
  }

  Future<void> _fazerLogin() async {
    final res = await api.post('/auth/login', {
      'login': _loginController.text,
      'senha': _senhaController.text,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await api.setToken(data['token']);
      if (_lembrarUsuario) {
        await api.setSavedUser(_loginController.text);
      } else {
        await api.removeSavedUser();
      }
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() {
        erro = 'Usuário ou senha inválidos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 80, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                "AgendaRep",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _lembrarUsuario,
                          onChanged: (v) {
                            setState(() {
                              _lembrarUsuario = v ?? false;
                            });
                          },
                        ),
                        const Text('Lembrar usuário'),
                      ],
                    ),
                    if (erro != null) ...[
                      const SizedBox(height: 12),
                      Text(erro!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Entrar",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
