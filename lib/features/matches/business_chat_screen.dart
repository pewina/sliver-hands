import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/models/opportunity.dart';
import '../../shared/widgets/voice_button.dart';
import 'mock_matching_repository.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen({
    super.key,
    required this.opportunity,
    required this.business,
  });

  final Opportunity opportunity;
  final BusinessProfile business;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final List<_Message> _messages = [
    const _Message(
      'Namaste Savita! We are delighted to work with you on the festival hampers.',
      false,
    ),
    const _Message('Would you like to join the seller collaboration?', false),
  ];

  void _sendHello() {
    setState(() {
      _messages.add(
        const _Message(
          'Namaste! I am interested and would like to know more.',
          true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.business.businessName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const Text('Matched business', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: AppColors.cream,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Center(
                    child: Text(
                      'Today',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._messages.map(
                    (message) => Align(
                      alignment: message.mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 11),
                        padding: const EdgeInsets.all(13),
                        constraints: const BoxConstraints(maxWidth: 290),
                        decoration: BoxDecoration(
                          color: message.mine ? AppColors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.3,
                            color: message.mine ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sendHello,
                      icon: const Icon(Icons.waving_hand_rounded),
                      label: const Text('Send hello'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  VoiceButton(label: 'Voice', onTap: _sendHello),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  const _Message(this.text, this.mine);

  final String text;
  final bool mine;
}
