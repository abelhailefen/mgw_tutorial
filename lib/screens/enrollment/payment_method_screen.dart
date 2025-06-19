import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/screens/enrollment/order_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Semester semester;

  const PaymentMethodScreen({Key? key, required this.semester}) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int? _selectedIndex;
  String? _dummyAcc;

  final List<Map<String, String>> _methods = [
    {'name': 'telebirr', 'logo': 'assets/images/telebirr.png'},
    {'name': 'CBEBirr', 'logo': 'assets/images/cbe.png'},
    {'name': 'M-Pesa', 'logo': 'assets/images/mpesa.png'},
    {'name': 'Kacha', 'logo': 'assets/images/kacha.png'},
    {'name': 'Enat Bank', 'logo': 'assets/images/enatbank.png'},
  ];

  final Map<String, String> _dummyAccounts = {
    'telebirr': '0900000000',
    'CBEBirr': '1000123456789',
    'M-Pesa': '0703000000',
    'Kacha': '9897564',
    'Enat Bank': '43567',
  };

  void _onMethodTap(int index) {
    setState(() {
      _selectedIndex = index;
      _dummyAcc = _dummyAccounts[_methods[index]['name']!];
    });
  }

  void _proceedToOrder() {
    if (_selectedIndex != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderScreen(
            semesterToEnroll: widget.semester,
            bankName: _methods[_selectedIndex!]['name'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showAccount = _selectedIndex != null && _dummyAcc != null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Choose Payment Method'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                // Amount to pay
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Amount to Pay\n${widget.semester.price} ETB',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),

                // Show dummy account after method selection
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: showAccount
                      ? Container(
                          key: ValueKey(_dummyAcc),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200, width: 1),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Account Number for ${_methods[_selectedIndex!]['name']!}",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 7),
                              SelectableText(
                                _dummyAcc!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Please pay to this account and upload your screenshot.",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text("Proceed"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                                ),
                                onPressed: _proceedToOrder,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Payment methods grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9,
                    children: List.generate(_methods.length, (index) {
                      return GestureDetector(
                        onTap: () => _onMethodTap(index),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedIndex == index
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: _selectedIndex == index
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.shade100,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Image.asset(
                                _methods[index]['logo']!,
                                height: 42,
                                width: 42,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _methods[index]['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _selectedIndex == index
                                    ? Colors.green.shade700
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 26),
                const Icon(Icons.lock, size: 36, color: Colors.black54),
                const Text("Secured By Chapa"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}