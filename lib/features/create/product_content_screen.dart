import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../core/demo_store.dart';
import 'api_content_generation_service.dart';
import 'content_generation_service.dart';

/// SilverHands AI Content Creator.
///
/// The creator is intentionally profile-driven: the user does not have to
/// type a product description again. It reads the skills identified during
/// voice onboarding, asks Gemini for marketing copy, then turns that copy into
/// a WhatsApp-ready message and an in-app poster preview.
class ProductContentScreen extends StatefulWidget {
  const ProductContentScreen({super.key, this.service});

  final ContentGenerationService? service;

  @override
  State<ProductContentScreen> createState() => _ProductContentScreenState();
}

class _ProductContentScreenState extends State<ProductContentScreen> {
  late ContentGenerationService _service;
  ProductContent? _content;
  bool _generating = true;
  int _selectedChannel = 0;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _businessImageBytes;

  @override
  void initState() {
    super.initState();
    _service = widget.service ??
        (AppConfig.hasSupabase
            ? ApiContentGenerationService()
            : const MockContentGenerationService());
    Future<void>.microtask(_generateFromProfile);
  }

  List<String> get _skills => DemoStore.instance.skills;

  String get _name =>
      DemoStore.instance.profile['display_name']?.toString() ??
      'SilverHands Creator';

  String get _location =>
      DemoStore.instance.profile['location']?.toString() ?? 'Chennai';

  int get _years => DemoStore.instance.experienceYears;

  String get _language => DemoStore.instance.language;

  String get _skillTitle {
    final skills = _skills;
    if (skills.isEmpty) return 'My Home-Based Services';
    if (skills.length == 1) return _businessNameForSkill(skills.first);
    return skills.take(2).map(_businessNameForSkill).join(' & ');
  }

  String get _profileDescription {
    final skills = _skills.isEmpty ? ['practical skills'] : _skills;
    final experience = _years > 0 ? '$_years years of experience' : 'hands-on experience';
    return 'A SilverHands creator offering ${skills.join(', ')} with $experience in $_location. '
        'Create simple, trustworthy content that helps nearby customers discover these skills.';
  }

  String _businessNameForSkill(String skill) {
    final x = skill.toLowerCase();
    if (x.contains('pickle')) return 'Homemade Pickles';
    if (x.contains('cook') || x.contains('food') || x.contains('meal')) return 'Homemade Traditional Food';
    if (x.contains('tailor') || x.contains('stitch') || x.contains('sew')) return 'Custom Tailoring & Stitching';
    if (x.contains('embroider')) return 'Hand Embroidery';
    if (x.contains('handicraft') || x.contains('craft')) return 'Handmade Crafts';
    if (x.contains('teach') || x.contains('tutor') || x.contains('mentor')) return 'Home Tutoring & Mentoring';
    if (x.contains('garden') || x.contains('plant')) return 'Home Gardening Services';
    if (x.contains('child')) return 'Trusted Childcare Support';
    return skill;
  }

  String get _businessCategory {
    final text = '${_skillTitle} ${_skills.join(' ')}'.toLowerCase();
    if (RegExp(r'pickle|cook|food|bakery|catering|sweet|snack|meal').hasMatch(text)) return 'Food / Culinary';
    if (RegExp(r'tailor|stitch|embroider|sew|fashion|blouse|dress|clothing').hasMatch(text)) return 'Tailoring / Fashion';
    if (RegExp(r'handicraft|craft|pottery|weav|basket|art|jewell').hasMatch(text)) return 'Handicrafts / Art';
    if (RegExp(r'tutor|teach|education|mentor|class|math|english').hasMatch(text)) return 'Tutoring / Education';
    if (RegExp(r'beauty|salon|makeup|hair|mehendi|henna').hasMatch(text)) return 'Beauty / Salon';
    if (RegExp(r'garden|plant|nursery|flower|organic').hasMatch(text)) return 'Gardening / Plants';
    if (RegExp(r'repair|plumb|electric|carp|clean|home service').hasMatch(text)) return 'Home Services';
    if (RegExp(r'photo|camera|video|design|creative').hasMatch(text)) return 'Creative Services';
    if (RegExp(r'traditional|classical|dance|music|culture|rangoli|kolam').hasMatch(text)) return 'Traditional Arts';
    return 'Local Services';
  }

