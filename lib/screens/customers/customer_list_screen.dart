import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import 'add_edit_customer_screen.dart';

class CustomerListScreen extends StatelessWidget {
  CustomerListScreen({Key? key}) : super(key: key);

  final CustomerService _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: FutureBuilder<List<Customer>>(
        future: _customerService.getAllCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }

          return ListView.builder(
            itemCount: customers.length,
            // Add these properties for smoother scrolling
            physics: const AlwaysScrollableScrollPhysics(),
            addAutomaticKeepAlives: true,
            cacheExtent: 400, // Cache more items offscreen
            itemBuilder: (context, index) {
              final customer = customers[index];
              return CustomerListItem(
                customer: customer,
                onEditPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditCustomerScreen(customer: customer),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Customer',
      ),
    );
  }
}

// Extracted to a separate widget for better performance
class CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEditPressed;

  const CustomerListItem({
    Key? key,
    required this.customer,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(customer.id), // Helps Flutter identify items uniquely
      title: Text(customer.name),
      subtitle: Text(
        'Phone: ${customer.phone}\nPlan: ₹${customer.monthlyPlan}',
      ),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onEditPressed,
      ),
    );
  }
}
