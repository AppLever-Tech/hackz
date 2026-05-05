import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../common/dashboard_components.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirestoreUtils.getDepartmentPayments(
        orgId: user.orgId,
        department: user.departmentCode,
      ),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load payments: ${snapshot.error}');
        }
        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        return SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Payments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Text('No payment records found.')
              else
                ...rows.map((row) {
                  final faculty = row['user'] as UserModel;
                  final total = (row['totalPayment'] as double?) ?? 0;
                  final history = (row['history'] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('${faculty.firstName} ${faculty.lastName}'.trim()),
                    subtitle: Text('Total Payment: ${total.toStringAsFixed(2)}'),
                    children: history.isEmpty
                        ? const <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text('No payment history'),
                              ),
                            ),
                          ]
                        : history
                            .map(
                              (h) => Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Amount: ${((h['amount'] as num?) ?? 0).toString()} | ${((h['dateLabel'] as String?) ?? 'Date N/A')}',
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
