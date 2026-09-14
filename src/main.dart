import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
const redirectUrl = 'tj.smetatj.app://login-callback/';

SupabaseClient get sb => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

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
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

void msg(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: sb.auth.onAuthStateChange,
      builder: (context, snapshot) {
        return sb.auth.currentSession == null
            ? const LoginPage()
            : const HomePage();
      },
    );
  }
}

// ================= LOGIN =================

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
      msg(context, 'Email ва рамзи на камтар аз 6 аломатро ворид кунед.');
      return;
    }

    setState(() => loading = true);

    try {
      if (register) {
        await sb.auth.signUp(
          email: e,
          password: p,
          emailRedirectTo: redirectUrl,
        );

        if (mounted) {
          msg(context, 'Email-ро барои тасдиқ санҷед.');
        }
      } else {
        await sb.auth.signInWithPassword(
          email: e,
          password: p,
        );
      }
    } on AuthException catch (e) {
      if (mounted) msg(context, e.message);
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 70,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SMETA TJ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Системаи рақамии сохтмони Тоҷикистон',
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Рамз',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(
                            register ? 'Сабти ном' : 'Ворид шудан',
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
    );
  }
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              await sb.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Асосӣ',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment),
            label: 'Объект',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate),
            label: 'Смета',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Меъёр',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments),
            label: 'Нарх',
          ),
        ],
      ),
    );
  }
}

// ================= DASHBOARD =================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int projects = 0;
  int estimates = 0;
  int standards = 0;
  int prices = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final a = await sb.from('projects').select('id');
      final b = await sb.from('estimates').select('id');
      final c = await sb.from('construction_standards').select('id');
      final d = await sb.from('prices').select('id');

      if (!mounted) return;

      setState(() {
        projects = a.length;
        estimates = b.length;
        standards = c.length;
        prices = d.length;
      });
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_done,
                    size: 55,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'SMETA TJ ONLINE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                  ),
                  Divider(height: 30),
                  Text(
                    '«...ба фарзандону набераҳоямон '
                    'як мулки обод мерос гузорем.»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Эмомалӣ Раҳмон',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          stat('Объектҳо', projects, Icons.apartment),
          stat('Сметаҳо', estimates, Icons.calculate),
          stat('Меъёрҳо', standards, Icons.menu_book),
          stat('Нархҳо', prices, Icons.payments),
        ],
      ),
    );
  }

  Widget stat(String title, int count, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          '$count',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ================= PROJECTS =================

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await sb
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final budget = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Объекти нав'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Номи объект',
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
              controller: budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Буҷет, сомонӣ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бекор'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сабт'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await sb.from('projects').insert({
        'user_id': sb.auth.currentUser!.id,
        'name': name.text.trim(),
        'address': address.text.trim(),
        'budget': double.tryParse(budget.text.trim()) ?? 0,
        'status': 'active',
      });

      await load();

      if (mounted) msg(context, 'Объект сабт шуд.');
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: rows.isEmpty
            ? empty('Ҳоло объект нест')
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final item = rows[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.apartment),
                      title: Text(
                        item['name']?.toString() ?? '',
                      ),
                      subtitle: Text(
                        '${item['address'] ?? '-'}\n'
                        '${item['budget'] ?? 0} сомонӣ',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ================= ESTIMATES =================

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  List<Map<String, dynamic>> estimates = [];
  List<Map<String, dynamic>> projects = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await sb.from('projects').select();
      final e = await sb
          .from('estimates')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        projects = List<Map<String, dynamic>>.from(p);
        estimates = List<Map<String, dynamic>>.from(e);
      });
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }
  }

  String projectName(String id) {
    for (final p in projects) {
      if (p['id'].toString() == id) {
        return p['name']?.toString() ?? '';
      }
    }
    return '';
  }

  Future<void> add() async {
    if (projects.isEmpty) {
      msg(context, 'Аввал объект созед.');
      return;
    }

    final title = TextEditingController();
    String projectId = projects.first['id'].toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Сметаи нав'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: projectId,
                decoration: const InputDecoration(
                  labelText: 'Объект',
                ),
                items: projects.map((p) {
                  return DropdownMenuItem(
                    value: p['id'].toString(),
                    child: Text(
                      p['name']?.toString() ?? '',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => projectId = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Номи смета',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Бекор'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сабт'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await sb.from('estimates').insert({
        'user_id': sb.auth.currentUser!.id,
        'project_id': projectId,
        'title': title.text.trim(),
        'estimate_type': 'local',
        'status': 'draft',
      });

      await load();

      if (mounted) msg(context, 'Смета сохта шуд.');
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: estimates.isEmpty
            ? empty('Ҳоло смета нест')
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: estimates.length,
                itemBuilder: (context, i) {
                  final item = estimates[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.calculate),
                      title: Text(
                        item['title']?.toString() ?? '',
                      ),
                      subtitle: Text(
                        'Объект: '
                        '${projectName(item['project_id'].toString())}\n'
                        'Ҷамъ: ${item['total'] ?? 0} сомонӣ',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ================= STANDARDS =================

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await sb
          .from('construction_standards')
          .select()
          .order('code');

      if (!mounted) return;

      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) msg(context, 'Хато: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: rows.isEmpty
          ? empty('Базаи меъёрҳо ҳоло холӣ аст')
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final item = rows[i];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(
                      item['title']?.toString() ?? '',
                    ),
                    subtitle: Text(
                      '${item['code'] ?? '-'} | '
                      '${item['edition_year'] ?? '-'}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ================= PRICES =================

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await sb
          .from('prices')
          .select()
          .order('name');

      if (!mounted) return;

      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        msg(context, 'Хато: $e');
      }
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final unit = TextEditingController();
    final price = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Нархи нав'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Ном',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: unit,
                decoration: const InputDecoration(
                  labelText: 'Воҳид',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Нарх, сомонӣ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Бекор'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Сабт'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      name.dispose();
      unit.dispose();
      price.dispose();
      return;
    }

    final itemName = name.text.trim();
    final itemUnit = unit.text.trim();
    final itemPrice = double.tryParse(
          price.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    name.dispose();
    unit.dispose();
    price.dispose();

    if (itemName.isEmpty || itemUnit.isEmpty) {
      if (mounted) {
        msg(context, 'Ном ва воҳид ҳатмист.');
      }
      return;
    }

    try {
      await sb.from('prices').insert({
        'owner_user_id': sb.auth.currentUser!.id,
        'category': 'material',
        'name': itemName,
        'unit': itemUnit,
        'price': itemPrice,
        'currency': 'TJS',
        'region': 'Tajikistan',
        'is_official': false,
      });

      await load();

      if (mounted) {
        msg(context, 'Нарх сабт шуд.');
      }
    } catch (e) {
      if (mounted) {
        msg(context, 'Хато: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: rows.isEmpty
            ? empty('Ҳоло нарх нест')
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final item = rows[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text(
                        item['name']?.toString() ?? '',
                      ),
                      subtitle: Text(
                        'Воҳид: ${item['unit'] ?? '-'}',
                      ),
                      trailing: Text(
                        '${item['price'] ?? 0} '
                        '${item['currency'] ?? 'TJS'}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ================= EMPTY =================

Widget empty(String text) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 130),
      const Icon(
        Icons.inbox_outlined,
        size: 70,
      ),
      const SizedBox(height: 15),
      Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}