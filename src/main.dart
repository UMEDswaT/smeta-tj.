class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  List<Map<String, dynamic>> estimates = [];
  List<Map<String, dynamic>> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final projectData = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      final estimateData = await supabase
          .from('estimates')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        projects = List<Map<String, dynamic>>.from(projectData);
        estimates = List<Map<String, dynamic>>.from(estimateData);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showAppMessage(context, 'Хато: $e');
    }
  }

  String findProjectName(String projectId) {
    for (final project in projects) {
      if (project['id'].toString() == projectId) {
        return project['name']?.toString() ?? '';
      }
    }

    return 'Объект';
  }

  Future<void> addEstimate() async {
    if (projects.isEmpty) {
      showAppMessage(
        context,
        'Аввал дар бахши Объектҳо як объект созед.',
      );
      return;
    }

    final titleController = TextEditingController();
    String selectedProjectId = projects.first['id'].toString();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Сметаи нав'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Объект',
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project['id'].toString(),
                          child: Text(
                            project['name']?.toString() ?? '',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedProjectId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Номи смета *',
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
      },
    );

    if (save != true) {
      titleController.dispose();
      return;
    }

    final title = titleController.text.trim();
    titleController.dispose();

    if (title.isEmpty) {
      if (mounted) {
        showAppMessage(context, 'Номи сметаро нависед.');
      }
      return;
    }

    try {
      await supabase.from('estimates').insert({
        'user_id': supabase.auth.currentUser!.id,
        'project_id': selectedProjectId,
        'title': title,
        'estimate_type': 'local',
        'status': 'draft',
      });

      if (!mounted) return;

      showAppMessage(context, 'Смета сохта шуд.');
      await loadData();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Хато: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addEstimate,
        icon: const Icon(Icons.add),
        label: const Text('Сметаи нав'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: estimates.isEmpty
                  ? const EmptyPage(
                      icon: Icons.calculate_outlined,
                      title: 'Ҳоло смета нест',
                      subtitle:
                          'Аввал объект созед, баъд смета илова кунед.',
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        90,
                      ),
                      itemCount: estimates.length,
                      itemBuilder: (context, index) {
                        final item = estimates[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.calculate),
                            ),
                            title: Text(
                              item['title']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Объект: '
                              '${findProjectName(item['project_id'].toString())}\n'
                              'Ҳолат: ${item['status'] ?? 'draft'}\n'
                              'Ҷамъ: ${item['total'] ?? 0} сомонӣ',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}