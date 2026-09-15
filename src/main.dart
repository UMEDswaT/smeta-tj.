      import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
const authRedirect = 'tj.smetatj.app://login-callback/';
const primary = Color(0xFF006B55);

SupabaseClient get db => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const SmetaTjApp());
}

class SmetaTjApp extends StatelessWidget {
  const SmetaTjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMETA TJ',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F7F6),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD9E1DE),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

void notice(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

double numberValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String money(dynamic value) {
  final number = numberValue(value);

  if (number == number.roundToDouble()) {
    return number.toStringAsFixed(0);
  }

  return number.toStringAsFixed(2);
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Тасдиқ',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Не'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

// =====================================================
// AUTH
// =====================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            db.auth.currentSession == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (db.auth.currentSession == null) {
          return const LoginPage();
        }

        return const MainPage();
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

  bool register = false;
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final userEmail = email.text.trim();
    final userPassword = password.text;

    if (userEmail.isEmpty) {
      notice(context, 'Email-ро ворид кунед.');
      return;
    }

    if (userPassword.length < 6) {
      notice(
        context,
        'Рамз бояд на камтар аз 6 аломат бошад.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (register) {
        await db.auth.signUp(
          email: userEmail,
          password: userPassword,
          emailRedirectTo: authRedirect,
        );

        if (!mounted) return;

        notice(
          context,
          'Ҳисоб сохта шуд. Email-ро тасдиқ кунед.',
        );
      } else {
        await db.auth.signInWithPassword(
          email: userEmail,
          password: userPassword,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      notice(context, e.message);
    } catch (e) {
      if (!mounted) return;
      notice(context, 'Хатои система: $e');
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F4ED),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.architecture_rounded,
                      size: 48,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SMETA TJ',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Системаи рақамии сохтмони Тоҷикистон',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF596460),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8E5),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: 'Рамз',
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: loading ? null : submit,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
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
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(
                                    () => register = !register,
                                  );
                                },
                          child: Text(
                            register
                                ? 'Ҳисоб доред? Ворид шавед'
                                : 'Ҳисоби нав созед',
                          ),
                        ),
                      ],
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

