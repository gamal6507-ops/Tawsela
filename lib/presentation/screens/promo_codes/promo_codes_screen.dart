import 'package:flutter/material.dart';

class PromoCodesScreen extends StatelessWidget {
  const PromoCodesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('العروض والخصومات')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'مفيش عروض أو أكواد خصم مفعّلة حالياً. السعر المعروض قبل الحجز هو الأجرة المتفق عليها.',
        ),
      ),
    ),
  );
}
