void reorderCategoryList<T>(List<T> categories, int oldIndex, int newIndex) {
  if (oldIndex < newIndex) newIndex -= 1;
  categories.insert(newIndex, categories.removeAt(oldIndex));
}
