// SMETA TJ v1.0 FINAL
// src/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
const primary = Color(0xFF006B55);

SupabaseClient get db => Supabase.instance.client;
String get uid => db.auth.currentUser?.id ?? '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const SmetaApp());
}

double n(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}'.replaceAll(',', '.')) ?? 0;
}

String money(dynamic value) => n(value).toStringAsFixed(2);

void note(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Widget fld(
  TextEditingController controller,
  String label, {
  bool number = false,
  int lines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: lines,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(labelText: label),
  );
}

// ============================================================
// APP
// ============================================================

class SmetaApp extends StatelessWidget {
  const SmetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMETA TJ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// AUTH
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (db.auth.currentSession == null) {
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
  final email = TextEditingController();
  final password = TextEditingController();

  bool signup = false;
  bool busy = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      note(context, 'Email ва рамзи на кам аз 6 аломат ворид кунед.');
      return;
    }

    setState(() => busy = true);

    try {
      if (signup) {
        await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: 'tj.smetatj.app://login-callback/',
        );

        if (mounted) {
          note(context, 'Барои тасдиқи ҳисоб Email-ро санҷед.');
        }
      } else {
        await db.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) note(context, e.message);
    } catch (e) {
      if (mounted) note(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const Icon(
                  Icons.architecture,
                  size: 80,
                  color: primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'SMETA TJ',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Смета • Меъёр • Назорати сохтмон',
                ),
                const SizedBox(height: 28),
                fld(email, 'Email'),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Рамз',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      signup ? 'Сабти ном' : 'Ворид шудан',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => signup = !signup);
                        },
                  child: Text(
                    signup ? 'Ҳисоб дорам' : 'Ҳисоби нав',
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

// ============================================================
// HOME — 1–10
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;
  int refreshKey = 0;

  static const titles = [
    'Асосӣ',
    'Объектҳо',
    'Сметаҳо',
    'Меъёрҳо',
    'Нархҳо',
    'Ҳуҷҷатҳо',
    'Назорати техникӣ',
    'Online / Sync',
    'Marketplace',
    'AI SMETA TJ',
  ];

  List<Widget> get pages => [
        Dashboard(key: ValueKey('dashboard-$refreshKey')),
        Projects(key: ValueKey('projects-$refreshKey')),
        Estimates(key: ValueKey('estimates-$refreshKey')),
        Standards(key: ValueKey('standards-$refreshKey')),
        Prices(key: ValueKey('prices-$refreshKey')),
        Documents(key: ValueKey('documents-$refreshKey')),
        Technical(key: ValueKey('technical-$refreshKey')),
        SyncPage(key: ValueKey('sync-$refreshKey')),
        Market(key: ValueKey('market-$refreshKey')),
        AiPage(key: ValueKey('ai-$refreshKey')),
      ];

  IconData iconFor(int i) {
    return [
      Icons.dashboard,
      Icons.apartment,
      Icons.calculate,
      Icons.menu_book,
      Icons.payments,
      Icons.description,
      Icons.fact_check,
      Icons.cloud_sync,
      Icons.storefront,
      Icons.auto_awesome,
    ][i];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[page],
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Навсозӣ',
            onPressed: () {
              setState(() => refreshKey++);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Баромадан',
            onPressed: () => db.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'SMETA TJ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
              ),
              for (int i = 0; i < titles.length; i++)
                ListTile(
                  leading: Icon(iconFor(i)),
                  selected: page == i,
                  title: Text('${i + 1}. ${titles[i]}'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => page = i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: page,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page < 5 ? page : 0,
        onDestinationSelected: (index) {
          setState(() => page = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
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

// ============================================================
// 1. DASHBOARD
// ============================================================

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int projectCount = 0;
  int estimateCount = 0;
  int standardCount = 0;
  int priceCount = 0;
  int documentCount = 0;
  int inspectionCount = 0;

  double estimateTotal = 0;

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final projects = await db.from('projects').select('id');

      final estimates = await db.from('estimates').select('id,total');

      final standards =
          await db.from('construction_standards').select('id');

      final prices = await db.from('prices').select('id');

      final documents = await db.from('documents').select('id');

      final inspections =
          await db.from('technical_inspections').select('id');

      if (!mounted) return;

      setState(() {
        projectCount = projects.length;
        estimateCount = estimates.length;
        standardCount = standards.length;
        priceCount = prices.length;
        documentCount = documents.length;
        inspectionCount = inspections.length;

        estimateTotal = estimates.fold<double>(
          0,
          (sum, row) => sum + n(row['total']),
        );

        busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Dashboard: $e');
      }
    }
  }

  Widget stat(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: primary),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'SMETA TJ ONLINE',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '«...БА ФАРЗАНДОНУ НАБЕРАҲОЯМОН ЯК МУЛКИ ОБОД МЕРОС ГУЗОРЕМ.»',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text('— Эмомалӣ Раҳмон'),
          const SizedBox(height: 10),
          Text(db.auth.currentUser?.email ?? ''),
          if (busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 10),
          stat(
            'Объектҳо',
            '$projectCount',
            Icons.apartment,
          ),
          stat(
            'Сметаҳо',
            '$estimateCount',
            Icons.calculate,
          ),
          stat(
            'Меъёрҳои сохтмонӣ',
            '$standardCount',
            Icons.menu_book,
          ),
          stat(
            'Нархҳо',
            '$priceCount',
            Icons.payments,
          ),
          stat(
            'Ҳуҷҷатҳо',
            '$documentCount',
            Icons.description,
          ),
          stat(
            'Санҷишҳои техникӣ',
            '$inspectionCount',
            Icons.fact_check,
          ),
          stat(
            'Ҷамъи сметаҳо',
            '${money(estimateTotal)} сом.',
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. PROJECTS
// ============================================================

class Projects extends StatefulWidget {
  const Projects({super.key});

  @override
  State<Projects> createState() => _ProjectsState();
}

class _ProjectsState extends State<Projects> {
  List<Map<String, dynamic>> rows = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(data);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Объектҳо: $e');
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? old]) async {
    final name =
        TextEditingController(text: '${old?['name'] ?? ''}');

    final address =
        TextEditingController(text: '${old?['address'] ?? ''}');

    final customer =
        TextEditingController(text: '${old?['customer'] ?? ''}');

    final contractor =
        TextEditingController(text: '${old?['contractor'] ?? ''}');

    final engineer =
        TextEditingController(text: '${old?['engineer'] ?? ''}');

    final budget =
        TextEditingController(text: '${old?['budget'] ?? ''}');

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(
                old == null
                    ? 'Объекти нав'
                    : 'Тағйири объект',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fld(name, 'Номи объект'),
                      const SizedBox(height: 7),
                      fld(address, 'Суроға'),
                      const SizedBox(height: 7),
                      fld(customer, 'Фармоишгар'),
                      const SizedBox(height: 7),
                      fld(contractor, 'Пудратчӣ'),
                      const SizedBox(height: 7),
                      fld(engineer, 'Муҳандис'),
                      const SizedBox(height: 7),
                      fld(
                        budget,
                        'Буҷет',
                        number: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Бекор'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || name.text.trim().isEmpty) return;

    final data = {
      'name': name.text.trim(),
      'address': address.text.trim(),
      'customer': customer.text.trim(),
      'contractor': contractor.text.trim(),
      'engineer': engineer.text.trim(),
      'budget': n(budget.text),
      'status': 'Дар кор',
    };

    try {
      if (old == null) {
        await db.from('projects').insert({
          ...data,
          'user_id': uid,
        });
      } else {
        await db
            .from('projects')
            .update(data)
            .eq('id', old['id']);
      }

      await load();
    } catch (e) {
      if (mounted) note(context, 'Сабти объект: $e');
    }
  }

  Future<void> remove(Map<String, dynamic> row) async {
    try {
      await db.from('projects').delete().eq('id', row['id']);
      await load();
    } catch (e) {
      if (mounted) note(context, 'Нест кардан: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: busy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...rows.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.apartment,
                          color: primary,
                        ),
                        title: Text('${r['name']}'),
                        subtitle: Text(
                          '${r['address'] ?? ''}\n'
                          'Буҷет: ${money(r['budget'])} сом.',
                        ),
                        isThreeLine: true,
                        onTap: () => edit(r),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => remove(r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// 3. ESTIMATES
// ============================================================

class Estimates extends StatefulWidget {
  const Estimates({super.key});

  @override
  State<Estimates> createState() => _EstimatesState();
}

class _EstimatesState extends State<Estimates> {
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> projects = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final e = await db
          .from('estimates')
          .select()
          .order('created_at', ascending: false);

      final p = await db.from('projects').select('id,name');

      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(e);
          projects = List<Map<String, dynamic>>.from(p);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Сметаҳо: $e');
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? old]) async {
    if (projects.isEmpty) {
      note(context, 'Аввал объект созед.');
      return;
    }

    final title =
        TextEditingController(text: '${old?['title'] ?? ''}');

    String projectId =
        '${old?['project_id'] ?? projects.first['id']}';

    String estimateType =
        '${old?['estimate_type'] ?? 'Локалӣ'}';

    String status = '${old?['status'] ?? 'Лоиҳа'}';

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialog) {
                return AlertDialog(
                  title: Text(
                    old == null
                        ? 'Сметаи нав'
                        : 'Тағйири смета',
                  ),
                  content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: projectId,
                            items: projects
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: '${p['id']}',
                                    child:
                                        Text('${p['name']}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialog(() {
                                projectId =
                                    value ?? projectId;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Объект',
                            ),
                          ),
                          const SizedBox(height: 8),
                          fld(title, 'Номи смета'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: estimateType,
                            items: const [
                              DropdownMenuItem(
                                value: 'Локалӣ',
                                child: Text('Локалӣ'),
                              ),
                              DropdownMenuItem(
                                value: 'Объектӣ',
                                child: Text('Объектӣ'),
                              ),
                              DropdownMenuItem(
                                value: 'Ҷамъбастӣ',
                                child: Text('Ҷамъбастӣ'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialog(() {
                                estimateType =
                                    value ?? estimateType;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Намуди смета',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: status,
                            items: const [
                              DropdownMenuItem(
                                value: 'Лоиҳа',
                                child: Text('Лоиҳа'),
                              ),
                              DropdownMenuItem(
                                value: 'Дар кор',
                                child: Text('Дар кор'),
                              ),
                              DropdownMenuItem(
                                value: 'Тасдиқшуда',
                                child: Text('Тасдиқшуда'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialog(() {
                                status = value ?? status;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Ҳолат',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text('Бекор'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      child: const Text('Сабт'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!ok || title.text.trim().isEmpty) return;

    final data = {
      'project_id': projectId,
      'title': title.text.trim(),
      'estimate_type': estimateType,
      'status': status,
    };

    try {
      if (old == null) {
        await db.from('estimates').insert({
          ...data,
          'user_id': uid,
          'subtotal': 0,
          'total': 0,
        });
      } else {
        await db
            .from('estimates')
            .update(data)
            .eq('id', old['id']);
      }

      await load();
    } catch (e) {
      if (mounted) note(context, 'Сабти смета: $e');
    }
  }

  Future<void> remove(Map<String, dynamic> row) async {
    try {
      await db
          .from('estimate_items')
          .delete()
          .eq('estimate_id', row['id']);

      await db
          .from('estimates')
          .delete()
          .eq('id', row['id']);

      await load();
    } catch (e) {
      if (mounted) note(context, 'Нест кардан: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: busy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...rows.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.calculate,
                          color: primary,
                        ),
                        title: Text('${r['title']}'),
                        subtitle: Text(
                          '${r['estimate_type']} • '
                          '${r['status']}\n'
                          '${money(r['total'])} сом.',
                        ),
                        isThreeLine: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EstimateItems(
                                estimate: r,
                              ),
                            ),
                          );

                          await load();
                        },
                        onLongPress: () => edit(r),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete),
                          onPressed: () => remove(r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// ESTIMATE ITEMS
// ============================================================

class EstimateItems extends StatefulWidget {
  final Map<String, dynamic> estimate;

  const EstimateItems({
    super.key,
    required this.estimate,
  });

  @override
  State<EstimateItems> createState() =>
      _EstimateItemsState();
}

class _EstimateItemsState extends State<EstimateItems> {
  List<Map<String, dynamic>> rows = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('estimate_items')
          .select()
          .eq(
            'estimate_id',
            widget.estimate['id'],
          )
          .order('created_at');

      final list =
          List<Map<String, dynamic>>.from(data);

      final total = list.fold<double>(
        0,
        (sum, row) =>
            sum + n(row['total_price']),
      );

      await db
          .from('estimates')
          .update({
            'subtotal': total,
            'total': total,
          })
          .eq(
            'id',
            widget.estimate['id'],
          );

      if (mounted) {
        setState(() {
          rows = list;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Корҳои смета: $e');
      }
    }
  }

  Future<void> edit(
      [Map<String, dynamic>? old]) async {
    final work = TextEditingController(
      text: '${old?['work_name'] ?? ''}',
    );

    final unit = TextEditingController(
      text: '${old?['unit'] ?? ''}',
    );

    final quantity = TextEditingController(
      text: '${old?['quantity'] ?? ''}',
    );

    final price = TextEditingController(
      text: '${old?['unit_price'] ?? ''}',
    );

    final coefficient = TextEditingController(
      text: '${old?['coefficient'] ?? 1}',
    );

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(
                old == null
                    ? 'Кори нав'
                    : 'Тағйири кор',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fld(work, 'Номи кор'),
                      const SizedBox(height: 7),
                      fld(unit, 'Воҳид'),
                      const SizedBox(height: 7),
                      fld(
                        quantity,
                        'Миқдор',
                        number: true,
                      ),
                      const SizedBox(height: 7),
                      fld(
                        price,
                        'Нархи воҳид',
                        number: true,
                      ),
                      const SizedBox(height: 7),
                      fld(
                        coefficient,
                        'Коэффитсиент',
                        number: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child: const Text('Бекор'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    true,
                  ),
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || work.text.trim().isEmpty) {
      return;
    }

    final qty = n(quantity.text);
    final unitPrice = n(price.text);

    var coef = n(coefficient.text);

    if (coef == 0) coef = 1;

    final total = qty * unitPrice * coef;

    final data = {
      'work_name': work.text.trim(),
      'unit': unit.text.trim(),
      'quantity': qty,
      'unit_price': unitPrice,
      'coefficient': coef,
      'total_price': total,
    };

    try {
      if (old == null) {
        await db.from('estimate_items').insert({
          ...data,
          'user_id': uid,
          'estimate_id':
              widget.estimate['id'],
        });
      } else {
        await db
            .from('estimate_items')
            .update(data)
            .eq('id', old['id']);
      }

      await load();
    } catch (e) {
      if (mounted) note(context, 'Сабти кор: $e');
    }
  }

  Future<void> remove(
      Map<String, dynamic> row) async {
    try {
      await db
          .from('estimate_items')
          .delete()
          .eq('id', row['id']);

      await load();
    } catch (e) {
      if (mounted) note(context, 'Нест кардан: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(
      0,
      (sum, row) =>
          sum + n(row['total_price']),
    );

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.estimate['title']}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: busy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: const Text(
                        'ҶАМЪИ СМЕТА',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      trailing: Text(
                        '${money(total)} сом.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  ...rows.map(
                    (r) => Card(
                      child: ListTile(
                        title:
                            Text('${r['work_name']}'),
                        subtitle: Text(
                          '${r['quantity']} '
                          '${r['unit']} × '
                          '${money(r['unit_price'])} × '
                          '${r['coefficient']}',
                        ),
                        onTap: () => edit(r),
                        trailing: SizedBox(
                          width: 145,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${money(r['total_price'])}',
                                  textAlign:
                                      TextAlign.end,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete),
                                onPressed: () =>
                                    remove(r),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// 4. CONSTRUCTION STANDARDS
// ============================================================

class Standards extends StatefulWidget {
  const Standards({super.key});

  @override
  State<Standards> createState() =>
      _StandardsState();
}

class _StandardsState extends State<Standards> {
  final search = TextEditingController();

  List<Map<String, dynamic>> rows = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('construction_standards')
          .select()
          .order('code');

      if (mounted) {
        setState(() {
          rows =
              List<Map<String, dynamic>>.from(data);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Меъёрҳо: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text
        .trim()
        .toLowerCase();

    final filtered = rows.where((r) {
      final text =
          '${r['code']} '
          '${r['title']} '
          '${r['document_type']} '
          '${r['status']} '
          '${r['notes']}'
              .toLowerCase();

      return text.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText:
                  'Ҷустуҷӯи меъёри сохтмонӣ',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ҳамагӣ: ${rows.length} меъёр',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (busy)
            const LinearProgressIndicator(),
          const SizedBox(height: 8),
          ...filtered.map(
            (r) => Card(
              child: ListTile(
                leading: Icon(
                  r['status'] == 'Амалкунанда'
                      ? Icons.verified
                      : Icons.warning_amber,
                  color: r['status'] ==
                          'Амалкунанда'
                      ? primary
                      : Colors.orange,
                ),
                title: Text(
                  '${r['code']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${r['title']}\n'
                  '${r['document_type']} • '
                  '${r['edition_year']} • '
                  '${r['status']}\n'
                  '${r['notes'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. PRICES
// ============================================================

class Prices extends StatefulWidget {
  const Prices({super.key});

  @override
  State<Prices> createState() => _PricesState();
}

class _PricesState extends State<Prices> {
  final search = TextEditingController();

  List<Map<String, dynamic>> rows = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('prices')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          rows =
              List<Map<String, dynamic>>.from(data);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Нархҳо: $e');
      }
    }
  }

  Future<void> edit(
      [Map<String, dynamic>? old]) async {
    final category = TextEditingController(
      text: '${old?['category'] ?? ''}',
    );

    final name = TextEditingController(
      text: '${old?['name'] ?? ''}',
    );

    final unit = TextEditingController(
      text: '${old?['unit'] ?? ''}',
    );

    final price = TextEditingController(
      text: '${old?['price'] ?? ''}',
    );

    final region = TextEditingController(
      text: '${old?['region'] ?? 'Душанбе'}',
    );

    final supplier = TextEditingController(
      text: '${old?['supplier'] ?? ''}',
    );

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(
                old == null
                    ? 'Нархи нав'
                    : 'Тағйири нарх',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fld(category, 'Категория'),
                      const SizedBox(height: 7),
                      fld(name, 'Ном'),
                      const SizedBox(height: 7),
                      fld(unit, 'Воҳид'),
                      const SizedBox(height: 7),
                      fld(
                        price,
                        'Нарх',
                        number: true,
                      ),
                      const SizedBox(height: 7),
                      fld(region, 'Минтақа'),
                      const SizedBox(height: 7),
                      fld(
                        supplier,
                        'Таъминкунанда',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child: const Text('Бекор'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    true,
                  ),
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || name.text.trim().isEmpty) {
      return;
    }

    final data = {
      'category': category.text.trim(),
      'name': name.text.trim(),
      'unit': unit.text.trim(),
      'price': n(price.text),
      'currency': 'TJS',
      'region': region.text.trim(),
      'supplier': supplier.text.trim(),
      'is_official': false,
    };

    try {
      if (old == null) {
        await db.from('prices').insert({
          ...data,
          'owner_user_id': uid,
        });
      } else {
        await db
            .from('prices')
            .update(data)
            .eq('id', old['id']);
      }

      await load();
    } catch (e) {
      if (mounted) {
        note(context, 'Сабти нарх: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.toLowerCase();

    final filtered = rows.where((r) {
      return '${r['name']} '
              '${r['category']} '
              '${r['supplier']} '
              '${r['region']}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Ҷустуҷӯи нарх',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (busy)
              const LinearProgressIndicator(),
            const SizedBox(height: 10),
            ...filtered.map(
              (r) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.payments,
                    color: primary,
                  ),
                  title: Text('${r['name']}'),
                  subtitle: Text(
                    '${r['category']} • '
                    '${r['unit']}\n'
                    '${r['region']} • '
                    '${r['supplier']}',
                  ),
                  isThreeLine: true,
                  onTap: r['owner_user_id'] == uid
                      ? () => edit(r)
                      : null,
                  trailing: Text(
                    '${money(r['price'])} сом.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. DOCUMENTS
// ============================================================

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() =>
      _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> estimates = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await db
          .from('documents')
          .select()
          .order('created_at', ascending: false);

      final p =
          await db.from('projects').select('id,name');

      final e =
          await db.from('estimates').select('id,title');

      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(d);
          projects =
              List<Map<String, dynamic>>.from(p);
          estimates =
              List<Map<String, dynamic>>.from(e);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Ҳуҷҷатҳо: $e');
      }
    }
  }

  Future<void> add() async {
    final title = TextEditingController();
    final notes = TextEditingController();

    String type = 'Смета';

    String? projectId = projects.isEmpty
        ? null
        : '${projects.first['id']}';

    String? estimateId = estimates.isEmpty
        ? null
        : '${estimates.first['id']}';

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialog) {
                return AlertDialog(
                  title:
                      const Text('Ҳуҷҷати нав'),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          fld(
                            title,
                            'Номи ҳуҷҷат',
                          ),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<
                              String>(
                            initialValue: type,
                            items: const [
                              DropdownMenuItem(
                                value: 'Смета',
                                child: Text('Смета'),
                              ),
                              DropdownMenuItem(
                                value: 'Санад',
                                child: Text('Санад'),
                              ),
                              DropdownMenuItem(
                                value:
                                    'Акти корҳои пӯшида',
                                child: Text(
                                  'Акти корҳои пӯшида',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Журнал',
                                child: Text('Журнал'),
                              ),
                              DropdownMenuItem(
                                value: 'Протокол',
                                child: Text('Протокол'),
                              ),
                              DropdownMenuItem(
                                value: 'Ҳисобот',
                                child: Text('Ҳисобот'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialog(() {
                                type = value ?? type;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Намуди ҳуҷҷат',
                            ),
                          ),
                          if (projects.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            DropdownButtonFormField<
                                String>(
                              initialValue: projectId,
                              items: projects
                                  .map(
                                    (p) =>
                                        DropdownMenuItem(
                                      value:
                                          '${p['id']}',
                                      child: Text(
                                        '${p['name']}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialog(() {
                                  projectId = value;
                                });
                              },
                              decoration:
                                  const InputDecoration(
                                labelText: 'Объект',
                              ),
                            ),
                          ],
                          if (estimates.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            DropdownButtonFormField<
                                String>(
                              initialValue: estimateId,
                              items: estimates
                                  .map(
                                    (e) =>
                                        DropdownMenuItem(
                                      value:
                                          '${e['id']}',
                                      child: Text(
                                        '${e['title']}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialog(() {
                                  estimateId = value;
                                });
                              },
                              decoration:
                                  const InputDecoration(
                                labelText: 'Смета',
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          fld(
                            notes,
                            'Эзоҳ',
                            lines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text('Бекор'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      child: const Text('Сабт'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!ok || title.text.trim().isEmpty) {
      return;
    }

    try {
      await db.from('documents').insert({
        'user_id': uid,
        'project_id': projectId,
        'estimate_id': estimateId,
        'title': title.text.trim(),
        'document_type': type,
        'status': 'Лоиҳа',
        'notes': notes.text.trim(),
      });

      await load();
    } catch (e) {
      if (mounted) {
        note(context, 'Сабти ҳуҷҷат: $e');
      }
    }
  }

  Future<void> remove(
      Map<String, dynamic> row) async {
    try {
      await db
          .from('documents')
          .delete()
          .eq('id', row['id']);

      await load();
    } catch (e) {
      if (mounted) note(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: busy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Смета • Санад • Акт • Журнал • Протокол • Ҳисобот',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...rows.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.description,
                          color: primary,
                        ),
                        title: Text('${r['title']}'),
                        subtitle: Text(
                          '${r['document_type']} • '
                          '${r['status']}\n'
                          '${r['notes'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete),
                          onPressed: () => remove(r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// 7. TECHNICAL SUPERVISION
// ============================================================

class Technical extends StatefulWidget {
  const Technical({super.key});

  @override
  State<Technical> createState() =>
      _TechnicalState();
}

class _TechnicalState extends State<Technical> {
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> projects = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final inspections = await db
          .from('technical_inspections')
          .select()
          .order('created_at', ascending: false);

      final p =
          await db.from('projects').select('id,name');

      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(
            inspections,
          );

          projects =
              List<Map<String, dynamic>>.from(p);

          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(
          context,
          'Назорати техникӣ: $e',
        );
      }
    }
  }

  Future<void> add() async {
    if (projects.isEmpty) {
      note(context, 'Аввал объект созед.');
      return;
    }

    final title = TextEditingController();
    final notes = TextEditingController();

    String projectId =
        '${projects.first['id']}';

    String result = 'Мутобиқ';

    String category = 'Сохтмон';

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialog) {
                return AlertDialog(
                  title: const Text(
                    'Санҷиши техникӣ',
                  ),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<
                              String>(
                            initialValue: projectId,
                            items: projects
                                .map(
                                  (p) =>
                                      DropdownMenuItem(
                                    value: '${p['id']}',
                                    child: Text(
                                      '${p['name']}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialog(() {
                                projectId =
                                    value ?? projectId;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Объект',
                            ),
                          ),
                          const SizedBox(height: 7),
                          fld(
                            title,
                            'Номи санҷиш',
                          ),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<
                              String>(
                            initialValue: category,
                            items: const [
                              DropdownMenuItem(
                                value: 'Сохтмон',
                                child: Text(
                                  'Сохтмон',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Бетон',
                                child: Text('Бетон'),
                              ),
                              DropdownMenuItem(
                                value: 'Арматура',
                                child:
                                    Text('Арматура'),
                              ),
                              DropdownMenuItem(
                                value: 'Геодезия',
                                child:
                                    Text('Геодезия'),
                              ),
                              DropdownMenuItem(
                                value:
                                    'Корҳои пӯшида',
                                child: Text(
                                  'Корҳои пӯшида',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Бехатарӣ',
                                child:
                                    Text('Бехатарӣ'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialog(() {
                                category =
                                    value ?? category;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Категория',
                            ),
                          ),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<
                              String>(
                            initialValue: result,
                            items: const [
                              DropdownMenuItem(
                                value: 'Мутобиқ',
                                child:
                                    Text('Мутобиқ'),
                              ),
                              DropdownMenuItem(
                                value:
                                    'Эзоҳ дорад',
                                child: Text(
                                  'Эзоҳ дорад',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Номувофиқ',
                                child:
                                    Text('Номувофиқ'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialog(() {
                                result =
                                    value ?? result;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText: 'Натиҷа',
                            ),
                          ),
                          const SizedBox(height: 7),
                          fld(
                            notes,
                            'Эзоҳ',
                            lines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text('Бекор'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      child: const Text('Сабт'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!ok || title.text.trim().isEmpty) {
      return;
    }

    try {
      await db
          .from('technical_inspections')
          .insert({
        'user_id': uid,
        'project_id': projectId,
        'title': title.text.trim(),
        'category': category,
        'result': result,
        'notes': notes.text.trim(),
        'inspection_date':
            DateTime.now().toIso8601String(),
      });

      await load();
    } catch (e) {
      if (mounted) {
        note(
          context,
          'Сабти назорати техникӣ: $e',
        );
      }
    }
  }

  Future<void> remove(
      Map<String, dynamic> row) async {
    try {
      await db
          .from('technical_check_items')
          .delete()
          .eq(
            'inspection_id',
            row['id'],
          );

      await db
          .from('technical_inspections')
          .delete()
          .eq('id', row['id']);

      await load();
    } catch (e) {
      if (mounted) note(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: busy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...rows.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.fact_check,
                          color: primary,
                        ),
                        title: Text('${r['title']}'),
                        subtitle: Text(
                          '${r['category']} • '
                          '${r['result']}\n'
                          '${r['notes'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete),
                          onPressed: () => remove(r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// 8. SYNC
// ============================================================

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() =>
      _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  List<Map<String, dynamic>> rows = [];

  bool busy = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('sync_log')
          .select()
          .order('synced_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          rows =
              List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> sync() async {
    setState(() => busy = true);

    try {
      await db
          .from('projects')
          .select('id')
          .limit(1);

      await db.from('sync_log').insert({
        'user_id': uid,
        'device_name': 'SMETA TJ Android',
        'sync_status': 'OK',
        'message':
            'Пайвастшавӣ бо Supabase муваффақ.',
      });

      await load();

      if (mounted) {
        note(context, 'Sync OK');
      }
    } catch (e) {
      if (mounted) {
        note(context, 'Sync: $e');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final online =
        db.auth.currentSession != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              online
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              color:
                  online ? primary : Colors.red,
            ),
            title: Text(
              online
                  ? 'Supabase Online'
                  : 'Offline',
            ),
            subtitle: Text(
              db.auth.currentUser?.email ?? '',
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: busy ? null : sync,
          icon: const Icon(Icons.sync),
          label: Text(
            busy
                ? 'Санҷиш...'
                : 'Санҷидани Sync',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Таърихи Sync',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        ...rows.map(
          (r) => ListTile(
            leading: const Icon(
              Icons.history,
            ),
            title:
                Text('${r['sync_status']}'),
            subtitle:
                Text('${r['message'] ?? ''}'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 9. MARKETPLACE
// ============================================================

class Market extends StatefulWidget {
  const Market({super.key});

  @override
  State<Market> createState() =>
      _MarketState();
}

class _MarketState extends State<Market> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> suppliers = [];

  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await db
          .from('marketplace_products')
          .select()
          .order('created_at', ascending: false);

      final s = await db
          .from('suppliers')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          products =
              List<Map<String, dynamic>>.from(p);

          suppliers =
              List<Map<String, dynamic>>.from(s);

          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        note(context, 'Marketplace: $e');
      }
    }
  }

  String supplierName(dynamic id) {
    for (final supplier in suppliers) {
      if ('${supplier['id']}' == '$id') {
        return '${supplier['name']}';
      }
    }

    return '';
  }

  Future<void> addSupplier() async {
    final name = TextEditingController();
    final phone = TextEditingController();

    final region =
        TextEditingController(text: 'Душанбе');

    final address = TextEditingController();

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title:
                  const Text('Таъминкунанда'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fld(name, 'Ном'),
                      const SizedBox(height: 7),
                      fld(phone, 'Телефон'),
                      const SizedBox(height: 7),
                      fld(region, 'Минтақа'),
                      const SizedBox(height: 7),
                      fld(address, 'Суроға'),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child: const Text('Бекор'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    true,
                  ),
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || name.text.trim().isEmpty) {
      return;
    }

    try {
      await db.from('suppliers').insert({
        'owner_user_id': uid,
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'region': region.text.trim(),
        'address': address.text.trim(),
        'is_active': true,
      });

      await load();
    } catch (e) {
      if (mounted) note(context, '$e');
    }
  }

  Future<void> addProduct() async {
    if (suppliers.isEmpty) {
      note(
        context,
        'Аввал таъминкунанда илова кунед.',
      );
      return;
    }

    final name = TextEditingController();
    final category = TextEditingController();
    final unit = TextEditingController();
    final price = TextEditingController();

    final region =
        TextEditingController(text: 'Душанбе');

    final description = TextEditingController();

    String supplierId =
        '${suppliers.first['id']}';

    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialog) {
                return AlertDialog(
                  title: const Text(
                    'Маҳсулоти Marketplace',
                  ),
                  content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                supplierId,
                            items: suppliers
                                .map(
                                  (s) =>
                                      DropdownMenuItem(
                                    value: '${s['id']}',
                                    child: Text(
                                      '${s['name']}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialog(() {
                                supplierId =
                                    value ??
                                        supplierId;
                              });
                            },
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Таъминкунанда',
                            ),
                          ),
                          const SizedBox(height: 7),
                          fld(name, 'Ном'),
                          const SizedBox(height: 7),
                          fld(
                            category,
                            'Категория',
                          ),
                          const SizedBox(height: 7),
                          fld(unit, 'Воҳид'),
                          const SizedBox(height: 7),
                          fld(
                            price,
                            'Нарх',
                            number: true,
                          ),
                          const SizedBox(height: 7),
                          fld(region, 'Минтақа'),
                          const SizedBox(height: 7),
                          fld(
                            description,
                            'Тавсиф',
                            lines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text('Бекор'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      child: const Text('Сабт'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!ok || name.text.trim().isEmpty) {
      return;
    }

    try {
      await db
          .from('marketplace_products')
          .insert({
        'owner_user_id': uid,
        'supplier_id': supplierId,
        'name': name.text.trim(),
        'category': category.text.trim(),
        'unit': unit.text.trim(),
        'price': n(price.text),
        'currency': 'TJS',
        'region': region.text.trim(),
        'description':
            description.text.trim(),
        'is_active': true,
      });

      await load();
    } catch (e) {
      if (mounted) note(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: addSupplier,
                  icon: const Icon(Icons.store),
                  label: const Text(
                    'Таъминкунанда',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: addProduct,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                  ),
                  label:
                      const Text('Маҳсулот'),
                ),
              ),
            ],
          ),
          if (busy)
            const LinearProgressIndicator(),
          const SizedBox(height: 14),
          ...products.map(
            (r) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.storefront,
                  color: primary,
                ),
                title: Text('${r['name']}'),
                subtitle: Text(
                  '${supplierName(r['supplier_id'])}\n'
                  '${r['region']} • '
                  '${r['unit']}',
                ),
                isThreeLine: true,
                trailing: Text(
                  '${money(r['price'])} сом.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 10. AI SMETA TJ
// ============================================================

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() =>
      _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final question = TextEditingController();

  String answer = '';

  bool busy = false;

  Future<void> run() async {
    final query = question.text.trim();

    if (query.isEmpty) {
      note(context, 'Саволро нависед.');
      return;
    }

    setState(() => busy = true);

    try {
      final standards = await db
          .from('construction_standards')
          .select()
          .limit(500);

      final prices = await db
          .from('prices')
          .select()
          .limit(500);

      final words = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 2)
          .toList();

      final matchedStandards =
          standards.where((r) {
        final text =
            '${r['code']} '
            '${r['title']} '
            '${r['document_type']} '
            '${r['notes']}'
                .toLowerCase();

        return words.any(text.contains);
      }).take(10);

      final matchedPrices = prices.where((r) {
        final text =
            '${r['name']} '
            '${r['category']} '
            '${r['region']} '
            '${r['supplier']}'
                .toLowerCase();

        return words.any(text.contains);
      }).take(10);

      final result = StringBuffer();

      if (matchedStandards.isNotEmpty) {
        result.writeln('МЕЪЁРҲОИ МУВОФИҚ:');

        for (final r in matchedStandards) {
          result.writeln(
            '• ${r['code']} — '
            '${r['title']} '
            '[${r['status']}]',
          );
        }
      }

      if (matchedPrices.isNotEmpty) {
        if (result.isNotEmpty) {
          result.writeln();
        }

        result.writeln('НАРХҲОИ МУВОФИҚ:');

        for (final r in matchedPrices) {
          result.writeln(
            '• ${r['name']} — '
            '${money(r['price'])} сом/'
            '${r['unit']}',
          );
        }
      }

      if (result.isEmpty) {
        result.write(
          'Дар база маълумоти мувофиқ ёфт нашуд.',
        );
      }

      answer = result.toString();

      await db.from('ai_history').insert({
        'user_id': uid,
        'question': query,
        'answer': answer,
        'ai_mode': 'database_search',
      });

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          answer = 'Хато: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 34,
              color: primary,
            ),
            SizedBox(width: 10),
            Text(
              'AI SMETA TJ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ҷустуҷӯ дар базаи меъёрҳои сохтмонӣ ва нархҳои SMETA TJ.',
        ),
        const SizedBox(height: 14),
        fld(
          question,
          'Савол ё номи меъёр / мавод / кор',
          lines: 3,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : run,
          icon: const Icon(
            Icons.auto_awesome,
          ),
          label: Text(
            busy ? 'Ҷустуҷӯ...' : 'Таҳлил',
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              answer.isEmpty
                  ? 'Натиҷа дар ин ҷо нишон дода мешавад.'
                  : answer,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SMETA TJ v1.0 FINAL — END
// ============================================================
