import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
const redirectUrl = 'tj.smetatj.app://login-callback/';

SupabaseClient get supabase => Supabase.instance.client;

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

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

// ======================================================
// AUTH
// ======================================================

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

        return const MainPage();
      },
    );
  }
}

// ======================================================
// LOGIN / REGISTER
// ======================================================

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMsg(context, 'Email-ро ворид кунед.');
      return;
    }

    if (password.length < 6) {
      showMsg(
        context,
        'Рамз бояд на камтар аз 6 аломат бошад.',
      );
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
          emailRedirectTo: redirectUrl,
        );

        if (mounted) {
          showMsg(
            context,
            'Ҳисоб сохта шуд. Email-ро тасдиқ кунед.',
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
        showMsg(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showMsg(context, 'Хато: $e');
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
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
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
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: loading ? null : submit,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  registerMode
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
                                setState(() {
                                  registerMode = !registerMode;
                                });
                              },
                        child: Text(
                          registerMode
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

// ======================================================
// MAIN
// ======================================================

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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          index == 0 ? 'SMETA TJ' : 'Объектҳо',
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
      body: IndexedStack(
        index: index,
        children: pages,
      ),
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
            label: 'Объектҳо',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// DASHBOARD
// ======================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int projectCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await supabase
          .from('projects')
          .select('id');

      if (!mounted) return;

      setState(() {
        projectCount = data.length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMsg(context, 'Хато: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        supabase.auth.currentUser?.email ?? '';

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
                  const SizedBox(height: 8),
                  const Text(
                    'Сохтмон бо ҳисоб. Сохтмон бо меъёр.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Эмомалӣ Раҳмон',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.apartment),
              ),
              title: const Text(
                'Объектҳо',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '$projectCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
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

// ======================================================
// PROJECTS
// ======================================================

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() =>
      _ProjectsPageState();
}

class _ProjectsPageState
    extends State<ProjectsPage> {
  List<Map<String, dynamic>> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await supabase
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

      showMsg(context, 'Хато: $e');
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
          title: const Text('Объекти нав'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                input(name, 'Номи объект *'),
                const SizedBox(height: 10),
                input(address, 'Суроға'),
                const SizedBox(height: 10),
                input(customer, 'Фармоишгар'),
                const SizedBox(height: 10),
                input(contractor, 'Пудратчӣ'),
                const SizedBox(height: 10),
                input(engineer, 'Муҳандис'),
                const SizedBox(height: 10),
                TextField(
                  controller: budget,
                  keyboardType:
                      const TextInputType.numberWithOptions(
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
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Бекор'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Сабт'),
            ),
          ],
        );
      },
    );

    if (save != true) {
      disposeAll([
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
      disposeAll([
        name,
        address,
        customer,
        contractor,
        engineer,
        budget,
      ]);

      if (mounted) {
        showMsg(
          context,
          'Номи объект ҳатмист.',
        );
      }

      return;
    }

    final data = {
      'user_id':
          supabase.auth.currentUser!.id,
      'name': projectName,
      'address': address.text.trim(),
      'customer': customer.text.trim(),
      'contractor': contractor.text.trim(),
      'engineer': engineer.text.trim(),
      'budget': double.tryParse(
            budget.text
                .trim()
                .replaceAll(',', '.'),
          ) ??
          0,
      'status': 'active',
    };

    disposeAll([
      name,
      address,
      customer,
      contractor,
      engineer,
      budget,
    ]);

    try {
      await supabase
          .from('projects')
          .insert(data);

      await load();

      if (mounted) {
        showMsg(
          context,
          'Объект сабт шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMsg(context, 'Хато: $e');
      }
    }
  }

  Future<void> deleteProject(
    String id,
  ) async {
    try {
      await supabase
          .from('projects')
          .delete()
          .eq('id', id);

      await load();

      if (mounted) {
        showMsg(
          context,
          'Объект нест карда шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMsg(context, 'Хато: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addProject,
        icon: const Icon(Icons.add),
        label: const Text('Объекти нав'),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: projects.isEmpty
                  ? emptyProjects()
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        90,
                      ),
                      itemCount:
                          projects.length,
                      itemBuilder:
                          (context, index) {
                        final item =
                            projects[index];

                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.apartment,
                              ),
                            ),
                            title: Text(
                              item['name']
                                      ?.toString() ??
                                  '',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Суроға: ${item['address'] ?? '-'}\n'
                              'Фармоишгар: ${item['customer'] ?? '-'}\n'
                              'Пудратчӣ: ${item['contractor'] ?? '-'}\n'
                              'Муҳандис: ${item['engineer'] ?? '-'}\n'
                              'Буҷет: ${item['budget'] ?? 0} сомонӣ',
                            ),
                            trailing:
                                PopupMenuButton<String>(
                              onSelected:
                                  (value) {
                                if (value ==
                                    'delete') {
                                  deleteProject(
                                    item['id']
                                        .toString(),
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) {
                                return const [
                                  PopupMenuItem<
                                      String>(
                                    value:
                                        'delete',
                                    child: Text(
                                      'Нест кардан',
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ======================================================
// HELPERS
// ======================================================

Widget input(
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

void disposeAll(
  List<TextEditingController> controllers,
) {
  for (final controller in controllers) {
    controller.dispose();
  }
}

Widget emptyProjects() {
  return ListView(
    physics:
        const AlwaysScrollableScrollPhysics(),
    children: const [
      SizedBox(height: 120),
      Icon(
        Icons.apartment_outlined,
        size: 72,
      ),
      SizedBox(height: 16),
      Center(
        child: Text(
          'Ҳоло объект нест',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}