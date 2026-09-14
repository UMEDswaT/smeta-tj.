import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

const authRedirectUrl = 'tj.smetatj.app://login-callback/';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'SUPABASE_URL ё SUPABASE_KEY ёфт нашуд.',
            ),
          ),
        ),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
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
          seedColor: const Color(0xFF005F4B),
          brightness: Brightness.light,
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginPage();
    }

    return const MainShell();
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

  bool registerMode = false;
  bool loading = false;
  bool hidePassword = true;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      showMessage('Email ва рамзи на камтар аз 6 аломатро ворид кунед.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (registerMode) {
        await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: authRedirectUrl,
        );

        showMessage(
          'Ҳисоб сохта шуд. Email-ро барои тасдиқ санҷед.',
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('Хато: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
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
                maxWidth: 420,
              ),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 72,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'SMETA TJ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Системаи рақамии сохтмон',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Рамз',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: loading ? null : submit,
                          child: loading
                              ? const CircularProgressIndicator()
                              : Text(
                                  registerMode
                                      ? 'Сабти ном'
                                      : 'Ворид шудан',
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            registerMode = !registerMode;
                          });
                        },
                        child: Text(
                          registerMode
                              ? 'Аллакай ҳисоб доред? Ворид шавед'
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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    ProjectsPage(),
    EstimatesPage(),
    StandardsPage(),
    PricesPage(),
  ];

  final titles = const [
    'SMETA TJ',
    'Объектҳо',
    'Смета',
    'Меъёрҳо',
    'Нархҳо',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[index],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Баромад',
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Асосӣ',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Объект',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Смета',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Меъёр',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Нарх',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int projectsCount = 0;
  int estimatesCount = 0;
  int standardsCount = 0;
  int pricesCount = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final projects =
          await supabase.from('projects').select('id');

      final estimates =
          await supabase.from('estimates').select('id');

      final standards =
          await supabase.from('construction_standards').select('id');

      final prices =
          await supabase.from('prices').select('id');

      if (!mounted) return;

      setState(() {
        projectsCount = projects.length;
        estimatesCount = estimates.length;
        standardsCount = standards.length;
        pricesCount = prices.length;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return RefreshIndicator(
      onRefresh: loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SMETA TJ ONLINE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 34),
                  const Text(
                    '«...ба фарзандону набераҳоямон '
                    'як мулки обод мерос гузорем.»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Эмомалӣ Раҳмон',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                StatCard(
                  title: 'Объектҳо',
                  number: projectsCount,
                  icon: Icons.apartment,
                ),
                StatCard(
                  title: 'Сметаҳо',
                  number: estimatesCount,
                  icon: Icons.calculate,
                ),
                StatCard(
                  title: 'Меъёрҳо',
                  number: standardsCount,
                  icon: Icons.menu_book,
                ),
                StatCard(
                  title: 'Нархҳо',
                  number: pricesCount,
                  icon: Icons.payments,
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.verified_outlined,
              ),
              title: Text(
                'Supabase пайваст аст',
              ),
              subtitle: Text(
                'Маълумот онлайн нигоҳ дошта мешавад.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int number;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.number,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              '$number',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Map<String, dynamic>> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final data = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        projects = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage('$e');
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> addProject() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final customer = TextEditingController();
    final contractor = TextEditingController();
    final engineer = TextEditingController();
    final budget = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Объекти нав'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Номи объект *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Суроға',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: customer,
                  decoration: const InputDecoration(
                    labelText: 'Фармоишгар',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contractor,
                  decoration: const InputDecoration(
                    labelText: 'Пудратчӣ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: engineer,
                  decoration: const InputDecoration(
                    labelText: 'Муҳандис',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budget,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Буҷет, сомонӣ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Бекор'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Сабт'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    if (name.text.trim().isEmpty) {
      showMessage('Номи объект ҳатмист.');
      return;
    }

    try {
      await supabase.from('projects').insert({
        'user_id': supabase.auth.currentUser!.id,
        'name': name.text.trim(),
        'address': address.text.trim(),
        'customer': customer.text.trim(),
        'contractor': contractor.text.trim(),
        'engineer': engineer.text.trim(),
        'budget': double.tryParse(
              budget.text.replaceAll(',', '.'),
            ) ??
            0,
      });

      showMessage('Объект сабт шуд.');
      await loadProjects();
    } catch (e) {
      showMessage('Хато: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await supabase
          .from('projects')
          .delete()
          .eq('id', id);

      showMessage('Объект нест карда шуд.');
      await loadProjects();
    } catch (e) {
      showMessage('Хато: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addProject,
        icon: const Icon(Icons.add),
        label: const Text('Объекти нав'),
      ),
      body: RefreshIndicator(
        onRefresh: l