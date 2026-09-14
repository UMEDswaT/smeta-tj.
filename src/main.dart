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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Нарх',
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

    if (ok != true) return;

    try {
      await sb.from('prices').insert({
        'owner_user_id': sb.auth.currentUser!.id,
        'category': 'material',
        'name': name.text.trim(),
        'unit': unit.text.trim(),
        'price': double.tryParse(price.text.trim()) ?? 0,
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
// ================= HELPERS =================

Widget field(
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

Widget gap() {
  return const SizedBox(height: 10);
}

void disposeControllers(
  List<TextEditingController> controllers,
) {
  for (final controller in controllers) {
    controller.dispose();
  }
}

Widget empty(String text) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(30),
    children: [
      const SizedBox(height: 120),
      const Icon(
        Icons.inbox_outlined,
        size: 70,
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
