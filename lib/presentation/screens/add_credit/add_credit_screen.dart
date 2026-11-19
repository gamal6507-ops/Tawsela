import 'package:flutter/material.dart';

class AddCreditScreen extends StatelessWidget {
  const AddCreditScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('طرق الدفع')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'الدفع المتاح حالياً كاش عند الوصول. الشحن الإلكتروني والبطاقات غير متاحين.',
        ),
      ),
    ),
  );
}
