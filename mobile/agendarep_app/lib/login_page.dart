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
      appBar: AppBar(
        title: const Text('AgendaRep'),
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
                  CheckboxListTile(
                    title: const Text('Lembrar usuário'),
                    value: _lembrarUsuario,
                    onChanged: (v) {
                      setState(() {
                        _lembrarUsuario = v ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
