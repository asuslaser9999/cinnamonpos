double serviceOnItems(double itemsAmount, double percent) {
  if (itemsAmount <= 0 || percent <= 0) return 0;
  return (itemsAmount * percent / 100).roundToDouble();
}
