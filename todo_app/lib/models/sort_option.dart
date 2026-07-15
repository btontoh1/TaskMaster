enum SortOption {
  manual('Manual'),
  dueDate('Due date'),
  priority('Priority');

  const SortOption(this.label);
  final String label;
}
