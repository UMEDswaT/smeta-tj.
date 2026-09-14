import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
const redirectUrl = 'tj.smetatj.app://login-callback/';

SupabaseClient get db => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          seedColor: const Color(0xFF006B55),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
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
  late final Stream<AuthState> authStream;

  @override
  void initState() {
    super.initState();
    authStream = db.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authStream,
      builder: (context, snapshot) {
        if (db.auth.currentSession == null) {
          return const LoginPage();
        }

        return const MainPage();
      },
    );
  }
}

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

// =====================================================
// LOGIN
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool register = false;
  bool loading = false;
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final e = email.text.trim();
    final p = password.text.trim();

    if (e.isEmpty || p.length < 6) {
      message(
        context,
        'Email ва рамзи на камтар аз 6 аломатро ворид кунед.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (register) {
        await db.auth.signUp(
          email: e,
          password: p,
          emailRedirectTo: redirectUrl,
        );

        if (mounted) {
          message(
            context,
            'Ҳисоб сохта шуд. Email-ро тасдиқ кунед.',
          );
        }
      } else {
        await db.auth.signInWithPassword(
          email: e,
          password: p,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        message(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        message(context, 'Хато: $error');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SMETA TJ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Системаи рақамии сохтмони Тоҷикистон',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: hidden,
                        decoration: InputDecoration(
                          labelText: 'Рамз',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => hidden = !hidden);
                            },
                            icon: Icon(
                              hidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: loading ? null : submit,
                          child: loading
                              ? const CircularProgressIndicator()
                              : Text(
                                  register
                                      ? 'Сабти ном'
                                      : 'Ворид шудан',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => register = !register);
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

// =====================================================
// MAIN PAGE
// =====================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
    'Сметаҳо',
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
            onPressed: () async {
              await db.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
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

// =====================================================
// DASHBOARD
// =====================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int projectCount = 0;
  int estimateCount = 0;
  int standardCount = 0;
  int priceCount = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final projects = await db.from('projects').select('id');
      final estimates = await db.from('estimates').select('id');
      final standards =
          await db.from('construction_standards').select('id');
      final prices = await db.from('prices').select('id');

      if (!mounted) return;

      setState(() {
        projectCount = projects.length;
        estimateCount = estimates.length;
        standardCount = standards.length;
        priceCount = prices.length;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);
      message(context, 'Хато: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    '«...ба фарзандону набераҳоямон '
                    'як мулки обод мерос гузорем.»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Эмомалӣ Раҳмон',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    db.auth.currentUser?.email ?? '',
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Объектҳо',
                  value: projectCount,
                  icon: Icons.apartment,
                ),
                StatCard(
                  title: 'Сметаҳо',
                  value: estimateCount,
                  icon: Icons.calculate,
                ),
                StatCard(
                  title: 'Меъёрҳо',
                  value: standardCount,
                  icon: Icons.menu_book,
                ),
                StatCard(
                  title: 'Нархҳо',
                  value: priceCount,
                  icon: Icons.payments,
                ),
              ],
            ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('Supabase пайваст аст'),
              subtitle: Text(
                'Маълумоти шумо онлайн нигоҳ дошта мешавад.',
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
  final int value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}

// =====================================================
// PROJECTS
// =====================================================

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await db
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        rows = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);
      message(context, 'Хато: $error');
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final customer = TextEditingController();
    final contractor = TextEditingController();
    final engineer = TextEditingController();
    final budget = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Объекти нав'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(name, 'Номи объект *'),
                gap(),
                field(address, 'Суроға'),
                gap(),
                field(customer, 'Фармоишгар'),
                gap(),
                field(contractor, 'Пудратчӣ'),
                gap(),
                field(engineer, 'Муҳандис'),
                gap(),
                TextField(
                  controller: budget,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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

    if (ok != true) {
      disposeControllers([
        name,
        address,
        customer,
        contractor,
        engineer,
        budget,
      ]);
      return;
    }

    final projectName = name.text.trim();
    final projectAddress = address.text.trim();
    final projectCustomer = customer.text.trim();
    final projectContractor = contractor.text.trim();
    final projectEngineer = engineer.text.trim();

    final projectBudget = double.tryParse(
          budget.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    disposeControllers([
      name,
      address,
      customer,
      contractor,
      engineer,
      budget,
    ]);

    if (projectName.isEmpty) {
      if (mounted) {
        message(context, 'Номи объект ҳатмист.');
      }
      return;
    }

    try {
      await db.from('projects').insert({
        'user_id': db.auth.currentUser!.id,
        'name': projectName,
        'address': projectAddress,
        'customer': projectCustomer,
        'contractor': projectContractor,
        'engineer': projectEngineer,
        'budget': projectBudget,
        'status': 'active',
      });

      await load();

      if (mounted) {
        message(context, 'Объект сабт шуд.');
      }
    } catch (error) {
      if (mounted) {
        message(context, 'Хато: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('Объекти нав'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: rows.isEmpty
                  ? const EmptyView(
                      icon: Icons.apartment_outlined,
                      title: 'Ҳоло объект нест',
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        90,
                      ),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final item = rows[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.apartment),
                 