  ({Color primary, Color secondary, Color accent, IconData icon}) _themeForCategory(String category) {
    switch (category) {
      case 'Food / Culinary': return (primary: const Color(0xFF7A351F), secondary: const Color(0xFFF4D7A1), accent: const Color(0xFFFFB347), icon: Icons.restaurant_rounded);
      case 'Tailoring / Fashion': return (primary: const Color(0xFF4A234F), secondary: const Color(0xFFF1D9E8), accent: const Color(0xFFE7A6C5), icon: Icons.checkroom_rounded);
      case 'Handicrafts / Art': return (primary: const Color(0xFF5B3A29), secondary: const Color(0xFFE8D5BE), accent: const Color(0xFFD69A5B), icon: Icons.palette_rounded);
      case 'Tutoring / Education': return (primary: const Color(0xFF164A63), secondary: const Color(0xFFD9EDF5), accent: const Color(0xFF62B5D0), icon: Icons.menu_book_rounded);
      case 'Beauty / Salon': return (primary: const Color(0xFF5B284D), secondary: const Color(0xFFF2D9E8), accent: const Color(0xFFE8A4C4), icon: Icons.spa_rounded);
      case 'Gardening / Plants': return (primary: const Color(0xFF285B3D), secondary: const Color(0xFFDCECD8), accent: const Color(0xFF86B96F), icon: Icons.local_florist_rounded);
      case 'Home Services': return (primary: const Color(0xFF23455C), secondary: const Color(0xFFDDE9EF), accent: const Color(0xFF6FA6C5), icon: Icons.handyman_rounded);
      case 'Creative Services': return (primary: const Color(0xFF302A63), secondary: const Color(0xFFE1DFF5), accent: const Color(0xFF958DE0), icon: Icons.camera_alt_rounded);
      case 'Traditional Arts': return (primary: const Color(0xFF6B321F), secondary: const Color(0xFFF1DDC4), accent: const Color(0xFFD79B62), icon: Icons.auto_awesome_rounded);
      default: return (primary: AppColors.teal, secondary: const Color(0xFFD9F0EC), accent: const Color(0xFFFFD694), icon: Icons.storefront_rounded);
    }
  }

  String _headlineForCategory(String category) {
    switch (category) {
      case 'Food / Culinary': return 'Freshly Made. Just for You.';
      case 'Tailoring / Fashion': return 'Stitched With Skill.';
      case 'Handicrafts / Art': return 'Handcrafted With Care.';
      case 'Tutoring / Education': return 'Learn. Grow. Succeed.';
      case 'Beauty / Salon': return 'Feel Confident. Feel Beautiful.';
      case 'Gardening / Plants': return 'Bring Nature Home.';
      case 'Home Services': return 'Trusted Skills. Reliable Service.';
      case 'Creative Services': return 'Bring Your Ideas to Life.';
      case 'Traditional Arts': return 'Tradition, Crafted With Heart.';
      default: return 'Made With Skill. Made For You.';
    }
  }

  String _ctaForCategory(String category) {
    switch (category) {
      case 'Tutoring / Education': return 'ENQUIRE NOW';
      case 'Home Services': return 'BOOK NOW';
      case 'Creative Services': return 'CONTACT NOW';
      case 'Food / Culinary': return 'ORDER NOW';
      default: return 'VIEW PROFILE';
    }
  }

  String _profileQrData() {
    if (AppConfig.hasSupabase) {
      final id = Supabase.instance.client.auth.currentUser?.id;
      if (id != null && id.isNotEmpty) {
        return 'silverhands://profile/$id';
      }
    }
    return 'silverhands://profile/${_name.replaceAll(' ', '-').toLowerCase()}';
  }

