import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

const authRedirect =
    'tj.smetatj.app://login-callback/';

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
    const primary = Color(0xFF006B55);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMETA TJ',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F7F6),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD9E1DE),
            ),
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

void notice(
  BuildContext context,
  String text,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

// =====================================================
// AUTH GATE
// =====================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = db.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return const MainPage();
      },
    );
  }
}

// =====================================================
// LOGIN / REGISTER
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
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
      notice(
        context,
        'Email-ро ворид кунед.',
      );
      return;
    }

    if (userPassword.length < 6) {
      notice(
        context,
        'Рамз бояд на камтар аз 6 аломат бошад.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (register) {
        await db.auth.signUp(
          email: userEmail,
          password: userPassword,
          emailRedirectTo: authRedirect,
        );

        if (mounted) {
          notice(
            context,
            'Ҳисоб сохта шуд. Email-ро тасдиқ кунед.',
          );
        }
      } else {
        await db.auth.signInWithPassword(
          email: userEmail,
          password: userPassword,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        notice(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Хатои система: $e',
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 440,
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE0F4ED,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: const Icon(
                      Icons.architecture_rounded,
                      size: 48,
                      color: Color(0xFF006B55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SMETA TJ',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
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
                  const SizedBox(height: 30),
                  Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFFE2E8E5,
                        ),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(
                            0x10000000,
                          ),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: email,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          autocorrect: false,
                          decoration:
                              const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons
                                  .alternate_email,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          decoration:
                              InputDecoration(
                            labelText: 'Рамз',
                            prefixIcon:
                                const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  obscure =
                                      !obscure;
                                });
                              },
                              icon: Icon(
                                obscure
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed:
                                loading
                                    ? null
                                    : submit,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : Text(
                                    register
                                        ? 'Сабти ном'
                                        : 'Ворид шудан',
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                : 'Ҳисоби нав созед',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SMETA TJ • ONLINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF75817D),
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
// MAIN NAVIGATION
// =====================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() =>
      _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    ProjectsPage(),
    EstimatesPage(),
    StandardsPage(),
  ];

  final titles = const [
    'SMETA TJ',
    'Объектҳо',
    'Смета',
    'Меъёрҳо',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[index],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Баромад',
            onPressed: () async {
              await db.auth.signOut();
            },
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 6),
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
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
            ),
            label: 'Асосӣ',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.apartment_outlined,
            ),
            selectedIcon: Icon(
              Icons.apartment_rounded,
            ),
            label: 'Объектҳо',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calculate_outlined,
            ),
            selectedIcon: Icon(
              Icons.calculate_rounded,
            ),
            label: 'Смета',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            selectedIcon: Icon(
              Icons.menu_book_rounded,
            ),
            label: 'Меъёрҳо',
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
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  bool loading = true;

  int projectCount = 0;
  int estimateCount = 0;
  int standardCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final projects =
          await db.from('projects').select('id');

      final estimates =
          await db.from('estimates').select('id');

      final standards = await db
          .from('construction_standards')
          .select('id');

      if (!mounted) return;

      setState(() {
        projectCount = projects.length;
        estimateCount = estimates.length;
        standardCount = standards.length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      notice(
        context,
        'Хатои боркунии маълумот: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        db.auth.currentUser?.email ?? '';

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          28,
        ),
        children: [
          _heroCard(userEmail),
          const SizedBox(height: 16),
          const Text(
            'Шарҳи умумӣ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.apartment_rounded,
                  title: 'Объектҳо',
                  value: projectCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.calculate_rounded,
                  title: 'Сметаҳо',
                  value: estimateCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _wideStatCard(
            icon: Icons.menu_book_rounded,
            title: 'Меъёрҳои сохтмонӣ',
            subtitle:
                'МҚС, ҚМҚ ва ҳуҷҷатҳои меъёрӣ',
            value: standardCount,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6F1),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: Color(0xFF006B55),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supabase пайваст аст',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Маълумот онлайн нигоҳ дошта мешавад.',
                        style: TextStyle(
                          color: Color(
                            0xFF596460,
                          ),
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

  Widget _heroCard(
    String userEmail,
  ) {
    return Container(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.architecture_rounded,
                  color: Color(0xFF006B55),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMETA TJ ONLINE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                      style: TextStyle(
                        color: Color(
                          0xFF53605C,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),
          const Text(
            '«...БА ФАРЗАНДОНУ НАБЕРАҲОЯМОН '
            'ЯК МУЛКИ ОБОД МЕРОС ГУЗОРЕМ.»',
            style: TextStyle(
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Эмомалӣ Раҳмон',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF006B55),
            ),
          ),
          const SizedBox(height: 18),
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
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4E9E7),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF006B55),
          ),
          const SizedBox(height: 16),
          loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF58635F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4E9E7),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                const Color(0xFFE5F5EF),
            child: Icon(
              icon,
              color: const Color(0xFF006B55),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A7470),
                  ),
                ),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
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
  State<ProjectsPage> createState() =>
      _ProjectsPageState();
}

class _ProjectsPageState
    extends State<ProjectsPage> {
  bool loading = true;
  List<Map<String, dynamic>> projects = [];

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
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        projects =
            List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      notice(
        context,
        'Хатои объектҳо: $e',
      );
    }
  }

  Future<void> addProject() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final customer = TextEditingController();
    final contractor = TextEditingController();
    final engineer = TextEditingController();
    final budget = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Объекти нав',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                appField(
                  name,
                  'Номи объект *',
                ),
                const SizedBox(height: 10),
                appField(
                  address,
                  'Суроға',
                ),
                const SizedBox(height: 10),
                appField(
                  customer,
                  'Фармоишгар',
                ),
                const SizedBox(height: 10),
                appField(
                  contractor,
                  'Пудратчӣ',
                ),
                const SizedBox(height: 10),
                appField(
                  engineer,
                  'Муҳандис',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budget,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Буҷет, сомонӣ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Бекор',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Сабт',
              ),
            ),
          ],
        );
      },
    );

    if (save != true) {
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

    if (projectName.isEmpty) {
      disposeControllers([
        name,
        address,
        customer,
        contractor,
        engineer,
        budget,
      ]);

      if (mounted) {
        notice(
          context,
          'Номи объект ҳатмист.',
        );
      }

      return;
    }

    final row = {
      'user_id': db.auth.currentUser!.id,
      'name': projectName,
      'address': address.text.trim(),
      'customer': customer.text.trim(),
      'contractor':
          contractor.text.trim(),
      'engineer': engineer.text.trim(),
      'budget': double.tryParse(
            budget.text
                .trim()
                .replaceAll(',', '.'),
          ) ??
          0,
      'status': 'active',
    };

    disposeControllers([
      name,
      address,
      customer,
      contractor,
      engineer,
      budget,
    ]);

    try {
      await db
          .from('projects')
          .insert(row);

      await load();

      if (mounted) {
        notice(
          context,
          'Объект сабт шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Хатои сабти объект: $e',
        );
      }
    }
  }

  Future<void> removeProject(
    Map<String, dynamic> project,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Нест кардани объект',
          ),
          content: Text(
            '«${project['name'] ?? ''}» нест карда шавад?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Не',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Нест кардан',
              ),
            ),
          ],
        );
      },
    );

    if (yes != true) return;

    try {
      await db
          .from('projects')
          .delete()
          .eq(
            'id',
            project['id'],
          );

      await load();

      if (mounted) {
        notice(
          context,
          'Объект нест карда шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Нест кардан нашуд: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addProject,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Объекти нав',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: projects.isEmpty
                  ? emptyView(
                      icon: Icons
                          .apartment_outlined,
                      title:
                          'Ҳоло объект нест',
                      subtitle:
                          'Объекти аввалро илова кунед.',
                    )
                  : ListView.separated(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        100,
                      ),
                      itemCount:
                          projects.length,
                      separatorBuilder:
                          (_, __) =>
                              const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (context, index) {
                        final item =
                            projects[index];

                        return Container(
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFE3E9E6,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets
                                    .all(16),
                            leading:
                                const CircleAvatar(
                              backgroundColor:
                                  Color(
                                0xFFE2F4ED,
                              ),
                              child: Icon(
                                Icons
                                    .apartment_rounded,
                                color: Color(
                                  0xFF006B55,
                                ),
                              ),
                            ),
                            title: Text(
                              item['name']
                                      ?.toString() ??
                                  '',
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 6,
                              ),
                              child: Text(
                                '${item['address'] ?? 'Суроға нишон дода нашудааст'}\n'
                                'Фармоишгар: ${item['customer'] ?? '-'}\n'
                                'Муҳандис: ${item['engineer'] ?? '-'}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing:
                                PopupMenuButton<
                                    String>(
                              onSelected:
                                  (value) {
                                if (value ==
                                    'delete') {
                                  removeProject(
                                    item,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) =>
                                      const [
                                PopupMenuItem(
                                  value:
                                      'delete',
                                  child: Text(
                                    'Нест кардан',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// =====================================================
// ESTIMATES
// =====================================================

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() =>
      _EstimatesPageState();
}

class _EstimatesPageState
    extends State<EstimatesPage> {
  bool loading = true;

  List<Map<String, dynamic>> estimates = [];
  List<Map<String, dynamic>> projects = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final estimateData = await db
          .from('estimates')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      final projectData = await db
          .from('projects')
          .select('id,name')
          .order('name');

      if (!mounted) return;

      setState(() {
        estimates =
            List<Map<String, dynamic>>.from(
          estimateData,
        );

        projects =
            List<Map<String, dynamic>>.from(
          projectData,
        );

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      notice(
        context,
        'Хатои сметаҳо: $e',
      );
    }
  }

  String getProjectName(
    dynamic projectId,
  ) {
    for (final item in projects) {
      if (item['id'].toString() ==
          projectId.toString()) {
        return item['name']
                ?.toString() ??
            '-';
      }
    }

    return '-';
  }

  Future<void> addEstimate() async {
    if (projects.isEmpty) {
      notice(
        context,
        'Аввал объект созед.',
      );
      return;
    }

    final title = TextEditingController();

    String? projectId =
        projects.first['id'].toString();

    String type = 'local';

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Сметаи нав',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          projectId,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Объект',
                      ),
                      items:
                          projects.map(
                        (project) {
                          return DropdownMenuItem<
                              String>(
                            value:
                                project['id']
                                    .toString(),
                            child: Text(
                              project['name']
                                      ?.toString() ??
                                  '',
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        setDialogState(
                          () {
                            projectId =
                                value;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    appField(
                      title,
                      'Номи смета *',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: type,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Намуди смета',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'local',
                          child: Text(
                            'Сметаи локалӣ',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'object',
                          child: Text(
                            'Сметаи объектӣ',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'summary',
                          child: Text(
                            'Сметаи ҷамъбастӣ',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(
                          () {
                            type = value;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Бекор',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child: const Text(
                    'Сабт',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) {
      title.dispose();
      return;
    }

    final estimateTitle =
        title.text.trim();

    title.dispose();

    if (estimateTitle.isEmpty ||
        projectId == null) {
      notice(
        context,
        'Номи смета ҳатмист.',
      );
      return;
    }

    try {
      await db
          .from('estimates')
          .insert({
        'user_id':
            db.auth.currentUser!.id,
        'project_id': projectId,
        'title': estimateTitle,
        'estimate_type': type,
        'status': 'draft',
        'subtotal': 0,
        'total': 0,
      });

      await load();

      if (mounted) {
        notice(
          context,
          'Смета сохта шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Хатои сабти смета: $e',
        );
      }
    }
  }

  Future<void> removeEstimate(
    Map<String, dynamic> estimate,
  ) async {
    try {
      await db
          .from('estimates')
          .delete()
          .eq(
            'id',
            estimate['id'],
          );

      await load();

      if (mounted) {
        notice(
          context,
          'Смета нест карда шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Нест кардан нашуд: $e',
        );
      }
    }
  }

  String estimateType(
    dynamic value,
  ) {
    switch (value) {
      case 'object':
        return 'Объектӣ';
      case 'summary':
        return 'Ҷамъбастӣ';
      default:
        return 'Локалӣ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addEstimate,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Сметаи нав',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
    onRefresh: load,
    child: estimates.isEmpty
        ? emptyView(
            icon: Icons.calculate_outlined,
            title: 'Ҳоло смета нест',
            subtitle:
                'Барои объект сметаи нав созед.',
          )
        : ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              100,
            ),
            itemCount: estimates.length,
            separatorBuilder: (_, __) =>
                const SizedBox(
              height: 10,
            ),
            itemBuilder: (context, index) {
              final item = estimates[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        const Color(0xFFE3E9E6),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE2F4ED),
                    child: Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF006B55),
                    ),
                  ),
                  title: Text(
                    item['title']?.toString() ??
                        '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Text(
                      'Объект: ${getProjectName(item['project_id'])}\n'
                      'Навъ: ${estimateType(item['estimate_type'])}',
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item['total'] ?? 0}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'сомонӣ',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  onLongPress: () {
                    removeEstimate(item);
                  },
                ),
              );
            },
          ),
  ),
);
  }
}
// =====================================================
// STANDARDS
// =====================================================

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() =>
      _StandardsPageState();
}

class _StandardsPageState
    extends State<StandardsPage> {
  bool loading = true;

  List<Map<String, dynamic>> standards = [];
  List<Map<String, dynamic>> filtered = [];

  final searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('construction_standards')
          .select()
          .order(
            'code',
            ascending: true,
          );

      if (!mounted) return;

      final rows =
          List<Map<String, dynamic>>.from(
        data,
      );

      setState(() {
        standards = rows;
        filtered = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      notice(
        context,
        'Хатои меъёрҳо: $e',
      );
    }
  }

  void search(String value) {
    final query =
        value.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filtered = standards;
      });
      return;
    }

    setState(() {
      filtered = standards.where((item) {
        final code =
            item['code']
                ?.toString()
                .toLowerCase() ??
            '';

        final title =
            item['title']
                ?.toString()
                .toLowerCase() ??
            '';

        final type =
            item['document_type']
                ?.toString()
                .toLowerCase() ??
            '';

        return code.contains(query) ||
            title.contains(query) ||
            type.contains(query);
      }).toList();
    });
  }

  String textOrDash(dynamic value) {
    final text =
        value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return '-';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent,
      body: RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  30,
                ),
                children: [
                  TextField(
                    controller:
                        searchController,
                    onChanged: search,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Ҷустуҷӯи МҚС, ҚМҚ ё ном...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon: Icon(
                        Icons
                            .manage_search_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEAF5F1,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Icon(
                          Icons
                              .verified_user_outlined,
                          color: Color(
                            0xFF006B55,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ин бахш барои меъёрҳои сохтмонӣ, '
                            'МҚС, ҚМҚ ва дигар ҳуҷҷатҳои меъёрӣ пешбинӣ шудааст.',
                            style:
                                TextStyle(
                              height: 1.4,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 80,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons
                                .menu_book_outlined,
                            size: 66,
                            color: Color(
                              0xFF8B9692,
                            ),
                          ),
                          SizedBox(
                            height: 14,
                          ),
                          Text(
                            'Меъёр ёфт нашуд',
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(
                      (item) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .all(
                              16,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFE3E9E6,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor:
                                          Color(
                                        0xFFE2F4ED,
                                      ),
                                      child:
                                          Icon(
                                        Icons
                                            .menu_book_rounded,
                                        color:
                                            Color(
                                          0xFF006B55,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            textOrDash(
                                              item[
                                                  'code'],
                                            ),
                                            style:
                                                const TextStyle(
                                              color:
                                                  Color(
                                                0xFF006B55,
                                              ),
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                              fontSize:
                                                  15,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            textOrDash(
                                              item[
                                                  'title'],
                                            ),
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  16,
                                              height:
                                                  1.3,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                const Divider(),
                                const SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          _standardInfo(
                                        'Навъ',
                                        textOrDash(
                                          item[
                                              'document_type'],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child:
                                          _standardInfo(
                                        'Сол',
                                        textOrDash(
                                          item[
                                              'edition_year'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _standardInfo(
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF5F8F7),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(
                0xFF73807B,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HELPERS
// =====================================================

Widget appField(
  TextEditingController controller,
  String label,
) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
    ),
  );
}

void disposeControllers(
  List<TextEditingController> controllers,
) {
  for (final controller in controllers) {
    controller.dispose();
  }
}

Widget emptyView({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return ListView(
    physics:
        const AlwaysScrollableScrollPhysics(),
    padding:
        const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 110),
      Icon(
        icon,
        size: 72,
        color:
            const Color(0xFF7B8883),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          title,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          subtitle,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color:
                Color(0xFF6A7470),
          ),
        ),
      ),
    ],
  );
}