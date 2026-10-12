import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/expense.dart';

String currency(num value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} đ';
const chartColors = [
  Color(0xff26705d),
  Color(0xff447db1),
  Color(0xffdaa338),
  Color(0xff8c68b0),
  Color(0xffc3675b),
];

int? donutHit(Offset position, Size size, List<int> values) {
  final delta = position - size.center(Offset.zero);
  final radius = delta.distance;
  final outer = math.min(size.width, size.height) / 2 - 15;
  if (radius > outer + 20 || radius < outer - 20) return null;
  final total = values.fold<int>(0, (a, b) => a + b);
  if (total <= 0) return null;
  final angle = (math.atan2(delta.dy, delta.dx) + math.pi / 2) % (2 * math.pi);
  var limit = 0.0;
  for (var i = 0; i < values.length; i++) {
    limit += values[i] / total * 2 * math.pi;
    if (angle < limit) return i;
  }
  return null;
}

class DonutChart extends StatefulWidget {
  const DonutChart({super.key, required this.amounts});
  final Map<String, int> amounts;
  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final values = categories.map((e) => widget.amounts[e] ?? 0).toList();
    final total = values.fold<int>(0, (a, b) => a + b);
    return Column(
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: GestureDetector(
            onTapUp: (event) => setState(
              () => selected = donutHit(
                event.localPosition,
                const Size(260, 260),
                values,
              ),
            ),
            child: CustomPaint(
              painter: DonutPainter(values, selected),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected == null ? 'Tổng chi' : categories[selected!]),
                    Text(
                      currency(selected == null ? total : values[selected!]),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (var i = 0; i < categories.length; i++)
          ListTile(
            dense: true,
            leading: Icon(Icons.circle, color: chartColors[i], size: 16),
            title: Text(categories[i]),
            trailing: Text(currency(values[i])),
            selected: selected == i,
            onTap: () => setState(() => selected = selected == i ? null : i),
          ),
        if (total == 0) const Text('Chưa có khoản chi trong bộ lọc này.'),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.selected);
  final List<int> values;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) / 2 - 15,
    );
    final total = values.fold<int>(0, (a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38;
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        paint..color = Colors.grey.shade200,
      );
      return;
    }
    var angle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      paint.color = selected == null || selected == i
          ? chartColors[i]
          : chartColors[i].withValues(alpha: .25);
      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) =>
      old.selected != selected || old.values.toString() != values.toString();
}

class WeeklyChart extends StatefulWidget {
  const WeeklyChart({super.key, required this.values});
  final List<int> values;
  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  int? selected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 210,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapUp: (event) {
              final i =
                  ((event.localPosition.dx - 12) /
                          ((constraints.maxWidth - 24) / 7))
                      .floor();
              setState(() => selected = i >= 0 && i < 7 ? i : null);
            },
            child: CustomPaint(painter: WeekPainter(widget.values, selected)),
          ),
        ),
      ),
      Text(
        selected == null
            ? 'Chạm vào cột để xem số tiền.'
            : '${selected == 6 ? 'CN' : 'T${selected! + 2}'}: ${currency(widget.values[selected!])}',
      ),
    ],
  );
}

class WeekPainter extends CustomPainter {
  WeekPainter(this.values, this.selected);
  final List<int> values;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce(math.max);
    final baseline = size.height - 28;
    final step = (size.width - 24) / 7;
    canvas.drawLine(
      Offset(12, baseline),
      Offset(size.width - 12, baseline),
      Paint()..color = Colors.grey.shade400,
    );
    for (var i = 0; i < 7; i++) {
      final h = maxValue == 0 ? 0.0 : values[i] / maxValue * (baseline - 36);
      final rect = Rect.fromLTWH(
        12 + i * step + step * .2,
        baseline - h,
        step * .6,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = selected == null || selected == i
              ? chartColors[0]
              : Colors.grey.shade300,
      );
      final label = TextPainter(
        text: TextSpan(
          text: i == 6 ? 'CN' : 'T${i + 2}',
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(12 + i * step + (step - label.width) / 2, baseline + 7),
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text: currency(maxValue),
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(12, 0));
  }

  @override
  bool shouldRepaint(WeekPainter old) =>
      old.selected != selected || old.values.toString() != values.toString();
}
