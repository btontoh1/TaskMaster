import 'package:flutter/material.dart';

import 'models/todo.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({
    super.key,
    this.initial,
    this.existingCategories = const [],
  });

  final Todo? initial;
  final List<String> existingCategories;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  static const _newCategorySentinel = '__new__';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _categoryController;
  String? _selectedCategory;
  bool _addingCategory = false;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late Priority _priority;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    final initialCategory = initial?.category ?? '';
    _categoryController = TextEditingController(text: initialCategory);
    if (initialCategory.isEmpty) {
      _selectedCategory = null;
    } else if (widget.existingCategories.contains(initialCategory)) {
      _selectedCategory = initialCategory;
    } else {
      _addingCategory = true;
    }
    _dueDate = initial?.dueDate;
    _dueTime = initial?.dueTime;
    _priority = initial?.priority ?? Priority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _setQuickDate(int daysFromToday) {
    final now = DateTime.now();
    setState(() {
      _dueDate = DateTime(now.year, now.month, now.day + daysFromToday);
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final todo = Todo(
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      done: widget.initial?.done ?? false,
      dueDate: _dueDate,
      dueTime: _dueDate == null ? null : _dueTime,
      priority: _priority,
      category: _addingCategory
          ? _categoryController.text.trim()
          : (_selectedCategory ?? ''),
    );
    Navigator.pop(context, todo);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _FormSection(
              title: 'Details',
              icon: Icons.description_outlined,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      textInputAction: TextInputAction.next,
                      autofocus: !isEditing,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _addingCategory ? _newCategorySentinel : _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        for (final category in widget.existingCategories)
                          DropdownMenuItem(value: category, child: Text(category)),
                        const DropdownMenuItem(
                          value: _newCategorySentinel,
                          child: Text('Add new category…'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value == _newCategorySentinel) {
                            _addingCategory = true;
                            _categoryController.clear();
                          } else {
                            _addingCategory = false;
                            _selectedCategory = value;
                          }
                        });
                      },
                    ),
                    if (_addingCategory) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'New category name'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FormSection(
              title: 'Due date',
              icon: Icons.event_outlined,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Today'),
                          onPressed: () => _setQuickDate(0),
                        ),
                        ActionChip(
                          label: const Text('Tomorrow'),
                          onPressed: () => _setQuickDate(1),
                        ),
                        ActionChip(
                          label: const Text('Next week'),
                          onPressed: () => _setQuickDate(7),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(_dueDate == null ? 'No due date' : _dueDate!.longLabel),
                    trailing: _dueDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _dueDate = null;
                              _dueTime = null;
                            }),
                          ),
                    onTap: _pickDueDate,
                  ),
                  if (_dueDate != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time_outlined),
                      title: Text(_dueTime == null ? 'No time set' : _dueTime!.label),
                      trailing: _dueTime == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dueTime = null),
                            ),
                      onTap: _pickDueTime,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _FormSection(
              title: 'Priority',
              icon: Icons.flag_outlined,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<Priority>(
                  segments: const [
                    ButtonSegment(value: Priority.low, label: Text('Low')),
                    ButtonSegment(value: Priority.medium, label: Text('Medium')),
                    ButtonSegment(value: Priority.high, label: Text('High')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) =>
                      setState(() => _priority = selection.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}
