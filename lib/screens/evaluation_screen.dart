import 'package:flutter/material.dart';

import '../data/dance_database.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({
    super.key,
    required this.database,
    required this.onSaved,
  });

  final DanceDatabase database;
  final VoidCallback onSaved;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Juvenil';
  int? _evaluatorId;
  int? _danceStyleId;
  List<Map<String, Object?>> _evaluators = [];
  List<Map<String, Object?>> _styles = [];
  List<Map<String, Object?>> _criteria = [];
  final Map<int, double> _scores = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      widget.database.getEvaluators(),
      widget.database.getDanceStyles(),
      widget.database.getCriteria(),
    ]);
    if (!mounted) return;
    setState(() {
      _evaluators = results[0];
      _styles = results[1];
      _criteria = results[2];
      _evaluatorId = _evaluators.first['id'] as int?;
      _danceStyleId = _styles.first['id'] as int?;
      for (final criterion in _criteria) {
        _scores[criterion['id'] as int] = 8;
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _evaluatorId == null ||
        _danceStyleId == null) {
      return;
    }
    setState(() => _saving = true);
    await widget.database.saveEvaluation(
      dancerName: _nameController.text,
      category: _category,
      evaluatorId: _evaluatorId!,
      danceStyleId: _danceStyleId!,
      scores: _scores,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evaluación guardada correctamente.')),
    );
    widget.onSaved();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          const Text(
            'Nueva evaluación',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Califica cada criterio del 0 al 10.',
            style: TextStyle(color: Color(0xFF6F7772)),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del bailarín o grupo',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe un nombre.'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: const ['Infantil', 'Juvenil', 'Adulto', 'Senior']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _danceStyleId,
            decoration: const InputDecoration(labelText: 'Estilo de baile'),
            items: _styles
                .map(
                  (item) => DropdownMenuItem(
                    value: item['id'] as int,
                    child: Text(item['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _danceStyleId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _evaluatorId,
            decoration: const InputDecoration(labelText: 'Evaluador'),
            items: _evaluators
                .map(
                  (item) => DropdownMenuItem(
                    value: item['id'] as int,
                    child: Text(item['full_name'] as String),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _evaluatorId = value),
          ),
          const SizedBox(height: 22),
          const Text(
            'PUNTUACIÓN POR CRITERIO',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          ..._criteria.map((criterion) {
            final id = criterion['id'] as int;
            final score = _scores[id] ?? 8;
            return Card(
              margin: const EdgeInsets.only(top: 9),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 9),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(criterion['name'] as String)),
                        Text(
                          score.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF176B58),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: score,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: score.toStringAsFixed(0),
                      onChanged: (value) => setState(() => _scores[id] = value),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando…' : 'Guardar evaluación'),
          ),
        ],
      ),
    );
  }
}