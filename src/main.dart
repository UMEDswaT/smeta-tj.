import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

SupabaseClient get supabase => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );

    runApp(const SmetaTJApp());
  } catch (e) {
    runApp(
      ConfigErrorApp(
        message: 'Пайвастшавӣ ба Supabase иҷро нашуд.\n$e',
      ),
    );
  }
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({
    super.key,
    this.message =
        'SUPABASE_URL ё SUPABASE_KEY ба барнома дода нашудааст.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SMETA TJ',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
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
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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
        final session = supabase.auth.currentSession;

        if (session == null) {
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
      showMessage(
        'Рамз бояд на кам аз 6 аломат бошад.',
      );
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
                        size: 72,
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
                      const Text(
                        'Online',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        register
                            ? 'Сабти номи корбар'
                            : 'Ворид шудан',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Рамз',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                          ),
                        ),
                        onSubmitted: (_) {
                          if (!loading) {
                            submit();
                          }
                        },
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
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                setState(() {
                                  register =
                                      !register;
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool checking = true;
  bool online = false;
  String statusText = 'Санҷиши сервер...';

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  Future<void> checkConnection() async {
    try {
      await supabase.auth.getUser();

      if (!mounted) return;

      setState(() {
        checking = false;
        online = true;
        statusText = 'Supabase пайваст аст';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        checking = false;
        online = false;
        statusText =
            'Пайвастшавӣ ба сервер санҷида нашуд';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMETA TJ'),
        actions: [
          IconButton(
            tooltip: 'Навсозӣ',
            onPressed: () {
              setState(() {
                checking = true;
                statusText =
                    'Санҷиши сервер...';
              });
              checkConnection();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Баромадан',
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: checkConnection,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  children: [
                    checking
                        ? const SizedBox(
                            width: 70,
                            height: 70,
                            child:
                                CircularProgressIndicator(),
                          )
                        : Icon(
                            online
                                ? Icons
                                    .cloud_done_outlined
                                : Icons
                                    .cloud_off_outlined,
                            size: 80,
                          ),
                    const SizedBox(height: 20),
                    const Text(
                      'SMETA TJ ONLINE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Корбар',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? '—',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.calculate_outlined,
                ),
                title: Text('Смета'),
                subtitle: Text(
                  'Модули ҳисобкунии смета дар марҳилаи навбатӣ пайваст мешавад.',
                ),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.price_check_outlined,
                ),
                title: Text('Нархҳо'),
                subtitle: Text(
                  'Базаи нархҳои онлайн ба Supabase пайваст карда мешавад.',
                ),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.storefront_outlined,
                ),
                title: Text('Маркет'),
                subtitle: Text(
                  'Фурӯшандагон ва маҳсулот дар марҳилаи навбатӣ.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
