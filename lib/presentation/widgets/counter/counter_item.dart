import 'package:flutter/material.dart';
import 'package:tazkira_app/presentation/widgets/common/show_alert.dart';
import '../../../data/tasbeeh_list.dart';
import 'counter_details.dart';

class CounterItem extends StatefulWidget {
  final int index;
  const CounterItem({Key? key, required this.index}) : super(key: key);

  @override
  State<CounterItem> createState() => _CounterItemState();
}

class _CounterItemState extends State<CounterItem> {
  int count = 0;

  void incrementCounter() {
    setState(() {
      count++;

      List<int> milestones = [
        50,
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
        1100,
        1200,
        1300,
        1400,
        1500,
        1600,
        1700,
        1800,
        1900,
        2000
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return ImprovedCounter(
      count: count,
      onIncrement: incrementCounter,
      onReset: resetCounter,
      title: azkarList[widget.index]["title"],
    );
  }
}
