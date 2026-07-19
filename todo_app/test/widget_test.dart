import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_app/main.dart';

Future<void> _addTask(
  WidgetTester tester,
  String title, {
  String? priority,
}) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), title);
  if (priority != null) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text(priority).first);
  }
  await tester.tap(find.byTooltip('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Add a task with details and mark it done', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Buy milk');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('1 task remaining'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(find.text('0 tasks remaining'), findsOneWidget);
  });

  testWidgets('Settings: switching theme mode updates the app theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('Settings: default sort order applies to the task list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Priority'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _addTask(tester, 'Low task', priority: 'Low');
    await _addTask(tester, 'High task', priority: 'High');

    final highPosition = tester.getTopLeft(find.text('High task')).dy;
    final lowPosition = tester.getTopLeft(find.text('Low task')).dy;
    expect(highPosition, lessThan(lowPosition));
  });

  testWidgets('Settings: clear completed tasks removes only done tasks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await _addTask(tester, 'Task A');
    await _addTask(tester, 'Task B');

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear completed tasks'), 200);
    await tester.tap(find.text('Clear completed tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Task A'), findsNothing);
    expect(find.text('Task B'), findsOneWidget);
  });

  testWidgets('Settings: reset all data clears every task', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await _addTask(tester, 'Temporary task');
    expect(find.text('Temporary task'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reset all data'), 200);
    await tester.ensureVisible(find.text('Reset all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
  });
}
