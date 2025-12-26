import 'package:tazkira_app/core/routing/route_export.dart';

class CounterItem extends StatefulWidget {
  final int index;
  const CounterItem({super.key, required this.index});

  @override
  State<CounterItem> createState() => _CounterItemState();
}

class _CounterItemState extends State<CounterItem> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Use the title as a unique key for persistence
      count = prefs.getInt('tasbeeh_${azkarList[widget.index]["title"]}') ?? 0;
    });
  }

  Future<void> _saveCount(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_${azkarList[widget.index]["title"]}', val);
  }

  void incrementCounter() {
    HapticFeedback.lightImpact();
    setState(() {
      count++;
      _saveCount(count);

      List<int> milestones = [
        25,
        50,
        75,
        100,
        150,
        200,
        300,
        400,
        500,
        600,
        700,
        800,
        900,
        1000,
        10000
      ];

      if (milestones.contains(count)) {
        showAlert(
          context: context,
          title: "ما شاء الله ",
          message:
              "لقد أكملت $count تسبيحة من ${azkarList[widget.index]["title"]}",
        );
      }
    });
  }

  void resetCounter() {
    setState(() {
      count = 0;
      _saveCount(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CounterDetails(
      count: count,
      onIncrement: incrementCounter,
      onReset: resetCounter,
      title: azkarList[widget.index]["title"],
    );
  }
}
