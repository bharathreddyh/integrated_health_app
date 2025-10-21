// ==================== SIMPLE LAB CHART - NO EXTERNAL PACKAGE ====================
// lib/widgets/simple_lab_chart.dart

import 'package:flutter/material.dart';
import '../models/endocrine/endocrine_condition.dart';

class SimpleLabChart extends StatelessWidget {
  final List<LabReading> readings;
  final String testName;
  final Color lineColor;
  final double? normalMin;
  final double? normalMax;

  const SimpleLabChart({
    super.key,
    required this.readings,
    required this.testName,
    this.lineColor = const Color(0xFF2563EB),
    this.normalMin,
    this.normalMax,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Text(
          'No data available for $testName',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    // Sort readings by date
    final sortedReadings = List<LabReading>.from(readings)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Find min and max values for scaling
    final values = sortedReadings.map((r) => r.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            testName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${sortedReadings.length} readings',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: LabChartPainter(
                readings: sortedReadings,
                lineColor: lineColor,
                normalMin: normalMin,
                normalMax: normalMax,
                minValue: minValue,
                maxValue: maxValue,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(lineColor, 'Values'),
        if (normalMin != null && normalMax != null) ...[
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green.shade200, 'Normal Range'),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class LabChartPainter extends CustomPainter {
  final List<LabReading> readings;
  final Color lineColor;
  final double? normalMin;
  final double? normalMax;
  final double minValue;
  final double maxValue;

  LabChartPainter({
    required this.readings,
    required this.lineColor,
    this.normalMin,
    this.normalMax,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Add padding
    final chartWidth = size.width - 60;
    final chartHeight = size.height - 40;
    final leftPadding = 50.0;
    final bottomPadding = 30.0;

    // Calculate Y-axis range with some padding
    final valueRange = maxValue - minValue;
    final yMin = (minValue - valueRange * 0.1).clamp(0, double.infinity);
    final yMax = maxValue + valueRange * 0.1;
    final yRange = yMax - yMin;

    // Draw normal range background if available
    if (normalMin != null && normalMax != null && yRange > 0) {
      final normalMinY = chartHeight - ((normalMin! - yMin) / yRange * chartHeight);
      final normalMaxY = chartHeight - ((normalMax! - yMin) / yRange * chartHeight);

      final normalRangePaint = Paint()
        ..color = Colors.green.shade100.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          leftPadding,
          normalMaxY,
          chartWidth,
          normalMinY - normalMaxY,
        ),
        normalRangePaint,
      );

      // Draw normal range borders
      final normalBorderPaint = Paint()
        ..color = Colors.green.shade300
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(leftPadding, normalMinY),
        Offset(leftPadding + chartWidth, normalMinY),
        normalBorderPaint,
      );
      canvas.drawLine(
        Offset(leftPadding, normalMaxY),
        Offset(leftPadding + chartWidth, normalMaxY),
        normalBorderPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    // Y-axis
    canvas.drawLine(
      Offset(leftPadding, 0),
      Offset(leftPadding, chartHeight),
      axisPaint,
    );

    // X-axis
    canvas.drawLine(
      Offset(leftPadding, chartHeight),
      Offset(leftPadding + chartWidth, chartHeight),
      axisPaint,
    );

    // Draw Y-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    final numYLabels = 5;
    for (int i = 0; i <= numYLabels; i++) {
      final value = yMin + (yRange * i / numYLabels);
      final y = chartHeight - (i * chartHeight / numYLabels);

      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < readings.length; i++) {
      final reading = readings[i];
      final x = leftPadding + (i / (readings.length - 1)) * chartWidth;
      final y = chartHeight - ((reading.value - yMin) / yRange * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final reading = readings[i];
      final point = points[i];

      // Determine point color based on value
      Color pointColor = lineColor;
      if (normalMin != null && normalMax != null) {
        if (reading.value < normalMin! || reading.value > normalMax!) {
          pointColor = Colors.red;
        } else {
          pointColor = Colors.green;
        }
      }

      // Draw outer circle
      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, outerPaint);

      // Draw inner circle
      final innerPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, innerPaint);

      // Draw date label for first and last point
      if (i == 0 || i == points.length - 1) {
        final dateText = _formatDate(reading.date);
        textPainter.text = TextSpan(
          text: dateText,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            point.dx - textPainter.width / 2,
            chartHeight + 8,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  @override
  bool shouldRepaint(LabChartPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}