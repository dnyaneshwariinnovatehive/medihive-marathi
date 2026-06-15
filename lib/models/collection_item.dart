class CollectionItem {
  final String name;
  final int amount;
  final String mode;

  const CollectionItem({
    required this.name,
    required this.amount,
    required this.mode,
  });
}

class RevenueData {
  final String name;
  final double value;

  const RevenueData({
    required this.name,
    required this.value,
  });
}

class OpdTrendData {
  final String day;
  final int count;

  const OpdTrendData({
    required this.day,
    required this.count,
  });
}
