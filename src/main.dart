import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

const primary = Color(0xFF006B55);

SupabaseClient get db => Supabase.instance.client;
String get uid => db.auth.currentUser?.id ?? '';

double d(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? 0;
}

String money(double v) => '${v.toStringAsFixed(2)} сом.';
String qty(double v) => v.toStringAsFixed(2);

void msg(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const SmetaTjApp());
}

// ============================================================
// APP
// ============================================================

class SmetaTjApp extends StatelessWidget {
  const SmetaTjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMETA TJ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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

  bool register = false;
  bool busy = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      msg(context, 'Email ва рамзи на кам аз 6 аломат ворид кунед.');
      return;
    }

    setState(() => busy = true);

    try {
      if (register) {
        await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: 'tj.smetatj.app://login-callback/',
        );

        if (mounted) {
          msg(context, 'Барои тасдиқи ҳисоб Email-ро санҷед.');
        }
      } else {
        await db.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) msg(context, '$e');
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
                  size: 82,
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
                const Text('Ёрдамчии рақамии сохтмон'),
                const SizedBox(height: 28),
                TextField(
                  controller: email,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      register ? 'Сабти ном' : 'Ворид шудан',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => register = !register),
                  child: Text(
                    register ? 'Ҳисоб дорам' : 'Ҳисоби нав',
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
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  final titles = const [
    'Асосӣ',
    'Ҳисоби сохтмон',
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

  final icons = const [
    Icons.home,
    Icons.calculate,
    Icons.apartment,
    Icons.receipt_long,
    Icons.menu_book,
    Icons.payments,
    Icons.description,
    Icons.fact_check,
    Icons.cloud_sync,
    Icons.storefront,
    Icons.auto_awesome,
  ];

  Widget currentPage() {
    switch (page) {
      case 0:
        return Dashboard(
          openPage: (i) => setState(() => page = i),
        );

      case 1:
        return const ConstructionCalculator();

      case 2:
        return const SimpleTablePage(
          table: 'projects',
          titleField: 'name',
          fields: ['address', 'status', 'budget'],
        );

      case 3:
        return const SimpleTablePage(
          table: 'estimates',
          titleField: 'title',
          fields: ['estimate_type', 'status', 'total'],
        );

      case 4:
        return const StandardsPage();

      case 5:
        return const PricesPage();

      case 6:
        return const SimpleTablePage(
          table: 'documents',
          titleField: 'title',
          fields: ['document_type', 'status'],
        );

      case 7:
        return const SimpleTablePage(
          table: 'technical_inspections',
          titleField: 'title',
          fields: ['category', 'result'],
        );

      case 8:
        return const SyncPage();

      case 9:
        return const SimpleTablePage(
          table: 'marketplace_products',
          titleField: 'name',
          fields: ['category', 'unit', 'price', 'region'],
        );

      default:
        return const AiPage();
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMETA TJ',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: primary,
                      ),
                    ),
                    Text('Construction Assistant 2.1'),
                  ],
                ),
              ),
              for (int i = 0; i < titles.length; i++)
                ListTile(
                  selected: page == i,
                  leading: Icon(icons[i]),
                  title: Text(titles[i]),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => page = i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: currentPage(),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatelessWidget {
  final ValueChanged<int> openPage;

  const Dashboard({
    super.key,
    required this.openPage,
  });

  Widget card(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: primary.withValues(alpha: .10),
          child: Icon(icon, color: primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 17),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ҲИСОБ КУНЕД',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Пеш аз хариди масолеҳ миқдор ва арзиши сохтмонро ҳисоб кунед.',
        ),
        const SizedBox(height: 18),

        card(
          'Хонаамро ҳисоб кун',
          'Масоҳат • девор • фундамент • блок • бетон • бом',
          Icons.home_work,
          () => openPage(1),
        ),

        card(
          'Сметаи касбӣ',
          'Натиҷаҳои ҳисоб ва сметаҳои объект',
          Icons.engineering,
          () => openPage(3),
        ),

        card(
          'Меъёрҳои сохтмонӣ',
          'Меъёр → боб → § / пункт',
          Icons.menu_book,
          () => openPage(4),
        ),

        card(
          'Нархҳо',
          'Нархномаи масолеҳ ва корҳои сохтмонӣ',
          Icons.payments,
          () => openPage(5),
        ),

        const SizedBox(height: 12),

        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: primary),
                SizedBox(height: 8),
                Text(
                  'Ҳисоби бехатар',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Ҳисоб пешакӣ мебошад. Андоза ва арматураи '
                  'конструксияҳои борбардор бояд аз рӯи лоиҳаи '
                  'муҳандисӣ тасдиқ карда шаванд.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CALCULATOR
// ============================================================

class CalcItem {
  final String category;
  final String materialCode;
  final String name;
  final String unit;
  final double quantity;
  final double? price;
  final String note;

  const CalcItem({
    required this.category,
    required this.materialCode,
    required this.name,
    required this.unit,
    required this.quantity,
    this.price,
    this.note = '',
  });

  double? get total => price == null ? null : quantity * price!;
}

class ConstructionCalculator extends StatefulWidget {
  const ConstructionCalculator({super.key});

  @override
  State<ConstructionCalculator> createState() =>
      _ConstructionCalculatorState();
}

class _ConstructionCalculatorState extends State<ConstructionCalculator> {
  final title = TextEditingController(text: 'Хонаи ман');
  final length = TextEditingController(text: '10');
  final width = TextEditingController(text: '12');
  final height = TextEditingController(text: '3');
  final floors = TextEditingController(text: '1');

  final openings = TextEditingController(text: '20');
  final internalLength = TextEditingController(text: '20');

  final wallThickness = TextEditingController(text: '0.20');

  final foundationWidth = TextEditingController(text: '0.40');
  final foundationHeight = TextEditingController(text: '0.80');

  final waste = TextEditingController(text: '5');

  String wallMaterial = 'Газоблок 600×300×200';
  String foundation = 'Лентагӣ';
  String roof = 'Душатра';

  bool busy = false;
  List<CalcItem> results = [];
  Map<String, double> geometry = {};

  double get L => d(length.text);
  double get W => d(width.text);
  double get H => d(height.text);
  double get F => math.max(1, d(floors.text));
  double get wasteFactor => 1 + d(waste.text) / 100;

  Future<Map<String, Map<String, dynamic>>> loadPrices() async {
    final Map<String, Map<String, dynamic>> out = {};

    try {
      final rows = await db
          .from('latest_material_prices')
          .select()
          .eq('region', 'Душанбе');

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final code = '${row['material_code'] ?? ''}';

        if (code.isNotEmpty) {
          out[code] = row;
        }
      }
    } catch (_) {}

    return out;
  }

  Future<void> calculate() async {
    if (L <= 0 || W <= 0 || H <= 0) {
      msg(context, 'Дарозӣ, бар ва баландиро дуруст ворид кунед.');
      return;
    }

    setState(() => busy = true);

    try {
      final priceMap = await loadPrices();

      final footprint = L * W;
      final floorArea = footprint * F;
      final perimeter = 2 * (L + W);

      final grossExterior = perimeter * H * F;
      final netExterior =
          math.max(0.0, grossExterior - d(openings.text));

      final internalOneSide = d(internalLength.text) * H * F;
      final internalFinish = internalOneSide * 2;

      final wallVolume =
          (netExterior + internalOneSide) * d(wallThickness.text);

      final foundationVolume = foundation == 'Плита'
          ? footprint * d(foundationHeight.text)
          : perimeter *
              d(foundationWidth.text) *
              d(foundationHeight.text);

      final roofArea = roof == 'Ҳамвор'
          ? footprint
          : roof == 'Душатра'
              ? footprint * 1.15
              : footprint * 1.20;

      String wallCode;
      double wallQty;
      String wallUnit;

      if (wallMaterial == 'Газоблок 600×300×200') {
        wallCode = 'AAC-600-300-200';
        wallQty = wallVolume / (0.60 * 0.30 * 0.20) * wasteFactor;
        wallUnit = 'дона';
      } else if (wallMaterial == 'Газоблок 600×250×200') {
        wallCode = 'AAC-600-250-200';
        wallQty = wallVolume / (0.60 * 0.25 * 0.20) * wasteFactor;
        wallUnit = 'дона';
      } else {
        wallCode = 'BRICK-250-120-65';

        // Ҳисоби пешакии геометрӣ.
        // Коэффисиенти маҳлул дар ин ҳисоб ҳамчун меъёри расмӣ
        // пешниҳод намешавад.
        wallQty = wallVolume / (0.25 * 0.12 * 0.065) * wasteFactor;
        wallUnit = 'дона';
      }

      double? priceFor(String code) {
        final row = priceMap[code];
        if (row == null) return null;

        final p = d(row['price']);
        return p > 0 ? p : null;
      }

      results = [
        CalcItem(
          category: 'Девор',
          materialCode: wallCode,
          name: wallMaterial,
          unit: wallUnit,
          quantity: wallQty,
          price: priceFor(wallCode),
          note: 'Ҳисоби геометрӣ + ${waste.text}% захира',
        ),
        CalcItem(
          category: 'Фундамент',
          materialCode: 'CONCRETE',
          name: 'Бетон',
          unit: 'м³',
          quantity: foundationVolume * 1.03,
          price: priceFor('CONCRETE'),
          note: 'Ҳаҷми пешакии бетон. Андозаи фундамент аз лоиҳа.',
        ),
        CalcItem(
          category: 'Бом',
          materialCode: '',
          name: 'Масоҳати бом',
          unit: 'м²',
          quantity: roofArea * wasteFactor,
          price: null,
          note: 'Барои нархи бом навъи рӯйпӯш интихоб карда мешавад.',
        ),
        CalcItem(
          category: 'Ороиш',
          materialCode: '',
          name: 'Масоҳати сатҳи ороиш',
          unit: 'м²',
          quantity: (netExterior + internalFinish) * wasteFactor,
          price: null,
          note:
              'Миқдори кг/л танҳо баъди интихоби рецепти тасдиқшуда ҳисоб мешавад.',
        ),
      ];

      geometry = {
        'Масоҳати сохтмон': footprint,
        'Масоҳати умумии ошёнаҳо': floorArea,
        'Периметр': perimeter,
        'Девори берунии соф': netExterior,
        'Девори дохилӣ (як тараф)': internalOneSide,
        'Ҳаҷми умумии девор': wallVolume,
        'Ҳаҷми фундамент': foundationVolume,
        'Масоҳати бом': roofArea,
      };

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) msg(context, 'Хатои ҳисоб: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  double get pricedTotal {
    double total = 0;

    for (final item in results) {
      if (item.total != null) total += item.total!;
    }

    return total;
  }

  Future<void> saveCalculation() async {
    if (results.isEmpty) {
      msg(context, 'Аввал ҳисобро иҷро кунед.');
      return;
    }

    setState(() => busy = true);

    try {
      final calc = await db
          .from('building_calculations')
          .insert({
            'user_id': uid,
            'title': title.text.trim().isEmpty
                ? 'Ҳисоби сохтмон'
                : title.text.trim(),
            'building_type': 'Хонаи истиқоматӣ',
            'dimensions': {
              'length': L,
              'width': W,
              'height': H,
              'floors': F,
            },
            'materials': {
              'wall_material': wallMaterial,
              'wall_thickness': d(wallThickness.text),
            },
            'foundation': {
              'type': foundation,
              'width': d(foundationWidth.text),
              'height': d(foundationHeight.text),
            },
            'roof': {'type': roof},
            'finish': {},
            'waste': d(waste.text),
            'geometry': geometry,
            'estimated_total': pricedTotal,
            'material_total': pricedTotal,
            'grand_total': pricedTotal,
            'region': 'Душанбе',
            'price_mode': 'database',
            'calculation_status': 'calculated',
          })
          .select('id')
          .single();

      final calculationId = calc['id'];

      final rows = results
          .map(
            (x) => {
              'user_id': uid,
              'calculation_id': calculationId,
              'category': x.category,
              'material_name': x.name,
              'unit': x.unit,
              'quantity': x.quantity,
              'unit_price': x.price ?? 0,
              'total_price': x.total ?? 0,
              'note': x.note,
              'result_type': 'material',
              'is_preliminary': true,
            },
          )
          .toList();

      await db.from('calculation_results').insert(rows);

      if (mounted) {
        msg(context, 'Ҳисоб бомуваффақият захира шуд.');
      }
    } catch (e) {
      if (mounted) msg(context, 'Захира нашуд: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createEstimate() async {
    if (results.isEmpty) {
      msg(context, 'Аввал ҳисобро иҷро кунед.');
      return;
    }

    setState(() => busy = true);

    try {
      final estimate = await db
          .from('estimates')
          .insert({
            'user_id': uid,
            'title': 'Смета — ${title.text.trim()}',
            'estimate_type': 'Ҳисоби автоматӣ',
            'status': 'Пешакӣ',
            'subtotal': pricedTotal,
            'total': pricedTotal,
          })
          .select('id')
          .single();

      final estimateId = estimate['id'];

      final items = results
          .map(
            (x) => {
              'user_id': uid,
              'estimate_id': estimateId,
              'work_name': x.name,
              'unit': x.unit,
              'quantity': x.quantity,
              'unit_price': x.price ?? 0,
              'coefficient': 1,
              'total_price': x.total ?? 0,
              'category': x.category,
            },
          )
          .toList();

      await db.from('estimate_items').insert(items);

      if (mounted) {
        msg(context, 'Смета сохта шуд.');
      }
    } catch (e) {
      if (mounted) msg(context, 'Смета сохта нашуд: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(
    String label,
    TextEditingController controller, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
        ),
      ),
    );
  }

  Widget section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        section(
          '1. Андозаи бино',
          [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Номи ҳисоб',
              ),
            ),
            const SizedBox(height: 10),
            input('Дарозӣ', length, suffix: 'м'),
            input('Бар', width, suffix: 'м'),
            input('Баландии ошёна', height, suffix: 'м'),
            input('Шумораи ошёна', floors),
          ],
        ),

        section(
          '2. Деворҳо',
          [
            DropdownButtonFormField<String>(
              initialValue: wallMaterial,
              decoration: const InputDecoration(
                labelText: 'Маводи девор',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Газоблок 600×300×200',
                  child: Text('Газоблок 600×300×200'),
                ),
                DropdownMenuItem(
                  value: 'Газоблок 600×250×200',
                  child: Text('Газоблок 600×250×200'),
                ),
                DropdownMenuItem(
                  value: 'Хишти сафолӣ 250×120×65',
                  child: Text('Хишти сафолӣ 250×120×65'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => wallMaterial = v);
              },
            ),
            const SizedBox(height: 10),
            input(
              'Ғафсии девор',
              wallThickness,
              suffix: 'м',
            ),
            input(
              'Масоҳати умумии дару тиреза',
              openings,
              suffix: 'м²',
            ),
            input(
              'Дарозии умумии деворҳои дохилӣ',
              internalLength,
              suffix: 'м',
            ),
          ],
        ),

        section(
          '3. Фундамент',
          [
            DropdownButtonFormField<String>(
              initialValue: foundation,
              decoration: const InputDecoration(
                labelText: 'Навъи фундамент',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Лентагӣ',
                  child: Text('Лентагӣ'),
                ),
                DropdownMenuItem(
                  value: 'Плита',
                  child: Text('Плита'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => foundation = v);
              },
            ),
            const SizedBox(height: 10),
            input(
              'Бари фундамент',
              foundationWidth,
              suffix: 'м',
            ),
            input(
              'Баландӣ / ғафсӣ',
              foundationHeight,
              suffix: 'м',
            ),
            const Text(
              'Эзоҳ: андозаи фундаментро SMETA TJ ҳамчун '
              'ҳисоби конструктивии тайёр таъин намекунад.',
            ),
          ],
        ),

        section(
          '4. Бом ва захира',
          [
            DropdownButtonFormField<String>(
              initialValue: roof,
              decoration: const InputDecoration(
                labelText: 'Навъи бом',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Ҳамвор',
                  child: Text('Ҳамвор'),
                ),
                DropdownMenuItem(
                  value: 'Душатра',
                  child: Text('Душатра'),
                ),
                DropdownMenuItem(
                  value: 'Чоршатра',
                  child: Text('Чоршатра'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => roof = v);
              },
            ),
            const SizedBox(height: 10),
            input(
              'Захираи масолеҳ',
              waste,
              suffix: '%',
            ),
          ],
        ),

        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: busy ? null : calculate,
            icon: const Icon(Icons.calculate),
            label: Text(
              busy ? 'Ҳисоб шуда истодааст...' : 'ҲИСОБ КУН',
            ),
          ),
        ),

        if (geometry.isNotEmpty) ...[
          const SizedBox(height: 16),

          section(
            'Геометрияи бино',
            geometry.entries
                .map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: Text(
                      qty(e.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          section(
            'Масолеҳ ва арзиш',
            [
              for (final x in results)
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${qty(x.quantity)} ${x.unit}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          x.price == null
                              ? 'Нарх ворид нашудааст'
                              : '${money(x.price!)} / ${x.unit}',
                          style: TextStyle(
                            color: x.price == null
                                ? Colors.orange.shade900
                                : primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (x.total != null)
                          Text(
                            'Ҷамъ: ${money(x.total!)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (x.note.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            x.note,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const Divider(),

              Text(
                'АРЗИШИ МАВОДИ НАРХДОР: ${money(pricedTotal)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: busy ? null : saveCalculation,
                icon: const Icon(Icons.save),
                label: const Text('Захира кун'),
              ),

              FilledButton.icon(
                onPressed: busy ? null : createEstimate,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Смета соз'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ============================================================
// STANDARDS
// ============================================================

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage> {
  final search = TextEditingController();

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
    search.addListener(() => setState(() {}));
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('construction_standards')
          .select()
          .order('code');

      rows = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();

    final filtered = rows.where((x) {
      final text =
          '${x['code']} ${x['title']} ${x['status']} ${x['notes']}'
              .toLowerCase();

      return q.isEmpty || text.contains(q);
    }).toList();

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Ҷустуҷӯи меъёр',
              hintText: 'Масалан: бетон, бом, сӯхтор...',
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final x = filtered[i];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const CircleAvatar(
                      child: Icon(Icons.menu_book),
                    ),
                    title: Text(
                      '${x['code'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${x['title'] ?? ''}'),
                        const SizedBox(height: 5),
                        Text(
                          '${x['status'] ?? ''}',
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StandardDetailPage(
                            standard: x,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StandardDetailPage extends StatefulWidget {
  final Map<String, dynamic> standard;

  const StandardDetailPage({
    super.key,
    required this.standard,
  });

  @override
  State<StandardDetailPage> createState() =>
      _StandardDetailPageState();
}

class _StandardDetailPageState extends State<StandardDetailPage> {
  final search = TextEditingController();

  bool loading = true;
  String? error;

  List<Map<String, dynamic>> sections = [];

  @override
  void initState() {
    super.initState();
    load();
    search.addListener(() => setState(() {}));
  }

  Future<void> load() async {
    try {
      final data = await db
          .from('standard_sections')
          .select()
          .eq('standard_id', widget.standard['id'])
          .order('sort_order');

      sections = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();

    final filtered = sections.where((x) {
      final text =
          '${x['section_number']} ${x['title']} '
                  '${x['content']} ${x['keywords']}'
              .toLowerCase();

      return q.isEmpty || text.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.standard['code'] ?? 'Меъёр'}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.standard['code'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${widget.standard['title'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ҳолат: ${widget.standard['status'] ?? '—'}',
                  ),
                  Text(
                    'Сол: ${widget.standard['edition_year'] ?? '—'}',
                  ),
                  if ('${widget.standard['notes'] ?? ''}'.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('${widget.standard['notes']}'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Ҷустуҷӯ дар боб ва пунктҳо',
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Бобҳо ва § / пунктҳо',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Text(error!)
          else if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Барои ин меъёр ҳоло боб ё пункт дар база ворид нашудааст.',
                ),
              ),
            )
          else
            for (final x in filtered)
              Card(
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.article_outlined,
                    color: primary,
                  ),
                  title: Text(
                    '${x['section_number'] ?? ''} — '
                    '${x['title'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${x['content'] ?? 'Шарҳ ворид нашудааст.'}',
                      ),
                    ),
                    if ('${x['keywords'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Калимаҳои калидӣ: ${x['keywords']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

          const SizedBox(height: 20),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'SMETA TJ шарҳи кӯтоҳ ва сохтори меъёрро нишон медиҳад. '
                'Барои истифодаи ҳуқуқӣ ва лоиҳавӣ матни расмии '
                'санад бояд санҷида шавад.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRICES
// ============================================================

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await db
          .from('prices')
          .select()
          .order('price_date', ascending: false);

      rows = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> addPrice() async {
    final name = TextEditingController();
    final unit = TextEditingController();
    final price = TextEditingController();
    final region = TextEditingController(text: 'Душанбе');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нархи нав'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Номи масолеҳ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: unit,
                decoration: const InputDecoration(
                  labelText: 'Воҳид',
                  hintText: 'дона / кг / м³',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Нарх',
                  suffixText: 'сом.',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: region,
                decoration: const InputDecoration(
                  labelText: 'Минтақа',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бекор'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Захира'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (name.text.trim().isEmpty || d(price.text) <= 0) {
      if (mounted) msg(context, 'Ном ва нархро дуруст ворид кунед.');
      return;
    }

    try {
      await db.from('prices').insert({
        'owner_user_id': uid,
        'name': name.text.trim(),
        'unit': unit.text.trim(),
        'price': d(price.text),
        'currency': 'TJS',
        'region': region.text.trim(),
        'price_type': 'user',
        'is_official': false,
        'is_active': true,
        'price_date': DateTime.now().toIso8601String().substring(0, 10),
      });

      await load();

      if (mounted) msg(context, 'Нарх захира шуд.');
    } catch (e) {
      if (mounted) msg(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FilledButton.icon(
            onPressed: addPrice,
            icon: const Icon(Icons.add),
            label: const Text('НАРХ ИЛОВА КУН'),
          ),

          const SizedBox(height: 14),

          if (rows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Нархнома ҳоло холӣ аст. '
                  'Нархҳои воқеиро ворид кунед.',
                ),
              ),
            ),

          for (final x in rows)
            Card(
              child: ListTile(
                title: Text(
                  '${x['name'] ?? 'Масолеҳ'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${x['region'] ?? '—'} • '
                  '${x['price_date'] ?? '—'}',
                ),
                trailing: Text(
                  '${d(x['price']).toStringAsFixed(2)} '
                  '${x['currency'] ?? 'TJS'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: primary,
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
// GENERIC DATABASE LIST
// ============================================================

class SimpleTablePage extends StatefulWidget {
  final String table;
  final String titleField;
  final List<String> fields;

  const SimpleTablePage({
    super.key,
    required this.table,
    required this.titleField,
    required this.fields,
  });

  @override
  State<SimpleTablePage> createState() => _SimpleTablePageState();
}

class _SimpleTablePageState extends State<SimpleTablePage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await db
          .from(widget.table)
          .select()
          .order('created_at', ascending: false);

      rows = List<Map<String, dynamic>>.from(data);
      error = null;
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error!),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (rows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Маълумот ҳоло нест.'),
              ),
            ),

          for (final row in rows)
            Card(
              child: ListTile(
                title: Text(
                  '${row[widget.titleField] ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in widget.fields)
                      if (row[f] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text('$f: ${row[f]}'),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SYNC
// ============================================================

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool busy = false;
  String status = 'Омода';

  Future<void> check() async {
    setState(() {
      busy = true;
      status = 'Санҷиш...';
    });

    try {
      final projects = await db.from('projects').select('id');
      final materials = await db.from('material_catalog').select('id');
      final standards =
          await db.from('construction_standards').select('id');
      final sections =
          await db.from('standard_sections').select('id');

      status =
          'Online ✓\n'
          'Объектҳо: ${projects.length}\n'
          'Масолеҳ: ${materials.length}\n'
          'Меъёрҳо: ${standards.length}\n'
          'Боб/пунктҳо: ${sections.length}';
    } catch (e) {
      status = 'Хато: $e';
    }

    if (mounted) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_done,
                  size: 70,
                  color: primary,
                ),
                const SizedBox(height: 15),
                const Text(
                  'SMETA TJ ONLINE',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  status,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: busy ? null : check,
                  icon: const Icon(Icons.sync),
                  label: const Text('САНҶИШИ ONLINE'),
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
// AI DATABASE ASSISTANT
// ============================================================

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final question = TextEditingController();

  bool busy = false;
  String answer =
      'Саволро оид ба масолеҳ ё меъёрҳои сохтмонӣ ворид кунед.';

  Future<void> ask() async {
    final q = question.text.trim();

    if (q.isEmpty) return;

    setState(() => busy = true);

    try {
      final standards = await db
          .from('construction_standards')
          .select()
          .or('code.ilike.%$q%,title.ilike.%$q%')
          .limit(5);

      final sections = await db
          .from('standard_sections')
          .select()
          .or(
            'title.ilike.%$q%,content.ilike.%$q%,keywords.ilike.%$q%',
          )
          .limit(8);

      final materials = await db
          .from('material_catalog')
          .select()
          .ilike('name', '%$q%')
          .limit(5);

      final buffer = StringBuffer();

      if (standards.isNotEmpty) {
        buffer.writeln('МЕЪЁРҲО:');

        for (final x in standards) {
          buffer.writeln(
            '• ${x['code']} — ${x['title']}',
          );
        }
      }

      if (sections.isNotEmpty) {
        buffer.writeln('\nБОБ / ПУНКТҲО:');

        for (final x in sections) {
          buffer.writeln(
            '• ${x['section_number']} — ${x['title']}',
          );
        }
      }

      if (materials.isNotEmpty) {
        buffer.writeln('\nМАСОЛЕҲ:');

        for (final x in materials) {
          buffer.writeln(
            '• ${x['name']} — ${x['unit']}',
          );
        }
      }

      if (buffer.isEmpty) {
        buffer.write(
          'Дар база маълумоти мувофиқ ёфт нашуд.',
        );
      }

      answer = buffer.toString();

      try {
        await db.from('ai_history').insert({
          'user_id': uid,
          'question': q,
          'answer': answer,
          'ai_mode': 'database-search',
        });
      } catch (_) {}
    } catch (e) {
      answer = 'Хато: $e';
    }

    if (mounted) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'AI SMETA TJ ҳоло маълумоти базаи сохтмониро '
              'ҷустуҷӯ мекунад. Ин ҳоло AI-и генеративӣ нест.',
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: question,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Савол',
            hintText: 'Масалан: бетон, бом, сӯхтор...',
          ),
        ),

        const SizedBox(height: 12),

        FilledButton.icon(
          onPressed: busy ? null : ask,
          icon: const Icon(Icons.auto_awesome),
          label: Text(
            busy ? 'Ҷустуҷӯ...' : 'ПУРСЕД',
          ),
        ),

        const SizedBox(height: 15),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SelectableText(answer),
          ),
        ),
      ],
    );
  }
}
