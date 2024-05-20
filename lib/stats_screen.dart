import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats'),
      ),
      body: _buildStats(),
    );
  }

  Widget _buildStats() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Process the data to prepare for chart rendering
        final List<ExpenseData> data = _processData(snapshot.data!.docs);

        // Create and display the bar chart
        return _buildChart(data);
      },
    );
  }

  List<ExpenseData> _processData(List<QueryDocumentSnapshot> docs) {
    // Process Firestore documents to get data for the chart
    List<ExpenseData> data = [];
    docs.forEach((doc) {
      final category = doc['category'];
      final expense = doc['expense'];
      data.add(ExpenseData(category, expense));
    });
    return data;
  }

  Widget _buildChart(List<ExpenseData> data) {
    // Create series list for the chart
    final List<charts.Series<ExpenseData, String>> series = [
      charts.Series(
        id: 'Expenses',
        data: data,
        domainFn: (ExpenseData expense, _) => expense.category,
        measureFn: (ExpenseData expense, _) => expense.amount,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      )
    ];

    // Create the chart
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: charts.BarChart(
          series,
          animate: true,
          barRendererDecorator: charts.BarLabelDecorator<String>(),
          domainAxis: charts.OrdinalAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(labelRotation: 45),
          ),
          primaryMeasureAxis: charts.NumericAxisSpec(
            tickProviderSpec: charts.BasicNumericTickProviderSpec(
              desiredTickCount: 5,
            ),
          ),
        ),
      ),
    );
  }
}

// Model class for expense data
class ExpenseData {
  final String category;
  final double amount;

  ExpenseData(this.category, this.amount);
}
