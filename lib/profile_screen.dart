import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Expenses',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            _buildTotalExpenses(),
            SizedBox(height: 20.0),
            Text(
              'Most Spent Category',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            _buildMostSpentCategory(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalExpenses() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        double totalExpenses = 0;
        snapshot.data!.docs.forEach((expense) {
          totalExpenses += (expense['expense'] ?? 0.0) as double;
        });

        return Text(
          '\$$totalExpenses',
          style: TextStyle(
            fontSize: 18.0,
          ),
        );
      },
    );
  }

  Widget _buildMostSpentCategory() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        Map<String, double> categoryExpenses = {};
        snapshot.data!.docs.forEach((expense) {
          String category = expense['category'] ?? '';
          double amount = (expense['expense'] ?? 0.0) as double;
          categoryExpenses.update(category, (value) => value + amount,
              ifAbsent: () => amount);
        });

        String mostSpentCategory = '';
        double maxAmount = 0;
        categoryExpenses.forEach((category, amount) {
          if (amount > maxAmount) {
            maxAmount = amount;
            mostSpentCategory = category;
          }
        });

        return Text(
          mostSpentCategory.isNotEmpty ? mostSpentCategory : 'N/A',
          style: TextStyle(
            fontSize: 18.0,
          ),
        );
      },
    );
  }
}
