import 'package:flutter/material.dart';
import 'package:tazkira_app/widgets/show_alert.dart';
import '../lists/tasbeeh_list.dart';
import '../counter_details.dart';

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
      if (count == 50) {
        showAlert(
          context: context,
          title: "ما شاء الله ",
          message: "لقد أكملت 50 تسبيحة من ${azkarList[widget.index]["title"]}",
        );
      } else if (count == 100) {
        showAlert(
          context: context,
          title: "ما شاء الله ",
          message:
              "لقد أكملت 100 تسبيحة من ${azkarList[widget.index]["title"]}",
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