// =====================================================
// MAIN 1-5
// =====================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  static const pages = [
    DashboardPage(),
    ProjectsPage(),
    EstimatesPage(),
    StandardsPage(),
    PricesPage(),
  ];

  static const titles = [
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
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Навсозӣ',
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Баромад',
            onPressed: () async {
              await db.auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 74,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Асосӣ',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment_rounded),
            label: 'Объект',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Смета',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Меъёр',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Нарх',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// 1. DASHBOARD
// =====================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;

  int projectCount = 0;
  int estimateCount = 0;
  int standardCount = 0;
  int priceCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final results = await Future.wait([
        db.from('projects').select('id'),
        db.from('estimates').select('id'),
        db.from('construction_standards').select('id'),
        db.from('prices').select('id'),
      ]);

      if (!mounted) return;

      setState(() {
        projectCount = results[0].length;
        estimateCount = results[1].length;
        standardCount = results[2].length;
        priceCount = results[3].length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      notice(context, 'Хатои боркунӣ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = db.auth.currentUser?.email ?? '';

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1FAF6),
                  Color(0xFFE3F2EC),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD8E8E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.architecture_rounded,
                        color: primary,
                        size: 31,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMETA TJ ONLINE',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                            style: TextStyle(
                              color: Color(0xFF53605C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '«...БА ФАРЗАНДОНУ НАБЕРАҲОЯМОН '
                  'ЯК МУЛКИ ОБОД МЕРОС ГУЗОРЕМ.»',
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Эмомалӣ Раҳмон',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userEmail,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Шарҳи умумӣ',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: statCard(
                  icon: Icons.apartment_rounded,
                  title: 'Объектҳо',
                  value: projectCount,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: statCard(
                  icon: Icons.calculate_rounded,
                  title: 'Сметаҳо',
                  value: estimateCount,
                  loading: loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: statCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Меъёрҳо',
                  value: standardCount,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: statCard(
                  icon: Icons.payments_rounded,
                  title: 'Нархҳо',
                  value: priceCount,
                  loading: loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: primary,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMETA TJ Online',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Маълумот бо Supabase ҳамоҳанг мешавад.',
                        style: TextStyle(
                          color: Color(0xFF596460),
                        ),
                      ),
                    ],
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

// =====================================================
// 2. PROJECTS
// =====================================================

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final search = TextEditingController();

  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final data = await db
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        items = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      notice(context, 'Хатои объектҳо: $e');
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();

    if (q.isEmpty) return items;

    return items.where((item) {
      final text = [
        item['name'],
        item['address'],
        item['customer'],
        item['contractor'],
        item['engineer'],
        item['status'],
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> addProject() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final customer = TextEditingController();
    final contractor = TextEditingController();
    final engineer = TextEditingController();
    final budget = TextEditingController();

    String status = 'Нав';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Объекти нав'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      appField(
                        name,
                        'Номи объект *',
                        Icons.apartment_rounded,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        address,
                        'Суроға',
                        Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        customer,
                        'Фармоишгар',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        contractor,
                        'Пудратчӣ',
                        Icons.business_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        engineer,
                        'Муҳандис',
                        Icons.engineering_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        budget,
                        'Буҷет, сомонӣ',
                        Icons.payments_outlined,
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Ҳолат',
                          prefixIcon:
                              Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Нав',
                            child: Text('Нав'),
                          ),
                          DropdownMenuItem(
                            value: 'Дар кор',
                            child: Text('Дар кор'),
                          ),
                          DropdownMenuItem(
                            value: 'Анҷомшуда',
                            child: Text('Анҷомшуда'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ],
                  ),
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
                    if (name.text.trim().isEmpty) {
                      notice(
                        context,
                        'Номи объектро нависед.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await db.from('projects').insert({
          'user_id': db.auth.currentUser!.id,
          'name': name.text.trim(),
          'address': address.text.trim(),
          'customer': customer.text.trim(),
          'contractor': contractor.text.trim(),
          'engineer': engineer.text.trim(),
          'budget': numberValue(budget.text),
          'status': status,
        });

        if (!mounted) return;

        notice(context, 'Объект сабт шуд.');
        await load();
      } catch (e) {
        if (!mounted) return;
        notice(context, 'Хатои сабти объект: $e');
      }
    }

    name.dispose();
    address.dispose();
    customer.dispose();
    contractor.dispose();
    engineer.dispose();
    budget.dispose();
  }

  Future<void> deleteProject(
    Map<String, dynamic> item,
  ) async {
    final yes = await confirmDialog(
      context,
      title: 'Нест кардани объект',
      content:
          'Объекти «${item['name'] ?? ''}» нест карда шавад?',
      confirmLabel: 'Нест кардан',
    );

    if (!yes) return;

    try {
      await db.from('projects').delete().eq('id', item['id']);

      if (!mounted) return;

      notice(context, 'Объект нест карда шуд.');
      await load();
    } catch (e) {
      if (!mounted) return;

      notice(
        context,
        'Объект нест нашуд. Эҳтимол ба он смета пайваст аст: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addProject,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Объект'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            TextField(
              controller: search,
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ҷустуҷӯи объект...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (data.isEmpty)
              emptyView(
                Icons.apartment_outlined,
                'Объект ёфт нашуд',
                'Бо тугмаи «Объект» объекти нав илова кунед.',
              )
            else
              ...data.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: appListCard(
                    icon: Icons.apartment_rounded,
                    title: item['name']?.toString() ??
                        'Бе ном',
                    subtitle: [
                      item['address'],
                      item['customer'],
                      item['status'],
                    ]
                        .where(
                          (value) =>
                              value != null &&
                              value.toString().trim().isNotEmpty,
                        )
                        .join(' • '),
                    trailing:
                        '${money(item['budget'])} сомонӣ',
                    onTap: () {
                      showProjectInfo(item);
                    },
                    onDelete: () {
                      deleteProject(item);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showProjectInfo(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item['name']?.toString() ?? 'Объект',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                infoRow('Суроға', item['address']),
                infoRow('Фармоишгар', item['customer']),
                infoRow('Пудратчӣ', item['contractor']),
                infoRow('Муҳандис', item['engineer']),
                infoRow('Ҳолат', item['status']),
                infoRow(
                  'Буҷет',
                  '${money(item['budget'])} сомонӣ',
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Пӯшидан'),
            ),
          ],
        );
      },
    );
  }
}

// =====================================================
// 3. ESTIMATES
// =====================================================

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  final search = TextEditingController();

  List<Map<String, dynamic>> estimates = [];
  List<Map<String, dynamic>> projects = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final results = await Future.wait([
        db
            .from('estimates')
            .select()
            .order('created_at', ascending: false),
        db
            .from('projects')
            .select('id,name')
            .order('created_at', ascending: false),
      ]);

      if (!mounted) return;

      setState(() {
        estimates =
            List<Map<String, dynamic>>.from(results[0]);
        projects =
            List<Map<String, dynamic>>.from(results[1]);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      notice(context, 'Хатои сметаҳо: $e');
    }
  }

  String projectName(dynamic id) {
    for (final project in projects) {
      if (project['id'].toString() == id?.toString()) {
        return project['name']?.toString() ?? '';
      }
    }

    return '';
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();

    if (q.isEmpty) return estimates;

    return estimates.where((item) {
      final text = [
        item['title'],
        item['estimate_type'],
        item['status'],
        projectName(item['project_id']),
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> addEstimate() async {
    if (projects.isEmpty) {
      notice(
        context,
        'Аввал ҳадди ақал як объект созед.',
      );
      return;
    }

    final title = TextEditingController();
    final subtotal = TextEditingController();
    final total = TextEditingController();

    String? projectId = projects.first['id'].toString();
    String type = 'Локалӣ';
    String status = 'Лоиҳа';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Сметаи нав'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: projectId,
                        decoration: const InputDecoration(
                          labelText: 'Объект',
                          prefixIcon:
                              Icon(Icons.apartment_outlined),
                        ),
                        items: projects.map((project) {
                          return DropdownMenuItem<String>(
                            value: project['id'].toString(),
                            child: Text(
                              project['name']?.toString() ??
                                  'Объект',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(
                            () => projectId = value,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      appField(
                        title,
                        'Номи смета *',
                        Icons.description_outlined,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Намуди смета',
                          prefixIcon:
                              Icon(Icons.category_outlined),
                        ),
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
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Ҳолат',
                          prefixIcon:
                              Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Лоиҳа',
                            child: Text('Лоиҳа'),
                          ),
                          DropdownMenuItem(
                            value: 'Тасдиқшуда',
                            child: Text('Тасдиқшуда'),
                          ),
                          DropdownMenuItem(
                            value: 'Архив',
                            child: Text('Архив'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(
                              () => status = value,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      appField(
                        subtotal,
                        'Маблағи асосӣ',
                        Icons.calculate_outlined,
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        total,
                        'Маблағи умумӣ',
                        Icons.payments_outlined,
                        number: true,
                      ),
                    ],
                  ),
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
                    if (title.text.trim().isEmpty) {
                      notice(
                        context,
                        'Номи сметаро нависед.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && projectId != null) {
      try {
        final base = numberValue(subtotal.text);
        final finalTotal = total.text.trim().isEmpty
            ? base
            : numberValue(total.text);

        await db.from('estimates').insert({
          'user_id': db.auth.currentUser!.id,
          'project_id': projectId,
          'title': title.text.trim(),
          'estimate_type': type,
          'status': status,
          'subtotal': base,
          'total': finalTotal,
        });

        if (!mounted) return;

        notice(context, 'Смета сабт шуд.');
        await load();
      } catch (e) {
        if (!mounted) return;

        notice(context, 'Хатои сабти смета: $e');
      }
    }

    title.dispose();
    subtotal.dispose();
    total.dispose();
  }

  Future<void> deleteEstimate(
    Map<String, dynamic> item,
  ) async {
    final yes = await confirmDialog(
      context,
      title: 'Нест кардани смета',
      content:
          'Сметаи «${item['title'] ?? ''}» нест карда шавад?',
      confirmLabel: 'Нест кардан',
    );

    if (!yes) return;

    try {
      await db.from('estimates').delete().eq('id', item['id']);

      if (!mounted) return;

      notice(context, 'Смета нест карда шуд.');
      await load();
    } catch (e) {
      if (!mounted) return;
      notice(context, 'Хатои нест кардани смета: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addEstimate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Смета'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            TextField(
              controller: search,
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ҷустуҷӯи смета...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (data.isEmpty)
              emptyView(
                Icons.calculate_outlined,
                'Смета ёфт нашуд',
                'Сметаи нави объектро илова кунед.',
              )
            else
              ...data.map(
                (item) {
                  final project =
                      projectName(item['project_id']);

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: appListCard(
                      icon: Icons.calculate_rounded,
                      title: item['title']?.toString() ??
                          'Смета',
                      subtitle: [
                        project,
                        item['estimate_type'],
                        item['status'],
                      ]
                          .where(
                            (value) =>
                                value != null &&
                                value
                                    .toString()
                                    .trim()
                                    .isNotEmpty,
                          )
                          .join(' • '),
                      trailing:
                          '${money(item['total'])} сомонӣ',
                      onTap: () {
                        showEstimateInfo(item);
                      },
                      onDelete: () {
                        deleteEstimate(item);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void showEstimateInfo(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item['title']?.toString() ?? 'Смета',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                infoRow(
                  'Объект',
                  projectName(item['project_id']),
                ),
                infoRow(
                  'Намуд',
                  item['estimate_type'],
                ),
                infoRow('Ҳолат', item['status']),
                infoRow(
                  'Маблағи асосӣ',
                  '${money(item['subtotal'])} сомонӣ',
                ),
                infoRow(
                  'Ҷамъ',
                  '${money(item['total'])} сомонӣ',
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Пӯшидан'),
            ),
          ],
        );
      },
    );
  }
}

// =====================================================
// 4. CONSTRUCTION STANDARDS
// =====================================================

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage> {
  final search = TextEditingController();

  List<Map<String, dynamic>> standards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final data = await db
          .from('construction_standards')
          .select()
          .order('code');

      if (!mounted) return;

      setState(() {
        standards =
            List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      notice(context, 'Хатои меъёрҳо: $e');
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();

    if (q.isEmpty) return standards;

    return standards.where((item) {
      final text = [
        item['code'],
        item['title'],
        item['document_type'],
        item['edition_year'],
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: primary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Пойгоҳи ҳуҷҷатҳои меъёрии сохтмонӣ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            onChanged: (value) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Масалан: МҚС, ҚМҚ, зилзила, меҳмонхона...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (data.isEmpty)
            emptyView(
              Icons.menu_book_outlined,
              'Меъёр ёфт нашуд',
              'Калима ё рамзи дигарро ҷустуҷӯ кунед.',
            )
          else
            ...data.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    standardInfo(context, item);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE0E7E4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F6F1),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['code']?.toString() ??
                                    'Меъёр',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item['title']?.toString() ??
                                    '',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                [
                                  item['document_type'],
                                  item['edition_year'],
                                ]
                                    .where(
                                      (value) =>
                                          value != null &&
                                          value
                                              .toString()
                                              .trim()
                                              .isNotEmpty,
                                    )
                                    .join(' • '),
                                style: const TextStyle(
                                  color: Color(0xFF64706C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                        ),
                      ],
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

// =====================================================
// 5. PRICES
// =====================================================

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final search = TextEditingController();

  List<Map<String, dynamic>> prices = [];
  bool loading = true;

  String categoryFilter = 'Ҳама';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final data = await db
          .from('prices')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        prices = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      notice(context, 'Хатои нархҳо: $e');
    }
  }

  List<String> get categories {
    final result = <String>{};

    for (final item in prices) {
      final value = item['category']?.toString().trim();

      if (value != null && value.isNotEmpty) {
        result.add(value);
      }
    }

    final list = result.toList()..sort();

    return ['Ҳама', ...list];
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();

    return prices.where((item) {
      final category =
          item['category']?.toString() ?? '';

      if (categoryFilter != 'Ҳама' &&
          category != categoryFilter) {
        return false;
      }

      if (q.isEmpty) return true;

      final text = [
        item['category'],
        item['name'],
        item['unit'],
        item['region'],
        item['supplier'],
        item['currency'],
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> addPrice() async {
    final category = TextEditingController();
    final name = TextEditingController();
    final unit = TextEditingController();
    final price = TextEditingController();
    final region = TextEditingController(
      text: 'Душанбе',
    );
    final supplier = TextEditingController();

    bool official = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Нархи нав'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      appField(
                        category,
                        'Категория *',
                        Icons.category_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        name,
                        'Номи масолеҳ / кор / техника *',
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        unit,
                        'Воҳиди ченак (м², м³, кг, дона...) *',
                        Icons.straighten_rounded,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        price,
                        'Нарх *',
                        Icons.payments_outlined,
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        region,
                        'Минтақа',
                        Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 10),
                      appField(
                        supplier,
                        'Таъминкунанда / манбаъ',
                        Icons.business_outlined,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Нархи расмӣ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          official
                              ? 'Манбаи расмӣ'
                              : 'Нархи бозорӣ',
                        ),
                        value: official,
                        onChanged: (value) {
                          setDialogState(
                            () => official = value,
                          );
                        },
                      ),
                    ],
                  ),
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
                    if (category.text.trim().isEmpty ||
                        name.text.trim().isEmpty ||
                        unit.text.trim().isEmpty ||
                        price.text.trim().isEmpty) {
                      notice(
                        context,
                        'Майдонҳои ҳатмиро пур кунед.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Сабт'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await db.from('prices').insert({
          'owner_user_id': db.auth.currentUser!.id,
          'category': category.text.trim(),
          'name': name.text.trim(),
          'unit': unit.text.trim(),
          'price': numberValue(price.text),
          'currency': 'TJS',
          'region': region.text.trim(),
          'supplier': supplier.text.trim(),
          'is_official': official,
        });

        if (!mounted) return;

        notice(context, 'Нарх сабт шуд.');
        await load();
      } catch (e) {
        if (!mounted) return;

        notice(context, 'Хатои сабти нарх: $e');
      }
    }

    category.dispose();
    name.dispose();
    unit.dispose();
    price.dispose();
    region.dispose();
    supplier.dispose();
  }

  Future<void> deletePrice(
    Map<String, dynamic> item,
  ) async {
    final yes = await confirmDialog(
      context,
      title: 'Нест кардани нарх',
      content:
          '«${item['name'] ?? ''}» аз рӯйхати нархҳо нест карда шавад?',
      confirmLabel: 'Нест кардан',
    );

    if (!yes) return;

    try {
      await db.from('prices').delete().eq('id', item['id']);

      if (!mounted) return;

      notice(context, 'Нарх нест карда шуд.');
      await load();
    } catch (e) {
      if (!mounted) return;
      notice(context, 'Хатои нест кардани нарх: $e');
    }
  }

  void showPriceInfo(Map<String, dynamic> item) {
    final official = item['is_official'] == true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item['name']?.toString() ?? 'Нарх',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                infoRow(
                  'Категория',
                  item['category'],
                ),
                infoRow(
                  'Воҳид',
                  item['unit'],
                ),
                infoRow(
                  'Нарх',
                  '${money(item['price'])} сомонӣ',
                ),
                infoRow(
                  'Минтақа',
                  item['region'],
                ),
                infoRow(
                  'Манбаъ',
                  item['supplier'],
                ),
                infoRow(
                  'Навъ',
                  official
                      ? 'Нархи расмӣ'
                      : 'Нархи бозорӣ',
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                deletePrice(item);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Нест кардан'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Пӯшидан'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;
    final categoryItems = categories;

    if (!categoryItems.contains(categoryFilter)) {
      categoryFilter = 'Ҳама';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPrice,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Нарх'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ҷустуҷӯи нарх...',
                      prefixIcon:
                          Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 155,
                  child: DropdownButtonFormField<String>(
                    initialValue: categoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                    ),
                    items: categoryItems.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => categoryFilter = value,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (data.isEmpty)
              emptyView(
                Icons.payments_outlined,
                'Нарх ёфт нашуд',
                'Нархи масолеҳ, кор ё техникаро илова кунед.',
              )
            else
              ...data.map(
                (item) {
                  final official =
                      item['is_official'] == true;

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(18),
                      onTap: () {
                        showPriceInfo(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                const Color(0xFFE0E7E4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: official
                                    ? const Color(
                                        0xFFE5F5ED,
                                      )
                                    : const Color(
                                        0xFFF3F4F4,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                              child: Icon(
                                official
                                    ? Icons
                                        .verified_rounded
                                    : Icons
                                        .payments_rounded,
                                color: official
                                    ? primary
                                    : const Color(
                                        0xFF596460,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    item['name']
                                            ?.toString() ??
                                        'Бе ном',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    [
                                      item['category'],
                                      item['unit'],
                                      item['region'],
                                    ]
                                        .where(
                                          (value) =>
                                              value !=
                                                  null &&
                                              value
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty,
                                        )
                                        .join(' • '),
                                    style: const TextStyle(
                                      color: Color(
                                        0xFF64706C,
                                      ),
                                    ),
                                  ),
                                  if (official) ...[
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    const Text(
                                      'НАРХИ РАСМӢ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: primary,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  money(item['price']),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w900,
                                    color: primary,
                                  ),
                                ),
                                const Text(
                                  'сомонӣ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Color(0xFF64706C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// COMMON WIDGETS
// =====================================================

Widget appField(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool number = false,
}) {
  return TextField(
    controller: controller,
    keyboardType:
        number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    ),
  );
}

Widget statCard({
  required IconData icon,
  required String title,
  required int value,
  required bool loading,
}) {
  return Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFE1E7E5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE9F6F1),
          child: Icon(
            icon,
            color: primary,
          ),
        ),
        const SizedBox(height: 15),
        loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(
                '$value',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF596460),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget emptyView(
  IconData icon,
  String title,
  String subtitle,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 50,
      horizontal: 20,
    ),
    child: Column(
      children: [
        Icon(
          icon,
          size: 60,
          color: const Color(0xFF9AA5A1),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7572),
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget appListCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required String trailing,
  required VoidCallback onTap,
  required VoidCallback onDelete,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E7E4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64706C),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                trailing,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              IconButton(
                tooltip: 'Нест кардан',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget infoRow(String title, dynamic value) {
  final text = value?.toString().trim() ?? '';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64706C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

void standardInfo(
  BuildContext context,
  Map<String, dynamic> item,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          item['code']?.toString() ?? 'Меъёр',
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                infoRow(
                  'Навъи ҳуҷҷат',
                  item['document_type'],
                ),
                infoRow(
                  'Соли нашр',
                  item['edition_year'],
                ),
                infoRow(
                  'Рамз',
                  item['code'],
                ),
                if (item['source_url'] != null &&
                    item['source_url']
                        .toString()
                        .trim()
                        .isNotEmpty)
                  infoRow(
                    'Манбаъ',
                    item['source_url'],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Пӯшидан'),
          ),
        ],
      );
    },
  );
}
