import 'package:flutter/material.dart';
import 'package:newapp/account_screen.dart';
import 'package:newapp/auth/auth_service.dart';
import 'package:newapp/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newapp/ocr_screen.dart';
import 'package:newapp/profile_screen.dart';
import 'package:newapp/widgets/button.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();

  int _selectedIndex = 0;

  TextEditingController _categoryController = TextEditingController();
  TextEditingController _expenseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {},
            ),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signout();
              goToLogin(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            Text(
              "Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildExpenseList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.data_exploration),
          label: 'Account summary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.data_exploration),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => StatsScreen()));
        } else if (index == 2) {
          _showAddExpenseDialog(context);
        } else if (index == 0) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AccountScreen()));
          // MaterialPageRoute(builder: (context) => ProfileScreen()));
        }
      },
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showManualEntryDialog(context);
                },
                child: Text('Manual Entry'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _scanExpense();
                },
                child: Text('Scan'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manual Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                ),
              ),
              TextField(
                controller: _expenseController,
                decoration: InputDecoration(
                  labelText: 'Expense',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveExpenseToFirestore();
                _categoryController.clear();
                _expenseController.clear();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _scanExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OcrScreen()),
    );
    // Implement your logic for scanning expenses here
    // For example, you can use a package like barcode_scan to scan barcodes
  }

  void _saveExpenseToFirestore() async {
    String category = _categoryController.text;
    double expense = double.tryParse(_expenseController.text) ?? 0;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('category', isEqualTo: category)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        double currentExpense = documentSnapshot['expense'];
        await documentSnapshot.reference
            .update({'expense': currentExpense + expense});
      } else {
        await FirebaseFirestore.instance.collection('expenses').add({
          'category': category,
          'expense': expense,
          'timestamp': Timestamp.now(),
        });
      }
      print('Expense saved to Firestore');
    } catch (e) {
      print('Error saving expense: $e');
    }
  }

  Widget _buildExpenseList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final expenses = snapshot.data!.docs;

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final category = expense['category'];
            final expenseAmount = expense['expense'];

            return ListTile(
              title: Text(category),
              subtitle: Text('Expense: $expenseAmount'),
            );
          },
        );
      },
    );
  }
}
