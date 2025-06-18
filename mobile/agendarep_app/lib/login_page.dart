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
  String? erro;
  final ApiService api = ApiService();

  Future<void> _fazerLogin() async {
    final res = await api.post('/auth/login', {
      'login': _loginController.text,
      'senha': _senhaController.text,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await api.setToken(data['token']);
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/agenda');
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
      appBar: AppBar(
        title: const Text('AgendaRep - Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _loginController,
                    decoration: const InputDecoration(labelText: 'Usuário'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fazerLogin,
                      child: const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
