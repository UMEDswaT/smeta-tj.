import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

SupabaseClient get supabase => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const SmetaTJApp());
}

class SmetaTJApp extends StatelessWidget {
  const SmetaTJApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMETA TJ',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123A73),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession == null) {
          return const LoginPage();
        }

        return const HomePage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool register = false;
  bool loading = false;

  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMessage('Email-ро ворид кунед.');
      return;
    }

    if (password.length < 6) {
      showMessage('Рамз бояд на кам аз 6 аломат бошад.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (register) {
        final result = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (result.session == null) {
          showMessage(
            'Сабти ном анҷом ёфт. Email-ро барои тасдиқ санҷед.',
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        showMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'Пайвастшавӣ ба сервер нашуд.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.engineering,
                        size: 70,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SMETA TJ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        register
                            ? 'Сабти номи корбар'
                            : 'Ворид шудан',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Рамз',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed:
                            loading ? null : submit,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(14),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  register
                                      ? 'Сабти ном'
                                      : 'Ворид шудан',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                setState(() {
                                  register = !register;
                                });
                              },
                        child: Text(
                          register
                              ? 'Ҳисоб доред? Ворид шавед'
                              : 'Ҳисоб надоред? Сабти ном',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMETA TJ'),
        actions: [
          IconButton(
            tooltip: 'Баромадан',
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 80,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SMETA TJ ONLINE',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Supabase пайваст аст',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? '',
                    textAlign: TextAlign.center,
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
