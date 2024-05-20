import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  bool _isLoading = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _getSmsMessages();
  }

  Future<void> _getSmsMessages() async {
    setState(() => _isLoading = true);
    var permission = await Permission.sms.request();
    if (permission.isGranted) {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );
      if (messages != null) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } else {
        // Handle null messages
        setState(() => _isLoading = false);
      }
    } else {
      // Handle permission denied
      debugPrint('Permission denied');
      setState(() => _isLoading = false);
    }
  }

  ExpenseDetails? _extractExpense(SmsMessage message) {
    // Default values for expense details
    String credOrDebt = 'Unknown';
    DateTime date = message.date ?? DateTime.now();
    double amount = 0.0;

    // Extracting message body
    String? messageBody = message.body;

    // If messageBody is null, return default values
    if (messageBody != null) {
      // Convert message body to lowercase for case-insensitive matching
      final lowercaseBody = messageBody.toLowerCase();

      // Check if the message body contains "credit" or "debit" followed by an amount
      final creditMatch =
          RegExp(r'a\/c\s+credit:rs\.\s*([\d.]+)').firstMatch(lowercaseBody);
      final debitMatch =
          RegExp(r'a\/c\s+debit:rs\.\s*([\d.]+)').firstMatch(lowercaseBody);

      if (creditMatch != null) {
        // Extract credit amount
        credOrDebt = 'CREDIT: Rs.${creditMatch.group(1)}';
        amount = double.tryParse(creditMatch.group(1)!) ?? 0.0;
      } else if (debitMatch != null) {
        // Extract debit amount
        credOrDebt = 'DEBIT: Rs.${debitMatch.group(1)}';
        amount = double.tryParse(debitMatch.group(1)!) ?? 0.0;
      }
    }

    // Check if the expense details are unknown
    if (credOrDebt == 'Unknown') {
      return null;
    }

    // Print expense details in the terminal
    print('Expense Details:');
    print('  CredOrDebt: $credOrDebt');
    print('  Date: $date');
    print('  Amount: $amount');

    // Return expense details
    return ExpenseDetails(
      credOrDebt: credOrDebt,
      date: date,
      amount: amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Inbox Parsing'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages to show.\n Tap refresh button...',
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final expenseDetails = _extractExpense(message);
                          if (expenseDetails == null) {
                            return SizedBox.shrink();
                          }
                          final formattedDateTime = message.date is DateTime
                              ? DateTime.fromMillisecondsSinceEpoch(
                                      message.date!.millisecondsSinceEpoch)
                                  .toString()
                              : "Unknown Date";
                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDateTime,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  expenseDetails.credOrDebt,
                                  style: TextStyle(
                                    color: expenseDetails.credOrDebt
                                            .contains('CREDIT')
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      FloatingActionButton(
                        onPressed: _getSmsMessages,
                        child: Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            List<ExpenseDetails> expenses = [];
            _messages.forEach((message) {
              final expenseDetails = _extractExpense(message);
              if (expenseDetails != null &&
                  (expenseDetails.credOrDebt.contains('CREDIT') ||
                      expenseDetails.credOrDebt.contains('DEBIT'))) {
                expenses.add(expenseDetails);
              }
            });
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ListPage(expenses: expenses)));
          }
        },
      ),
    );
  }
}

class ListPage extends StatelessWidget {
  final List<ExpenseDetails> expenses;

  ListPage({required this.expenses});

  @override
  Widget build(BuildContext context) {
    double totalCredit = 0.0;
    double totalDebit = 0.0;

    expenses.forEach((expense) {
      if (expense.credOrDebt.contains('CREDIT')) {
        totalCredit += expense.amount;
      } else if (expense.credOrDebt.contains('DEBIT')) {
        totalDebit += expense.amount;
      }
    });

    double netSpend = totalCredit - totalDebit;

    return Scaffold(
      appBar: AppBar(
        title: Text('List'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Net Spend: Rs. ${netSpend.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Credited Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Debited Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: expenses.map((expense) {
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(expense.date.toString())),
                    DataCell(Text(expense.credOrDebt.contains('CREDIT')
                        ? expense.amount.toString()
                        : '-')),
                    DataCell(Text(expense.credOrDebt.contains('DEBIT')
                        ? expense.amount.toString()
                        : '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseDetails {
  final String credOrDebt;
  final DateTime date;
  final double amount;

  ExpenseDetails({
    required this.credOrDebt,
    required this.date,
    required this.amount,
  });
}
