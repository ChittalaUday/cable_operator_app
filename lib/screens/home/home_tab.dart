import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../widgets/monthly_overview_widget.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Payment>>(
      stream: PaymentService.getAllPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                MonthlyOverviewWidget(
                  allPayments: payments,
                  selectedDate: _selectedDate,
                  onMonthSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                // Add more widgets below the monthly overview if needed
              ],
            ),
          ),
        );
      },
    );
  }
}