  Future<void> _pickBusinessImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1400);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _businessImageBytes = bytes);
    } catch (error) {
      debugPrint('Poster image error: $error');
      if (mounted) _showMessage('Could not load the photo. Please try again.');
    }
  }

  Future<void> _generateFromProfile() async {
    if (!mounted) return;
    setState(() => _generating = true);

    final productName = _skillTitle;
    final description = _profileDescription;

    try {
      final generated = await _service.generateFromProductPhoto(
        productName: productName,
        productDescription: description,
        language: _language,
      );

      if (!mounted) return;
      setState(() {
        _content = generated;
        _generating = false;
      });
    } catch (error) {
      // The creator must remain usable for a hackathon demo even if the AI
      // service is temporarily unavailable. Fall back to deterministic copy.
      debugPrint('Content creator API error: $error');
      try {
        final fallback = await const MockContentGenerationService().generateFromProductPhoto(
          productName: productName,
          productDescription: description,
          language: _language,
        );
        if (!mounted) return;
        setState(() {
          _content = fallback;
          _generating = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _generating = false);
      }
    }
  }

  String get _activeContent {
    final content = _content!;
    switch (_selectedChannel) {
      case 1:
        return content.instagramCaption;
      case 2:
        return content.facebookPost;
      default:
        return content.whatsAppStatus;
    }
  }

  Future<void> _shareToWhatsApp() async {
    if (_content == null) return;

    final message = _content!.whatsAppStatus;
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('WhatsApp could not be opened. The message is copied instead.');
        await Clipboard.setData(ClipboardData(text: message));
      }
    } catch (error) {
      debugPrint('WhatsApp launch error: $error');
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        _showMessage('WhatsApp is unavailable here. Message copied for you.');
      }
    }
  }

  Future<void> _copyWhatsApp() async {
    if (_content == null) return;
    await Clipboard.setData(ClipboardData(text: _content!.whatsAppStatus));
    if (mounted) _showMessage('WhatsApp message copied ✓');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Content Creator'),
        backgroundColor: AppColors.cream,
      ),
      body: SafeArea(
        child: _generating
            ? _loadingView()
            : RefreshIndicator(
                onRefresh: _generateFromProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                  children: [
                    _heroCard(),
                    const SizedBox(height: 18),
                    _skillsCard(),
                    const SizedBox(height: 18),
                    _posterCard(),
                    const SizedBox(height: 20),
                    _channelCard(),
                    const SizedBox(height: 16),
                    _whatsappCard(),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _generating ? null : _generateFromProfile,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Regenerate from my latest skills'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI-generated content is based only on the skills and experience in your SilverHands profile. Review before sharing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF56615C)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD694),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 44,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Creating your content…',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'SilverHands AI is turning your ${_skills.isEmpty ? 'skills' : _skills.join(', ')} into customer-ready content.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Card(
      color: const Color(0xFF0B827D),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFFFD694),
              child: Icon(Icons.campaign_rounded, color: AppColors.teal, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your AI promotion kit is ready!',
                    style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Created automatically from $_name’s identified skills.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI used these profile details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...(_skills.isEmpty ? ['Skills pending'] : _skills).map(
                  (skill) => Chip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: Text(skill),
                  ),
                ),
                if (_years > 0)
                  Chip(label: Text('$_years years experience')),
                Chip(label: Text(_language)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterCard() {
    final category = _businessCategory;
    final theme = _themeForCategory(category);
    final headline = _headlineForCategory(category);
    final offering = _skillTitle;
    final description = _profileDescription;
    final cta = _ctaForCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. AI-created business advertisement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('$category • automatically adapted from your identified skills', style: const TextStyle(color: Color(0xFF56615C))),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.secondary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(blurRadius: 20, offset: Offset(0, 9), color: Color(0x26000000))],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_businessImageBytes != null)
                  Image.memory(_businessImageBytes!, fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.secondary, theme.primary],
                      ),
                    ),
                    child: Center(child: Icon(theme.icon, size: 110, color: theme.accent.withValues(alpha: 0.8))),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.55, 0.82, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.62),
                          Colors.transparent,
                          Colors.transparent,
                          theme.primary.withValues(alpha: 0.74),
                          theme.primary,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  right: 18,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(16)),
                        child: Text('SILVERHANDS', style: TextStyle(color: theme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
                        child: Icon(theme.icon, color: theme.primary, size: 20),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 143,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.03, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(_name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.accent, fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(offering, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.5, height: 1.25)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(14)),
                        child: Text(cta, style: TextStyle(color: theme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        QrImageView(
                          data: _profileQrData(),
                          size: 70,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SCAN TO VIEW PROFILE', style: TextStyle(color: theme.primary, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                              const SizedBox(height: 4),
                              Text(_location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF56615C), fontSize: 10)),
                              const SizedBox(height: 3),
                              const Text('Powered by SilverHands', style: TextStyle(color: Color(0xFF56615C), fontSize: 8.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickBusinessImage,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: Text(_businessImageBytes == null ? 'Add business photo' : 'Change photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text('The poster automatically adapts its visual style, headline, CTA and QR section to the identified skill category.', style: TextStyle(color: Color(0xFF56615C))),
      ],
    );
  }

  Widget _channelCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Content for each social channel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, icon: Icon(Icons.chat_rounded), label: Text('WhatsApp')),
            ButtonSegment(value: 1, icon: Icon(Icons.camera_alt_rounded), label: Text('Instagram')),
            ButtonSegment(value: 2, icon: Icon(Icons.public_rounded), label: Text('Facebook')),
          ],
          selected: {_selectedChannel},
          onSelectionChanged: (value) => setState(() => _selectedChannel = value.first),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SelectableText(
              _activeContent,
              style: const TextStyle(fontSize: 17, height: 1.55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _whatsappCard() {
    return Card(
      color: const Color(0xFFEAF7F1),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_rounded, color: Color(0xFF168C5A), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '3. Share directly on WhatsApp',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The WhatsApp version is written specifically as a short customer message. Tap below to open WhatsApp with the message ready to send.',
              style: TextStyle(fontSize: 15.5, height: 1.45),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _shareToWhatsApp,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Share to WhatsApp'),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyWhatsApp,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy WhatsApp message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
