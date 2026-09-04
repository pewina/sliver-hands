import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../core/demo_store.dart';
import 'api_content_generation_service.dart';
import 'content_generation_service.dart';

class ProductContentScreen extends StatefulWidget {
  const ProductContentScreen({
    super.key,
    this.service,
  });

  final ContentGenerationService? service;

  @override
  State<ProductContentScreen> createState() => _ProductContentScreenState();
}

class _ProductContentScreenState extends State<ProductContentScreen> {
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _businessController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _priceController =
      TextEditingController();

  final TextEditingController _skillsController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _publishing = false;
  bool _analysing = false;

  late ContentGenerationService _service;
  ProductContent? _content;

  int _selectedChannel = 0;

  String _category = 'Product';

  @override
  void initState() {
    super.initState();
    _service = widget.service ??
        (AppConfig.hasSupabase
            ? ApiContentGenerationService()
            : const MockContentGenerationService());
    final store = DemoStore.instance;
    final skills = store.skills;
    final name = store.profile['display_name']?.toString() ?? '';
    final bio = store.profile['bio']?.toString() ?? '';

    // The content creator starts from the skills identified during voice
    // onboarding. The user can still edit every field before generating.
    if (name.isNotEmpty && name != 'SilverHands Member') {
      _businessController.text = name;
    }
    if (skills.isNotEmpty) {
      _skillsController.text = skills.join(', ');
      _titleController.text = skills.first;
    }
    if (bio.isNotEmpty && !bio.startsWith('Your SilverHands profile')) {
      _descriptionController.text = bio;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _businessController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      // Keep the bytes in memory so the preview works on Flutter Web too.
      // Image.file/File is not supported by Flutter Web.
      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      debugPrint('Image picker error: $error');

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not choose the image. Please try again.',
      );
    }
  }

  // ============================================================
  // PUBLISH OPPORTUNITY
  // ============================================================

  Future<void> _publish() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before publishing.',
      );
      return;
    }

    // ----------------------------------------------------------
    // Validation
    // ----------------------------------------------------------

    if (_titleController.text.trim().isEmpty) {
      _showMessage(
        'Please enter a title.',
      );
      return;
    }

    if (_businessController.text.trim().isEmpty) {
      _showMessage(
        'Please enter your business name.',
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage(
        'Please enter a description.',
      );
      return;
    }

    if (_selectedImage == null) {
      _showMessage(
        'Please choose a product image.',
      );
      return;
    }

    setState(() {
      _publishing = true;
    });

    try {
      final supabase =
          Supabase.instance.client;

      // --------------------------------------------------------
      // 1. Read image
      // --------------------------------------------------------

      final imageBytes =
          await _selectedImage!.readAsBytes();

      // --------------------------------------------------------
      // 2. Determine extension
      // --------------------------------------------------------

      final String extension =
          _selectedImage!.name.contains('.')
              ? _selectedImage!
                  .name
                  .split('.')
                  .last
                  .toLowerCase()
              : 'jpg';

      // --------------------------------------------------------
      // 3. Create unique storage path
      // --------------------------------------------------------

      final String filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      // --------------------------------------------------------
      // 4. Upload to Supabase Storage
      // --------------------------------------------------------

      await supabase.storage
          .from('product-images')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: _contentType(extension),
              upsert: false,
            ),
          );

      // --------------------------------------------------------
      // 5. Public URL
      // --------------------------------------------------------

      final String imageUrl =
          supabase.storage
              .from('product-images')
              .getPublicUrl(filePath);

      // --------------------------------------------------------
      // 6. Skills
      // --------------------------------------------------------

      final List<String> skills =
          _skillsController.text
              .split(',')
              .map(
                (skill) => skill.trim(),
              )
              .where(
                (skill) => skill.isNotEmpty,
              )
              .toList();

      // --------------------------------------------------------
      // 7. Insert opportunity
      // --------------------------------------------------------

      await supabase
          .from('opportunities')
          .insert({
        'owner_id': user.id,
        'title': _titleController.text.trim(),
        'subtitle': _category,
        'description':
            _descriptionController.text.trim(),
        'business_name':
            _businessController.text.trim(),
        'category': _category,
        'price': _priceController.text.trim(),
        'image_url': imageUrl,
        'skills': skills,
        'demand_score': 10,
        'seasonal_score': 10,
        'verified': false,
        'sellers_required': 1,
        'buyer_interested': false,
        'is_active': true,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _publishing = false;
      });

      _showMessage(
        'Published successfully! Your opportunity is now live.',
      );

      _clearForm();
    } catch (error, stackTrace) {
      debugPrint(
        'Publish error: $error',
      );

      debugPrint(
        'Publish stack trace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _publishing = false;
      });

      _showMessage(
        'Could not publish. Please try again.',
      );
    }
  }

  // ============================================================
  // CONTENT TYPE
  // ============================================================

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    _titleController.clear();
    _businessController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _skillsController.clear();

    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _category = 'Product';
      _content = null;
      _selectedChannel = 0;
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // AI CONTENT GENERATION
  // ============================================================

  Future<void> _generate() async {
    if (_selectedImage == null) {
      _showMessage(
        'Please choose an image first.',
      );
      return;
    }

    if (_titleController.text.trim().isEmpty && DemoStore.instance.skills.isEmpty) {
      _showMessage(
        'Please add a skill or offering first.',
      );
      return;
    }

    setState(() {
      _analysing = true;
    });

    try {
      final store = DemoStore.instance;
      final profileSkills = store.skills.join(', ');
      final profileBio = store.profile['bio']?.toString() ?? '';
      final generatedDescription = [
        _descriptionController.text.trim(),
        if (profileSkills.isNotEmpty) 'Skills: $profileSkills',
        if (profileBio.isNotEmpty && !profileBio.startsWith('Your SilverHands profile')) profileBio,
      ].where((value) => value.trim().isNotEmpty).join('\n');

      final ProductContent content =
          await _service.generateFromProductPhoto(
        productName: _posterOffering(),
        productDescription: generatedDescription,
        language: store.language,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _content = content;
        _analysing = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'AI generation error: $error',
      );

      debugPrint(
        'AI generation stack trace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _analysing = false;
      });

      _showMessage(
        'Content generator recovered with demo mode. Please try again if needed.',
      );
    }
  }

  // ============================================================
  // ACTIVE CONTENT
  // ============================================================

  String get _activeContent {
    final ProductContent content = _content!;

    if (_selectedChannel == 1) {
      return content.instagramCaption;
    }

    if (_selectedChannel == 2) {
      return content.facebookPost;
    }

    return content.whatsAppStatus;
  }

  // ============================================================
  // COPY
  // ============================================================

  void _copy() {
    Clipboard.setData(
      ClipboardData(
        text: _activeContent,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Content copied. You can now paste it anywhere.',
        ),
      ),
    );
  }

  // ============================================================
  // SHARE
  // ============================================================

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'WhatsApp sharing will be connected when device sharing is enabled.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Product / Service',
        ),
        backgroundColor: AppColors.cream,
      ),
      body: SafeArea(
        child: _content != null
            ? _contentView()
            : _createView(),
      ),
    );
  }

  // ============================================================
  // CREATE VIEW
  // ============================================================

  Widget _createView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        30,
      ),
      children: [
        Text(
          'Create your opportunity',
          style: Theme.of(context)
              .textTheme
              .headlineMedium,
        ),

        const SizedBox(height: 7),

        const Text(
          'Tell people what you make or the service you provide.',
          style: TextStyle(
            fontSize: 17,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 24),

        // ------------------------------------------------------
        // CATEGORY
        // ------------------------------------------------------

        _label('What are you offering?'),

        const SizedBox(height: 8),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: 'Product',
              label: Text('Product'),
              icon: Icon(
                Icons.inventory_2_outlined,
              ),
            ),
            ButtonSegment<String>(
              value: 'Service',
              label: Text('Service'),
              icon: Icon(
                Icons.handyman_outlined,
              ),
            ),
          ],
          selected: {_category},
          onSelectionChanged: (value) {
            setState(() {
              _category = value.first;
            });
          },
        ),

        const SizedBox(height: 20),

        // ------------------------------------------------------
        // TITLE
        // ------------------------------------------------------

        _label('Title'),

        const SizedBox(height: 8),

        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText:
                'Example: Handmade millet laddus',
            prefixIcon: Icon(
              Icons.title_rounded,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ------------------------------------------------------
        // BUSINESS
        // ------------------------------------------------------

        _label('Business / seller name'),

        const SizedBox(height: 8),

        TextField(
          controller: _businessController,
          decoration: const InputDecoration(
            hintText:
                'Example: Savita Home Foods',
            prefixIcon: Icon(
              Icons.storefront_rounded,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ------------------------------------------------------
        // DESCRIPTION
        // ------------------------------------------------------

        _label('Description'),

        const SizedBox(height: 8),

        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Describe your product or service...',
            prefixIcon: Icon(
              Icons.description_outlined,
            ),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 16),

        // ------------------------------------------------------
        // PRICE
        // ------------------------------------------------------

        _label('Price'),

        const SizedBox(height: 8),

        TextField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText:
                'Example: ₹500 per order',
            prefixIcon: Icon(
              Icons.currency_rupee_rounded,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ------------------------------------------------------
        // SKILLS
        // ------------------------------------------------------

        _label('Skills'),

        const SizedBox(height: 8),

        TextField(
          controller: _skillsController,
          decoration: const InputDecoration(
            hintText:
                'Cooking, Packaging, Crafts',
            prefixIcon: Icon(
              Icons.auto_awesome_rounded,
            ),
            helperText:
                'Separate skills with commas',
          ),
        ),

        const SizedBox(height: 20),

        // ------------------------------------------------------
        // IMAGE
        // ------------------------------------------------------

        _label('Product / service image'),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: _publishing
              ? null
              : _pickImage,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color:
                    const Color(0xFFD5DDD7),
                width: 2,
              ),
            ),
            child: _selectedImage == null
                ? const Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .add_photo_alternate_rounded,
                        size: 52,
                        color: AppColors.teal,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Choose an image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Upload a photo from your device',
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius:
                        BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_selectedImageBytes != null)
                          Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return const Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 60,
                                ),
                              );
                            },
                          )
                        else
                          const Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 60,
                            ),
                          ),

                        Container(
                          color: Colors.black
                              .withValues(
                            alpha: 0.18,
                          ),
                        ),

                        const Center(
                          child: Icon(
                            Icons
                                .check_circle_rounded,
                            color: Colors.white,
                            size: 55,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 25),

        // ------------------------------------------------------
        // PUBLISH
        // ------------------------------------------------------

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                _publishing ? null : _publish,
            icon: _publishing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(
                    Icons.publish_rounded,
                  ),
            label: Text(
              _publishing
                  ? 'Publishing...'
                  : 'Publish Product / Service',
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Your opportunity will appear in Discover after publishing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF56615C),
          ),
        ),

        const SizedBox(height: 28),

        const Divider(),

        const SizedBox(height: 20),

        // ------------------------------------------------------
        // AI CONTENT GENERATOR
        // ------------------------------------------------------

        Text(
          'AI Content Generator',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(height: 6),

        const Text(
          'After adding your product, you can generate content for WhatsApp, Instagram and Facebook.',
        ),

        const SizedBox(height: 15),

        FilledButton.tonalIcon(
          onPressed:
              _selectedImage == null ||
                      _analysing
                  ? null
                  : _generate,
          icon: _analysing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(
                  Icons.auto_awesome_rounded,
                ),
          label: Text(
            _analysing
                ? 'Generating...'
                : 'Generate AI content',
          ),
        ),

        if (_analysing)
          const Padding(
            padding:
                EdgeInsets.only(top: 13),
            child: Text(
              'AI is analyzing your product...',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // AI CONTENT VIEW
  // ============================================================

  // ============================================================
  // UNIVERSAL SILVERHANDS POSTER
  // ============================================================

  String _businessCategory() {
    return inferBusinessCategory(
      productName: _titleController.text,
      skills: _skillsController.text,
      selectedCategory: _category,
    );
  }

  ({Color primary, Color secondary, Color accent, IconData icon})
      _posterTheme(String category) {
    switch (category) {
      case 'Food / Culinary':
        return (
          primary: const Color(0xFF7A351F),
          secondary: const Color(0xFFF4D7A1),
          accent: const Color(0xFFFFB347),
          icon: Icons.restaurant_rounded,
        );
      case 'Tailoring / Fashion':
        return (
          primary: const Color(0xFF4A234F),
          secondary: const Color(0xFFF1D9E8),
          accent: const Color(0xFFE7A6C5),
          icon: Icons.checkroom_rounded,
        );
      case 'Handicrafts / Art':
        return (
          primary: const Color(0xFF5B3A29),
          secondary: const Color(0xFFE8D5BE),
          accent: const Color(0xFFD69A5B),
          icon: Icons.palette_rounded,
        );
      case 'Tutoring / Education':
        return (
          primary: const Color(0xFF164A63),
          secondary: const Color(0xFFD9EDF5),
          accent: const Color(0xFF62B5D0),
          icon: Icons.menu_book_rounded,
        );
      case 'Beauty / Salon':
        return (
          primary: const Color(0xFF5B284D),
          secondary: const Color(0xFFF2D9E8),
          accent: const Color(0xFFE8A4C4),
          icon: Icons.spa_rounded,
        );
      case 'Gardening / Plants':
        return (
          primary: const Color(0xFF285B3D),
          secondary: const Color(0xFFDCECD8),
          accent: const Color(0xFF86B96F),
          icon: Icons.local_florist_rounded,
        );
      case 'Home Services':
        return (
          primary: const Color(0xFF23455C),
          secondary: const Color(0xFFDDE9EF),
          accent: const Color(0xFF6FA6C5),
          icon: Icons.handyman_rounded,
        );
      case 'Creative Services':
        return (
          primary: const Color(0xFF302A63),
          secondary: const Color(0xFFE1DFF5),
          accent: const Color(0xFF958DE0),
          icon: Icons.camera_alt_rounded,
        );
      case 'Traditional Arts':
        return (
          primary: const Color(0xFF6B321F),
          secondary: const Color(0xFFF1DDC4),
          accent: const Color(0xFFD79B62),
          icon: Icons.auto_awesome_rounded,
        );
      default:
        return (
          primary: AppColors.teal,
          secondary: const Color(0xFFD9F0EC),
          accent: const Color(0xFFFFD694),
          icon: Icons.storefront_rounded,
        );
    }
  }

  String _posterProfileName() {
    final name = DemoStore.instance.profile['display_name']?.toString().trim();
    if (name != null && name.isNotEmpty && name != 'SilverHands Member') {
      return name;
    }
    final business = _businessController.text.trim();
    return business.isEmpty ? 'SilverHands Creator' : business;
  }

  String _posterLocation() {
    return DemoStore.instance.profile['location']?.toString().trim() ?? '';
  }

  String _profileQrData() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      return 'silverhands://profile/$userId';
    }
    return 'silverhands://profile/${_posterProfileName().replaceAll(' ', '-').toLowerCase()}';
  }

  String _posterOffering() {
    final title = _titleController.text.trim();
    final skills = _skillsController.text.trim();
    if (title.isNotEmpty && title.toLowerCase() != 'cooking' && title.toLowerCase() != 'tailoring') {
      return title;
    }
    if (skills.isNotEmpty) return skills.split(',').first.trim();
    return title.isEmpty ? 'Skilled local service' : title;
  }

  Widget _posterPreview() {
    final ProductContent content = _content!;
    final category = _businessCategory();
    final theme = _posterTheme(category);
    final headline = content.posterHeadline.trim().isEmpty
        ? categoryHeadline(category, _posterOffering())
        : content.posterHeadline.trim();
    final offering = _posterOffering();
    final profileName = _posterProfileName();
    final location = _posterLocation();
    final skills = _skillsController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? DemoStore.instance.profile['bio']?.toString() ?? ''
        : _descriptionController.text.trim();
    final cta = content.posterCta.trim().isEmpty
        ? 'VIEW PROFILE'
        : content.posterCta.trim().toUpperCase();

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: theme.secondary,
          boxShadow: const [
            BoxShadow(
              blurRadius: 22,
              offset: Offset(0, 10),
              color: Color(0x28000000),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image: the user's actual product/service photo remains
            // the dominant visual, with a category-aware editorial treatment.
            if (_selectedImageBytes != null)
              Positioned.fill(
                child: Image.memory(
                  _selectedImageBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.56, 0.83, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.64),
                      Colors.transparent,
                      Colors.transparent,
                      theme.primary.withValues(alpha: 0.76),
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.93),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'SILVERHANDS',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(theme.icon, color: theme.primary, size: 20),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    offering,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      skills,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    QrImageView(
                      data: _profileQrData(),
                      size: 72,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCAN TO VIEW PROFILE',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.isEmpty ? 'Connect with this SilverHands creator' : location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF4C5754),
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Powered by SilverHands',
                            style: TextStyle(
                              color: theme.primary.withValues(alpha: 0.75),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }

  Widget _contentView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        28,
      ),
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor:
                  Color(0xFFFFD694),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.teal,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your content is ready!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  const Text(
                    'Ready to share with your customers.',
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 21),

        // ------------------------------------------------------
        // AI POSTER PREVIEW
        // ------------------------------------------------------

        const Text(
          'AI-created WhatsApp poster',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        _posterPreview(),

        const SizedBox(height: 22),

        SegmentedButton<int>(
          segments: const [
            ButtonSegment<int>(
              value: 0,
              label: Text('WhatsApp'),
            ),
            ButtonSegment<int>(
              value: 1,
              label: Text('Instagram'),
            ),
            ButtonSegment<int>(
              value: 2,
              label: Text('Facebook'),
            ),
          ],
          selected: {
            _selectedChannel,
          },
          onSelectionChanged:
              (Set<int> value) {
            setState(() {
              _selectedChannel =
                  value.first;
            });
          },
        ),

        const SizedBox(height: 17),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: SelectableText(
              _activeContent,
              style: const TextStyle(
                fontSize: 18,
                height: 1.55,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _copy,
            icon: const Icon(
              Icons.copy_rounded,
            ),
            label: const Text(
              'Copy',
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(
              Icons.send_rounded,
            ),
            label: const Text(
              'Share to WhatsApp',
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextButton.icon(
          onPressed: _analysing
              ? null
              : _generate,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Generate Again',
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'AI-generated content may need a quick review before sharing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF56615C),
          ),
        ),
      ],
    );
  }
}