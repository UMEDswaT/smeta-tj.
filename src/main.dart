import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

const primary = Color(0xFF006B55);

SupabaseClient get db => Supabase.instance.client;
String get uid => db.auth.currentUser?.id ?? '';

double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(
        '${value ?? ''}'.trim().replaceAll(',', '.'),
      ) ??
      0;
}

String number(double value, [int digits = 2]) {
  return value.toStringAsFixed(digits);
}

void showMessage(BuildContext context, String text) {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
        ),
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
      showMessage(
        context,
        'Email ва рамзи на кам аз 6 аломат ворид кунед.',
      );
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
          showMessage(
            context,
            'Барои тасдиқи ҳисоб Email-ро санҷед.',
          );
        }
      } else {
        await db.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        showMessage(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
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
                  'Ёрдамчии рақамии сохтмон',
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
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
                      register ? 'Сабти ном' : 'Ворид шудан',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => register = !register);
                        },
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
          openPage: (index) {
            setState(() => page = index);
          },
        );

      case 1:
        return const ConstructionCalculator();

      case 2:
        return const DatabaseListPage(
          table: 'projects',
          titleField: 'name',
          fields: [
            'address',
            'status',
            'budget',
          ],
        );

      case 3:
        return const DatabaseListPage(
          table: 'estimates',
          titleField: 'title',
          fields: [
            'estimate_type',
            'status',
            'total',
          ],
        );

      case 4:
        return const StandardsPage();

      case 5:
        return const DatabaseListPage(
          table: 'prices',
          titleField: 'name',
          fields: [
            'category',
            'unit',
            'price',
            'region',
          ],
        );

      case 6:
        return const DatabaseListPage(
          table: 'documents',
          titleField: 'title',
          fields: [
            'document_type',
            'status',
          ],
        );

      case 7:
        return const DatabaseListPage(
          table: 'technical_inspections',
          titleField: 'title',
          fields: [
            'category',
            'result',
          ],
        );

      case 8:
        return const SyncPage();

      case 9:
        return const DatabaseListPage(
          table: 'marketplace_products',
          titleField: 'name',
          fields: [
            'category',
            'unit',
            'price',
            'region',
          ],
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
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
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
                    Text('Construction Assistant 2.0'),
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

  Widget menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Сохтмонро пеш аз харид ҳисоб кунед',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Андозаи биноро ворид кунед. SMETA TJ масоҳат, ҳаҷм, '
          'масолеҳ ва арзиши тахминиро ҳисоб мекунад.',
        ),
        const SizedBox(height: 18),
        menuCard(
          title: 'Хонаамро ҳисоб кун',
          subtitle:
              'Девор • фундамент • бетон • блок • хишт • бом • ороиш',
          icon: Icons.home_work,
          onTap: () => openPage(1),
        ),
        menuCard(
          title: 'Сметаи касбӣ',
          subtitle:
              'Объектҳо, сметаҳо ва натиҷаҳои сохтмон',
          icon: Icons.engineering,
          onTap: () => openPage(3),
        ),
        menuCard(
          title: 'Меъёрҳои сохтмонӣ',
          subtitle:
              'Ҷустуҷӯ дар базаи меъёрҳои SMETA TJ',
          icon: Icons.menu_book,
          onTap: () => openPage(4),
        ),
        menuCard(
          title: 'Нархҳо',
          subtitle:
              'Базаи нархи масолеҳ ва корҳои сохтмонӣ',
          icon: Icons.payments,
          onTap: () => openPage(5),
        ),
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: primary,
                ),
                SizedBox(height: 8),
                Text(
                  'Ҳисоби бехатар',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Ҳисобҳои миқдор ва арзиш пешакӣ мебошанд. '
                  'Андозаи фундамент, арматура ва дигар '
                  'конструксияҳои борбардор барои сохтмони воқеӣ '
                  'бояд аз рӯи лоиҳа ва ҳисоби муҳандисӣ тасдиқ шаванд.',
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
// CALCULATION MODEL
// ============================================================

class CalculationItem {
  final String category;
  final String name;
  final String unit;
  final double quantity;
  final double unitPrice;
  final String note;

  const CalculationItem({
    required this.category,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.note = '',
  });

  double get total => quantity * unitPrice;
}

// ============================================================
// AUTOMATIC CONSTRUCTION CALCULATOR
// ============================================================

class ConstructionCalculator extends StatefulWidget {
  const ConstructionCalculator({super.key});

  @override
  State<ConstructionCalculator> createState() =>
      _ConstructionCalculatorState();
}

class _ConstructionCalculatorState
    extends State<ConstructionCalculator> {
  final calculationName =
      TextEditingController(text: 'Хонаи ман');

  final length =
      TextEditingController(text: '10');

  final width =
      TextEditingController(text: '12');

  final floorHeight =
      TextEditingController(text: '3');

  final floors =
      TextEditingController(text: '1');

  final openingsArea =
      TextEditingController(text: '20');

  final internalWallLength =
      TextEditingController(text: '20');

  final wallThickness =
      TextEditingController(text: '0.20');

  final foundationWidth =
      TextEditingController(text: '0.40');

  final foundationHeight =
      TextEditingController(text: '0.80');

  String wallMaterial = 'Газоблок 600×300×200';
  String foundationType = 'Лентагӣ';
  String roofType = 'Душатра';
  String finishLevel = 'Стандарт';

  double wastePercent = 5;

  bool busy = false;

  List<CalculationItem> results = [];

  Map<String, double> geometry = {};

  double value(TextEditingController controller) {
    return double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  Widget numericField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  Widget dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<Map<String, double>> loadPrices() async {
    final priceMap = <String, double>{};

    try {
      final data = await db
          .from('prices')
          .select('name,price');

      for (final row in data) {
        final name =
            '${row['name'] ?? ''}'.trim().toLowerCase();

        if (name.isNotEmpty) {
          priceMap[name] = toDouble(row['price']);
        }
      }
    } catch (_) {}

    return priceMap;
  }

  double findPrice(
    Map<String, double> prices,
    List<String> words,
  ) {
    for (final entry in prices.entries) {
      for (final word in words) {
        if (entry.key.contains(word.toLowerCase())) {
          return entry.value;
        }
      }
    }

    return 0;
  }

  Future<void> calculate() async {
    final l = value(length);
    final w = value(width);
    final h = value(floorHeight);
    final floorCount =
        math.max(1, value(floors).round());

    final openings =
        math.max(0.0, value(openingsArea));

    final insideLength =
        math.max(0.0, value(internalWallLength));

    final thickness =
        value(wallThickness);

    final foundationW =
        value(foundationWidth);

    final foundationH =
        value(foundationHeight);

    if (l <= 0 ||
        w <= 0 ||
        h <= 0 ||
        thickness <= 0) {
      showMessage(
        context,
        'Андозаҳои биноро дуруст ворид кунед.',
      );
      return;
    }

    setState(() => busy = true);

    final prices = await loadPrices();

    final wasteFactor =
        1 + wastePercent / 100;

    final footprint = l * w;

    final totalFloorArea =
        footprint * floorCount;

    final perimeter =
        2 * (l + w);

    final grossExteriorWallArea =
        perimeter * h * floorCount;

    final netExteriorWallArea =
        math.max(
          0.0,
          grossExteriorWallArea - openings,
        );

    final interiorWallOneSideArea =
        insideLength * h * floorCount;

    final interiorFinishArea =
        interiorWallOneSideArea * 2;

    final exteriorWallVolume =
        netExteriorWallArea * thickness;

    final internalWallVolume =
        interiorWallOneSideArea * thickness;

    final totalWallVolume =
        exteriorWallVolume + internalWallVolume;

    double foundationVolume = 0;

    if (foundationType == 'Лентагӣ') {
      foundationVolume =
          perimeter *
          foundationW *
          foundationH;
    } else {
      foundationVolume =
          footprint * foundationH;
    }

    double roofArea = footprint;

    if (roofType == 'Душатра') {
      roofArea = footprint * 1.15;
    }

    if (roofType == 'Чоршатра') {
      roofArea = footprint * 1.20;
    }

    final finishArea =
        netExteriorWallArea +
        interiorFinishArea;

    final items = <CalculationItem>[];

    // --------------------------------------------------------
    // WALL
    // --------------------------------------------------------

    if (wallMaterial ==
        'Газоблок 600×300×200') {
      const blockVolume =
          0.60 * 0.30 * 0.20;

      final quantity =
          totalWallVolume /
          blockVolume *
          wasteFactor;

      items.add(
        CalculationItem(
          category: 'Девор',
          name: wallMaterial,
          unit: 'дона',
          quantity: quantity.ceilToDouble(),
          unitPrice: findPrice(
            prices,
            [
              'газоблок',
              'газобетон',
            ],
          ),
          note:
              'Миқдор аз рӯи ҳаҷми девор ва захираи талафот ҳисоб шудааст.',
        ),
      );
    } else if (wallMaterial ==
        'Газоблок 600×250×200') {
      const blockVolume =
          0.60 * 0.25 * 0.20;

      final quantity =
          totalWallVolume /
          blockVolume *
          wasteFactor;

      items.add(
        CalculationItem(
          category: 'Девор',
          name: wallMaterial,
          unit: 'дона',
          quantity: quantity.ceilToDouble(),
          unitPrice: findPrice(
            prices,
            [
              'газоблок',
              'газобетон',
            ],
          ),
        ),
      );
    } else if (wallMaterial ==
        'Хишт 250×120×65') {
      const nominalBrickVolume =
          0.00195;

      final quantity =
          totalWallVolume /
          nominalBrickVolume *
          wasteFactor;

      items.add(
        CalculationItem(
          category: 'Девор',
          name: wallMaterial,
          unit: 'дона',
          quantity: quantity.ceilToDouble(),
          unitPrice: findPrice(
            prices,
            [
              'хишт',
              'кирпич',
            ],
          ),
          note:
              'Ҳисоби пешакӣ. Дарзи маҳлул ва усули кладка ба миқдори воқеӣ таъсир мерасонанд.',
        ),
      );
    } else {
      items.add(
        CalculationItem(
          category: 'Девор',
          name: 'Бетон барои девор',
          unit: 'м³',
          quantity:
              totalWallVolume * 1.03,
          unitPrice: findPrice(
            prices,
            ['бетон'],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // FOUNDATION
    // --------------------------------------------------------

    items.add(
      CalculationItem(
        category: 'Фундамент',
        name: 'Бетон',
        unit: 'м³',
        quantity:
            foundationVolume * 1.03,
        unitPrice: findPrice(
          prices,
          ['бетон'],
        ),
        note:
            'Ҳаҷми геометрии фундамент + 3% захира.',
      ),
    );

    // IMPORTANT:
    // This is budget-only, not structural design.
    items.add(
      CalculationItem(
        category: 'Фундамент',
        name: 'Арматура — ориентири буҷетӣ',
        unit: 'кг',
        quantity:
            foundationVolume *
            90 *
            wasteFactor,
        unitPrice: findPrice(
          prices,
          [
            'арматура',
            'rebar',
          ],
        ),
        note:
            'Танҳо барои арзёбии пешакии буҷет. Миқдор ва диаметри воқеии арматура аз ҳисоби конструктивӣ муайян карда мешавад.',
      ),
    );

    // --------------------------------------------------------
    // FINISH
    // --------------------------------------------------------

    items.add(
      CalculationItem(
        category: 'Ороиш',
        name: 'Масоҳати андова',
        unit: 'м²',
        quantity:
            finishArea * wasteFactor,
        unitPrice: findPrice(
          prices,
          [
            'андова',
            'штукатур',
          ],
        ),
      ),
    );

    if (finishLevel != 'Иқтисодӣ') {
      items.add(
        CalculationItem(
          category: 'Ороиш',
          name: 'Масоҳати шпаклёвка',
          unit: 'м²',
          quantity:
              finishArea * wasteFactor,
          unitPrice: findPrice(
            prices,
            [
              'шпакл',
            ],
          ),
        ),
      );

      items.add(
        CalculationItem(
          category: 'Ороиш',
          name: 'Масоҳати ранг',
          unit: 'м²',
          quantity:
              finishArea * wasteFactor,
          unitPrice: findPrice(
            prices,
            [
              'ранг',
              'краска',
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // ROOF
    // --------------------------------------------------------

    items.add(
      CalculationItem(
        category: 'Бом',
        name: 'Масоҳати бом',
        unit: 'м²',
        quantity:
            roofArea * wasteFactor,
        unitPrice: findPrice(
          prices,
          [
            'бом',
            'кровл',
            'профнаст',
            'металлочереп',
          ],
        ),
        note:
            'Масоҳати пешакӣ. Геометрияи воқеии бом метавонад натиҷаро тағйир диҳад.',
      ),
    );

    geometry = {
      'Масоҳати як ошёна':
          footprint,
      'Масоҳати умумии фарш':
          totalFloorArea,
      'Периметри бино':
          perimeter,
      'Девори берунии холис':
          netExteriorWallArea,
      'Деворҳои дохилӣ':
          interiorFinishArea,
      'Ҳаҷми умумии девор':
          totalWallVolume,
      'Ҳаҷми фундамент':
          foundationVolume,
      'Масоҳати бом':
          roofArea,
    };

    if (mounted) {
      setState(() {
        results = items;
        busy = false;
      });
    }
  }

  Future<void> saveCalculation() async {
    if (results.isEmpty) {
      showMessage(
        context,
        'Аввал ҳисобро иҷро кунед.',
      );
      return;
    }

    setState(() => busy = true);

    try {
      final total = results.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );

      final inserted = await db
          .from('building_calculations')
          .insert({
            'user_id': uid,
            'title':
                calculationName.text.trim().isEmpty
                    ? 'Ҳисоби сохтмон'
                    : calculationName.text.trim(),
            'building_type':
                'Хонаи истиқоматӣ',
            'length_m': value(length),
            'width_m': value(width),
            'floor_height_m':
                value(floorHeight),
            'floors':
                math.max(
                  1,
                  value(floors).round(),
                ),
            'wall_material':
                wallMaterial,
            'wall_thickness_m':
                value(wallThickness),
            'openings_area_m2':
                value(openingsArea),
            'internal_wall_length_m':
                value(internalWallLength),
            'foundation_type':
                foundationType,
            'foundation_width_m':
                value(foundationWidth),
            'foundation_height_m':
                value(foundationHeight),
            'roof_type': roofType,
            'finish_level':
                finishLevel,
            'waste_percent':
                wastePercent,
            'floor_area_m2':
                geometry[
                        'Масоҳати умумии фарш'] ??
                    0,
            'outer_wall_area_m2':
                geometry[
                        'Девори берунии холис'] ??
                    0,
            'inner_wall_area_m2':
                geometry[
                        'Деворҳои дохилӣ'] ??
                    0,
            'wall_volume_m3':
                geometry[
                        'Ҳаҷми умумии девор'] ??
                    0,
            'foundation_volume_m3':
                geometry[
                        'Ҳаҷми фундамент'] ??
                    0,
            'estimated_total': total,
          })
          .select('id')
          .single();

      final calculationId =
          inserted['id'];

      final rows = results
          .map(
            (item) => {
              'user_id': uid,
              'calculation_id':
                  calculationId,
              'category':
                  item.category,
              'material_name':
                  item.name,
              'unit': item.unit,
              'quantity':
                  item.quantity,
              'unit_price':
                  item.unitPrice,
              'total_price':
                  item.total,
              'note': item.note,
            },
          )
          .toList();

      await db
          .from('calculation_results')
          .insert(rows);

      if (mounted) {
        showMessage(
          context,
          'Ҳисоб бомуваффақият нигоҳ дошта шуд.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          'Хатои сабт: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTotal =
        results.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ҳисоби автоматии сохтмон',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Андозаҳои биноро ворид карда, масолеҳро интихоб кунед.',
        ),
        const SizedBox(height: 16),

        TextField(
          controller: calculationName,
          decoration: const InputDecoration(
            labelText: 'Номи ҳисоб',
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: numericField(
                length,
                'Дарозӣ, м',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: numericField(
                width,
                'Бар, м',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: numericField(
                floorHeight,
                'Баландии ошёна, м',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: numericField(
                floors,
                'Ошёна',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: numericField(
                openingsArea,
                'Дару тиреза, м²',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: numericField(
                internalWallLength,
                'Девори дохилӣ, м',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        dropdown(
          label: 'Масолеҳи девор',
          value: wallMaterial,
          values: const [
            'Газоблок 600×300×200',
            'Газоблок 600×250×200',
            'Хишт 250×120×65',
            'Оҳанбетон',
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              wallMaterial = value;
            });
          },
        ),

        const SizedBox(height: 10),

        numericField(
          wallThickness,
          'Ғафсии девор, м',
        ),

        const SizedBox(height: 10),

        dropdown(
          label: 'Навъи фундамент',
          value: foundationType,
          values: const [
            'Лентагӣ',
            'Плита',
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              foundationType = value;
            });
          },
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: numericField(
                foundationWidth,
                'Бари фундамент, м',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: numericField(
                foundationHeight,
                'Баландӣ/ғафсӣ, м',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        dropdown(
          label: 'Навъи бом',
          value: roofType,
          values: const [
            'Душатра',
            'Чоршатра',
            'Ҳамвор',
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              roofType = value;
            });
          },
        ),

        const SizedBox(height: 10),

        dropdown(
          label: 'Сатҳи ороиш',
          value: finishLevel,
          values: const [
            'Иқтисодӣ',
            'Стандарт',
            'Премиум',
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              finishLevel = value;
            });
          },
        ),

        const SizedBox(height: 12),

        Text(
          'Захираи талафот: '
          '${wastePercent.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        Slider(
          value: wastePercent,
          min: 0,
          max: 15,
          divisions: 15,
          label:
              '${wastePercent.toStringAsFixed(0)}%',
          onChanged: (value) {
            setState(() {
              wastePercent = value;
            });
          },
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed:
                busy ? null : calculate,
            icon: const Icon(
              Icons.calculate,
            ),
            label: const Text(
              'ҲИСОБ КУН',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        if (busy) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],

        if (results.isNotEmpty) ...[
          const SizedBox(height: 24),

          const Text(
            'НАТИҶАИ ҲИСОБ',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: geometry.entries
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        title:
                            Text(entry.key),
                        trailing: Text(
                          entry.key.contains(
                                  'Ҳаҷм')
                              ? '${number(entry.value)} м³'
                              : entry.key.contains(
                                      'Периметр')
                                  ? '${number(entry.value)} м'
                                  : '${number(entry.value)} м²',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Масолеҳ ва корҳо',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          for (final item in results)
            Card(
              child: ListTile(
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  item.note.isEmpty
                      ? item.category
                      : '${item.category}\n${item.note}',
                ),
                isThreeLine:
                    item.note.isNotEmpty,
                trailing: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${number(item.quantity)} ${item.unit}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.unitPrice > 0
                          ? '${number(item.total)} сом.'
                          : 'Нарх нест',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            item.unitPrice > 0
                                ? primary
                                : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'АРЗИШИ ТАХМИНӢ',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${number(estimatedTotal)} сом.',
                    style: const TextStyle(
                      fontSize: 19,
                      color: primary,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed:
                busy
                    ? null
                    : saveCalculation,
            icon: const Icon(Icons.save),
            label: const Text(
              'Ҳисобро нигоҳ дор',
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Агар барои ягон масолеҳ «Нарх нест» барояд, '
            'нархи он ҳоло дар базаи Нархҳо ворид нашудааст.',
            style: TextStyle(
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ============================================================
// GENERIC DATABASE VIEW
// ============================================================

class DatabaseListPage extends StatefulWidget {
  final String table;
  final String titleField;
  final List<String> fields;

  const DatabaseListPage({
    super.key,
    required this.table,
    required this.titleField,
    required this.fields,
  });

  @override
  State<DatabaseListPage> createState() =>
      _DatabaseListPageState();
}

class _DatabaseListPageState
    extends State<DatabaseListPage> {
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
          .from(widget.table)
          .select()
          .order(
            'created_at',
            ascending: false,
          )
          .limit(200);

      if (!mounted) return;

      setState(() {
        rows =
            List<Map<String, dynamic>>.from(
          data,
        );

        busy = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => busy = false);

      showMessage(
        context,
        '${widget.table}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (busy)
            const LinearProgressIndicator(),

          if (!busy && rows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Ҳоло маълумот нест.',
                ),
              ),
            ),

          for (final row in rows)
            Card(
              child: ListTile(
                title: Text(
                  '${row[widget.titleField] ?? ''}',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  widget.fields
                      .map(
                        (field) =>
                            '${row[field] ?? ''}',
                      )
                      .where(
                        (text) =>
                            text.trim().isNotEmpty,
                      )
                      .join(' • '),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STANDARDS
// ============================================================

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() =>
      _StandardsPageState();
}

class _StandardsPageState
    extends State<StandardsPage> {
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

      if (!mounted) return;

      setState(() {
        rows =
            List<Map<String, dynamic>>.from(
          data,
        );

        busy = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => busy = false);

      showMessage(
        context,
        'Меъёрҳо: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query =
        search.text.trim().toLowerCase();

    final filtered = rows.where(
      (row) {
        final text =
            '${row['code']} '
            '${row['title']} '
            '${row['status']}'
                .toLowerCase();

        return text.contains(query);
      },
    ).toList();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: search,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText:
                  'Ҷустуҷӯи меъёр',
              prefixIcon:
                  Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 10),

          if (busy)
            const LinearProgressIndicator(),

          for (final row in filtered)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified,
                  color: primary,
                ),
                title: Text(
                  '${row['code'] ?? ''}',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${row['title'] ?? ''}\n'
                  '${row['edition_year'] ?? ''} • '
                  '${row['status'] ?? ''}',
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
  State<SyncPage> createState() =>
      _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool busy = false;

  String status =
      'Барои санҷиш тугмаро пахш кунед.';

  Future<void> check() async {
    setState(() => busy = true);

    try {
      await db
          .from('projects')
          .select('id')
          .limit(1);

      await db
          .from('material_catalog')
          .select('id')
          .limit(1);

      if (mounted) {
        setState(() {
          status =
              'Supabase Online — пайвастшавӣ дуруст аст.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          status = 'Хато: $e';
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
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.cloud_done,
              color: primary,
            ),
            title: Text(status),
            subtitle: Text(
              db.auth.currentUser?.email ?? '',
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: busy ? null : check,
          icon: const Icon(Icons.sync),
          label: const Text(
            'Санҷидани пайвастшавӣ',
          ),
        ),
      ],
    );
  }
}

// ============================================================
// AI DATABASE ASSISTANT
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

  Future<void> searchDatabase() async {
    final query =
        question.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() => busy = true);

    try {
      final standards = await db
          .from('construction_standards')
          .select()
          .limit(300);

      final materials = await db
          .from('material_catalog')
          .select()
          .limit(300);

      final words = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where(
            (word) => word.length > 2,
          )
          .toList();

      final buffer = StringBuffer();

      for (final row in standards) {
        final text =
            '${row['code']} ${row['title']}'
                .toLowerCase();

        if (words.any(text.contains)) {
          buffer.writeln(
            '• ${row['code']} — ${row['title']}',
          );
        }
      }

      for (final row in materials) {
        final text =
            '${row['name']} ${row['category']}'
                .toLowerCase();

        if (words.any(text.contains)) {
          buffer.writeln(
            '• ${row['name']} — ${row['unit']}',
          );
        }
      }

      answer = buffer.isEmpty
          ? 'Дар база маълумоти мувофиқ нест.'
          : buffer.toString();

      await db.from('ai_history').insert({
        'user_id': uid,
        'question': query,
        'answer': answer,
        'ai_mode': 'database_search',
      });

      if (mounted) {
        setState(() {});
      }
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
        const Text(
          'AI SMETA TJ',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Ёрдамчии ҷустуҷӯӣ дар базаи SMETA TJ. '
          'Ҳисобҳои миқдориро модули «Ҳисоби сохтмон» иҷро мекунад.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: question,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Савол',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed:
              busy
                  ? null
                  : searchDatabase,
          icon: const Icon(
            Icons.auto_awesome,
          ),
          label: const Text('Ҷустуҷӯ'),
        ),
        if (busy)
          const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              answer.isEmpty
                  ? 'Натиҷа дар ин ҷо пайдо мешавад.'
                  : answer,
            ),
          ),
        ),
      ],
    );
  }
}
