import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  const ChatScreen({super.key, required this.requestId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;
  late final _messages = FirebaseFirestore.instance
      .collection('ride_requests')
      .doc(widget.requestId)
      .collection('messages');
  late final _stream =
      _messages.orderBy('sentAt', descending: true).limit(100).snapshots();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (_sending || text.isEmpty || text.length > 1000) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _messages.add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _text.clear();
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال الرسالة. حاول تاني');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('محادثة الرحلة')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'لا تشارك بيانات بطاقتك أو كلمات السر. المحادثة متاحة لطرفي الرحلة فقط.',
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'تعذر تحميل المحادثة أو ليس لديك صلاحية لهذه الرحلة',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ابدأ المحادثة'));
                  }
                  return ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    children:
                        snapshot.data!.docs.map((doc) {
                          final m = doc.data();
                          return Align(
                            alignment:
                                m['senderId'] ==
                                        FirebaseAuth.instance.currentUser?.uid
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(m['text'] as String),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            if (_error != null) Text(_error!),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة',
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إرسال',
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
