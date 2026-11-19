import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/repositories/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _newEmail = TextEditingController();
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _newEmail.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () =>
              _message = switch (e.code) {
                'requires-recent-login' ||
                'invalid-credential' ||
                'wrong-password' =>
                  'اكتب كلمة السر الحالية الصحيحة أو سجل الدخول من جديد',
                'weak-password' => 'كلمة السر الجديدة ضعيفة',
                'email-already-in-use' => 'الإيميل الجديد مستخدم بالفعل',
                _ => 'تعذر تنفيذ العملية. تأكد من الاتصال والبيانات وحاول تاني',
              },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message =
                  'تعذر تنفيذ العملية. أكمل الرحلة النشطة أولاً وتحقق من البيانات',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reauth() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (_currentPassword.text.isEmpty) {
      throw StateError('اكتب كلمة السر الحالية');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('سجل الدخول أولاً')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الأمان والخصوصية')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('إيميل تسجيل الدخول: ${user.email ?? ''}'),
              Text(user.emailVerified ? 'الإيميل مفعّل' : 'الإيميل غير مفعّل'),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => _run(
                          user.sendEmailVerification,
                          'أرسلنا رسالة تفعيل للإيميل',
                        ),
                child: const Text('إرسال رسالة تفعيل'),
              ),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => _run(user.reload, 'تم تحديث حالة الحساب'),
                child: const Text('تحديث حالة التفعيل'),
              ),
              const Divider(),
              const Text(
                'تأكيد هويتك مطلوب لتغيير الإيميل أو كلمة السر أو حذف الحساب.',
              ),
              TextField(
                controller: _currentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة السر الحالية',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة السر الجديدة (٨ أحرف على الأقل)',
                ),
              ),
              OutlinedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _run(() async {
                          if (_newPassword.text.length < 8) {
                            throw ArgumentError('كلمة السر ضعيفة');
                          }
                          await _reauth();
                          await user.updatePassword(_newPassword.text);
                          _newPassword.clear();
                        }, 'تم تغيير كلمة السر'),
                child: const Text('تغيير كلمة السر'),
              ),
              TextField(
                controller: _newEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'الإيميل الجديد'),
              ),
              OutlinedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _run(
                          () async {
                            await _reauth();
                            await user.verifyBeforeUpdateEmail(
                              _newEmail.text.trim(),
                            );
                          },
                          'أرسلنا رابط تأكيد للإيميل الجديد. الإيميل القديم يفضل فعال لحد ما تأكد الجديد',
                        ),
                child: const Text('تأكيد تغيير الإيميل'),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              if (_busy) const LinearProgressIndicator(),
              const Divider(),
              const Text('الخصوصية', style: TextStyle(fontSize: 22)),
              const Text(
                'نحفظ بيانات حسابك وعناوين رحلاتك ومحادثاتها في Firebase. السائق المعتمد يرى طلبات نوع مركبته أثناء توفره؛ وبعد القبول يطلع طرفا الرحلة فقط على المحادثة. مشاركة موقع السائق اختيارية أثناء فتح شاشة السائق. البحث عن العناوين يرسل النص لخدمة Photon، والخريطة تحمل صوراً من OpenStreetMap. لا نجمع بيانات بطاقات ولا ننفذ دفعاً إلكترونياً.',
              ),
              const SizedBox(height: 12),
              const Text(
                'حذف الحساب يزيل ملفك الشخصي وطلب السائق وعلامات قراءة الإشعارات. سجلات الرحلات والمحادثات والتقييمات تظل محفوظة لأغراض متابعة الرحلات؛ لطلب مراجعة حذفها تواصل مع مسؤول المشروع. لا تضع بيانات شخصية في بلاغ GitHub عام.',
              ),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('حذف الحساب؟'),
                                  content: const Text(
                                    'هتحتاج تعمل حساب جديد بعد الحذف. سجلات الرحلات السابقة لا يتم حذفها تلقائياً.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('رجوع'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('حذف حسابي'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmed == true && context.mounted) {
                            final repository = context.read<AuthRepository>();
                            _run(() async {
                              await _reauth();
                              await repository.deleteAccount();
                            }, 'تم حذف الحساب');
                          }
                        },
                child: const Text('حذف حسابي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المساعدة والدعم')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('توصيلة • مساعدة', style: TextStyle(fontSize: 24)),
            const Text(
              'حدد نقطتي الانطلاق والوجهة على الخريطة أو ابحث عن العنوان ثم راجع العلامة. الطلب يفضل في البحث لحد قبول سائق معتمد. تقدر تلغي قبل بداية الرحلة. الدفع كاش عند الوصول؛ لا تدخل أي بيانات بطاقة.',
            ),
            const SizedBox(height: 16),
            const Text(
              'لو الاتصال انقطع، افتح الرئيسية واضغط استعادة الرحلة. الرحلة المكتملة تظهر في السجل حتى لو أغلقت التطبيق قبل التقييم.',
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد خدمة طوارئ أو دعم فوري داخل هذه النسخة. للإبلاغ عن مشكلة تقنية افتح بلاغاً بدون أسماء أو عناوين أو أرقام تليفون.',
            ),
            OutlinedButton(
              onPressed:
                  () => launchUrl(
                    Uri.parse(
                      'https://github.com/gamal6507-ops/Tawsela/issues',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
              child: const Text('الإبلاغ عن مشكلة تقنية'),
            ),
          ],
        ),
      ),
    ),
  );
}
