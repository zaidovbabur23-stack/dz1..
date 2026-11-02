import 'package:flutter/material.dart';

import 'models/note.dart';

const _ink = Color(0xFF242138);
const _muted = Color(0xFF858397);
const _paper = Color(0xFFFAF9F6);
const _violet = Color(0xFF7667D8);
const _noteColors = <Color>[
  Color(0xFFFFE9B8),
  Color(0xFFDDF2E8),
  Color(0xFFE9E2FF),
  Color(0xFFFFE3E5),
  Color(0xFFDDF0F7),
];
const _categories = <String>['Личное', 'Работа', 'Идеи', 'Учёба'];

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _violet,
        surface: _paper,
      ),
      scaffoldBackgroundColor: _paper,
    );

    return MaterialApp(
      title: 'Тихие заметки',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFECEAF0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _violet, width: 1.5),
          ),
        ),
      ),
      home: const ListNoteScreen(),
    );
  }
}

class ListNoteScreen extends StatefulWidget {
  const ListNoteScreen({super.key});

  @override
  State<ListNoteScreen> createState() => _ListNoteScreenState();
}

class _ListNoteScreenState extends State<ListNoteScreen> {
  final List<Note> notes = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Все';
  bool _favoritesOnly = false;
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor({Note? note}) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute<Note>(
        builder: (_) => AddNoteScreen(note: note),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      if (note == null) {
        notes.add(result);
      } else {
        final index = notes.indexOf(note);
        if (index != -1) notes[index] = result;
      }
    });
  }

  void _toggleFavorite(Note note) {
    final index = notes.indexOf(note);
    if (index == -1) return;
    setState(() {
      notes[index] = note.copyWith(isFavorite: !note.isFavorite);
    });
  }

  void _deleteNote(Note note) {
    final index = notes.indexOf(note);
    if (index == -1) return;
    setState(() => notes.removeAt(index));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Заметка удалена'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () {
              setState(() {
                notes.insert(index.clamp(0, notes.length), note);
              });
            },
          ),
        ),
      );
  }

  List<Note> get _visibleNotes {
    final query = _searchController.text.trim().toLowerCase();
    final result = notes.where((note) {
      final matchesSearch = query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.description.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Все' || note.category == _selectedCategory;
      return matchesSearch &&
          matchesCategory &&
          (!_favoritesOnly || note.isFavorite);
    }).toList();
    result.sort(
      (a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _visibleNotes;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1000 ? 3 : width > 650 ? 2 : 1;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E5FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: _violet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ТИХИЕ ЗАМЕТКИ',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: _newestFirst
                              ? 'Сначала новые'
                              : 'Сначала старые',
                          onPressed: () =>
                              setState(() => _newestFirst = !_newestFirst),
                          icon: const Icon(Icons.swap_vert_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _favoritesOnly ? 'Любимое' : 'Ваши мысли',
                      style: const TextStyle(
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${notes.length} ${_noteCountLabel(notes.length)} — всё важное в одном месте',
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Найти заметку...',
                        hintStyle: const TextStyle(color: _muted),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _muted,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Очистить поиск',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        _FilterPill(
                          label: 'Все',
                          selected: !_favoritesOnly,
                          onTap: () => setState(() => _favoritesOnly = false),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Избранное',
                          icon: Icons.favorite_rounded,
                          selected: _favoritesOnly,
                          onTap: () => setState(
                            () => _favoritesOnly = !_favoritesOnly,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'Все',
                          ..._categories,
                        ].map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterPill(
                              label: category,
                              selected: _selectedCategory == category,
                              onTap: () =>
                                  setState(() => _selectedCategory = category),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (visibleNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNotes(
                  isFiltered: notes.isNotEmpty,
                  favoritesOnly: _favoritesOnly,
                  onAdd: _openEditor,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                sliver: SliverGrid.builder(
                  itemCount: visibleNotes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 226,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) =>
                      _NoteCard(
                        note: visibleNotes[index],
                        onFavorite: () => _toggleFavorite(visibleNotes[index]),
                        onEdit: () =>
                            _openEditor(note: visibleNotes[index]),
                        onDelete: () => _deleteNote(visibleNotes[index]),
                      ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Новая заметка',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : _muted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _noteColors[note.colorIndex % _noteColors.length];
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      note.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _NoteMenu(
                    onFavorite: onFavorite,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    isFavorite: note.isFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF58566A),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: _muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(note.createdAt),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteMenu extends StatelessWidget {
  const _NoteMenu({
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.isFavorite,
  });

  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Действия с заметкой',
      icon: const Icon(Icons.more_horiz_rounded, color: _ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'favorite':
            onFavorite();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'favorite',
          child: Text(isFavorite ? 'Убрать из избранного' : 'В избранное'),
        ),
        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
        const PopupMenuItem(value: 'delete', child: Text('Удалить')),
      ],
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({
    required this.isFiltered,
    required this.favoritesOnly,
    required this.onAdd,
  });

  final bool isFiltered;
  final bool favoritesOnly;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final title = favoritesOnly
        ? 'Пока ничего любимого'
        : isFiltered
            ? 'Ничего не найдено'
            : 'Начните с одной мысли';
    final subtitle = favoritesOnly
        ? 'Отметьте заметку сердечком, чтобы она появилась здесь.'
        : isFiltered
            ? 'Попробуйте изменить поиск или категорию.'
            : 'Запишите идею, план или то, что хочется запомнить.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E5FF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 40,
                color: _violet,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            if (!isFiltered && !favoritesOnly) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Создать заметку'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key, this.note});

  final Note? note;

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _category;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _descriptionController =
        TextEditingController(text: note?.description ?? '');
    _category = note?.category ?? _categories.first;
    _colorIndex = note?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitNote() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните заголовок и текст заметки'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      Note(
        title: title,
        description: description,
        category: _category,
        colorIndex: _colorIndex,
        isFavorite: widget.note?.isFavorite ?? false,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактирование' : 'Новая заметка'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  prefixIcon: Icon(Icons.short_text_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Текст заметки',
                    alignLabelWithHint: true,
                    hintText: 'Запишите всё, что не хочется забыть...',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Цвет карточки',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  for (var index = 0; index < _noteColors.length; index++)
                    GestureDetector(
                      onTap: () => setState(() => _colorIndex = index),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(left: 9),
                        decoration: BoxDecoration(
                          color: _noteColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorIndex == index ? _ink : Colors.white,
                            width: _colorIndex == index ? 2 : 1,
                          ),
                        ),
                        child: _colorIndex == index
                            ? const Icon(Icons.check, size: 16, color: _ink)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submitNote,
                  style: FilledButton.styleFrom(
                    backgroundColor: _violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: Icon(
                    isEditing ? Icons.check_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    isEditing ? 'Сохранить изменения' : 'Добавить заметку',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _noteCountLabel(int count) {
  final remainder100 = count % 100;
  if (remainder100 >= 11 && remainder100 <= 14) return 'заметок';
  switch (count % 10) {
    case 1:
      return 'заметка';
    case 2:
    case 3:
    case 4:
      return 'заметки';
    default:
      return 'заметок';
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Сегодня, ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }
  return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';
}

String _twoDigits(int number) => number.toString().padLeft(2, '0');