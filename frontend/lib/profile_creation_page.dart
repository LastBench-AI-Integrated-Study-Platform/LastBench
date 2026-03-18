import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCreationPage extends StatefulWidget {
  final String? userEmail;
  final bool isEditing;
  const ProfileCreationPage({
    super.key,
    this.userEmail,
    this.isEditing = false,
  });

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController internshipController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  // ── Cross-platform image ──────────────────────────────────────────────────
  // On web  → _webImageBytes (Uint8List via readAsBytes())
  // On mobile/desktop → _nativeImageFile (dart:io File)
  Uint8List? _webImageBytes;
  File? _nativeImageFile;
  String? _profileImageBase64;

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  late AnimationController _avatarPulseController;
  late AnimationController _progressController;
  late AnimationController _fadeInController;
  late Animation<double> _avatarPulse;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeInAnimation;

  final Map<String, bool> _fieldCompletion = {
    'name': false,
    'bio': false,
    'education': false,
    'internship': false,
    'job': false,
    'skills': false,
    'photo': false,
  };

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0A2540);
  static const Color teal = Color(0xFF00B4D8);
  static const Color accent = Color(0xFF48CAE4);
  static const Color surface = Color(0xFF0D2137);
  static const Color cardBg = Color(0xFF112240);
  static const Color gold = Color(0xFFFFB703);
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF8BB4CC);

  final List<_SectionConfig> _sections = const [
    _SectionConfig(
      icon: Icons.person_outline_rounded,
      title: 'Basic Info',
      subtitle: 'Who are you?',
      color: Color(0xFF00B4D8),
    ),
    _SectionConfig(
      icon: Icons.school_outlined,
      title: 'Education',
      subtitle: 'Your academic background',
      color: Color(0xFF48CAE4),
    ),
    _SectionConfig(
      icon: Icons.work_outline_rounded,
      title: 'Experience',
      subtitle: 'Your work journey',
      color: Color(0xFF0077B6),
    ),
    _SectionConfig(
      icon: Icons.bolt_outlined,
      title: 'Skills',
      subtitle: 'What you bring to the table',
      color: Color(0xFFFFB703),
    ),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _avatarPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _avatarPulseController, curve: Curves.easeInOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut),
    );

    nameController.addListener(
      () => _updateCompletion('name', nameController.text.isNotEmpty),
    );
    bioController.addListener(
      () => _updateCompletion('bio', bioController.text.isNotEmpty),
    );
    educationController.addListener(
      () => _updateCompletion('education', educationController.text.isNotEmpty),
    );
    internshipController.addListener(
      () =>
          _updateCompletion('internship', internshipController.text.isNotEmpty),
    );
    jobController.addListener(
      () => _updateCompletion('job', jobController.text.isNotEmpty),
    );
    skillsController.addListener(
      () => _updateCompletion('skills', skillsController.text.isNotEmpty),
    );

    if (widget.isEditing) _loadProfileData();
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    _progressController.dispose();
    _fadeInController.dispose();
    nameController.dispose();
    bioController.dispose();
    educationController.dispose();
    internshipController.dispose();
    jobController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateCompletion(String field, bool complete) {
    setState(() => _fieldCompletion[field] = complete);
    _animateProgress();
  }

  void _animateProgress() {
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: _completionPercent,
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );
    _progressController
      ..reset()
      ..forward();
  }

  double get _completionPercent =>
      _fieldCompletion.values.where((v) => v).length / _fieldCompletion.length;

  bool get _hasImage =>
      kIsWeb ? _webImageBytes != null : _nativeImageFile != null;

  /// Returns the correct [ImageProvider] for the current platform.
  ImageProvider? get _imageProvider {
    if (kIsWeb && _webImageBytes != null) return MemoryImage(_webImageBytes!);
    if (!kIsWeb && _nativeImageFile != null)
      return FileImage(_nativeImageFile!);
    return null;
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('profile_name') ?? '';
      bioController.text = prefs.getString('profile_bio') ?? '';
      educationController.text = prefs.getString('profile_education') ?? '';
      internshipController.text = prefs.getString('profile_internship') ?? '';
      jobController.text = prefs.getString('profile_job') ?? '';
      skillsController.text = prefs.getString('profile_skills') ?? '';
      final base64 = prefs.getString('profile_image_base64');
      if (base64 != null) {
        _webImageBytes = base64Decode(base64);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      if (kIsWeb) {
        // Web: File I/O is unavailable — read bytes directly from XFile.
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _fieldCompletion['photo'] = true;
        });
      } else {
        // Mobile / Desktop: safe to use dart:io File.
        setState(() {
          _nativeImageFile = File(picked.path);
          _fieldCompletion['photo'] = true;
        });
      }
      // Store base64 for saving
      final bytes = kIsWeb
          ? _webImageBytes!
          : await _nativeImageFile!.readAsBytes();
      _profileImageBase64 = base64Encode(bytes);
      _animateProgress();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!kIsWeb) HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', nameController.text);
    await prefs.setString('profile_bio', bioController.text);
    await prefs.setString('profile_education', educationController.text);
    await prefs.setString('profile_internship', internshipController.text);
    await prefs.setString('profile_job', jobController.text);
    await prefs.setString('profile_skills', skillsController.text);
    if (_profileImageBase64 != null) {
      await prefs.setString('profile_image_base64', _profileImageBase64!);
    }

    setState(() => _isSaving = false);
    if (mounted) _showSuccessDialog();
  }

  // ── Sheets / Dialogs ──────────────────────────────────────────────────────

  void _showPickerSheet() {
    if (!kIsWeb) HapticFeedback.mediumImpact();

    // On web the camera source is unreliable — skip the sheet and go direct.
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Photo',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceBtn(
                  Icons.photo_library_rounded,
                  'Gallery',
                  teal,
                  () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _imageSourceBtn(Icons.camera_alt_rounded, 'Camera', accent, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: textSecondary, fontSize: 13)),
      ],
    ),
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: teal, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Profile Saved!',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your profile is live and ready.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3a9b9b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProgressCard(),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        section: _sections[0],
                        children: [
                          _buildField(
                            nameController,
                            'Full Name',
                            'e.g., Arjun Sharma',
                            Icons.badge_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            bioController,
                            'Professional Bio',
                            'Tell the world what drives you...',
                            Icons.notes_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        section: _sections[1],
                        children: [
                          _buildField(
                            educationController,
                            'Education',
                            'e.g., B.Tech CSE, IIT Delhi — 2024',
                            Icons.school_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        section: _sections[2],
                        children: [
                          _buildField(
                            internshipController,
                            'Internship Experience',
                            'Company, role, duration...',
                            Icons.assignment_ind_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            jobController,
                            'Job Experience',
                            'Current or past full-time roles...',
                            Icons.business_center_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        section: _sections[3],
                        children: [
                          _buildField(
                            skillsController,
                            'Skills & Technologies',
                            'Flutter, Python, ML, Firebase...',
                            Icons.bolt_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _buildSkillChips(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: navy,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: textPrimary,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: TextButton.styleFrom(
              backgroundColor: teal.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), navy, Color(0xFF012030)],
                ),
              ),
            ),
            // Decorative blobs
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teal.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.05),
                ),
              ),
            ),

            // Avatar + name — centred in the flexible space below the toolbar
            Positioned.fill(
              top: kToolbarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tappable avatar
                  GestureDetector(
                    onTap: _showPickerSheet,
                    child: AnimatedBuilder(
                      animation: _avatarPulse,
                      builder: (_, child) => Transform.scale(
                        scale: _hasImage ? 1.0 : _avatarPulse.value,
                        child: child,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Gradient glow ring
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [teal, accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withOpacity(0.45),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 106,
                            height: 106,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: navy,
                            ),
                          ),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: cardBg,
                            backgroundImage: _imageProvider,
                            child: !_hasImage
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_rounded,
                                        color: teal,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: teal,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          if (_hasImage)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [teal, accent],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: teal.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Live name preview
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      nameController.text.isEmpty
                          ? 'Your Name'
                          : nameController.text,
                      key: ValueKey(nameController.text.isEmpty),
                      style: TextStyle(
                        color: nameController.text.isEmpty
                            ? textSecondary
                            : textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userEmail ?? 'yourname@email.com',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    final pct = (_completionPercent * 100).round();
    return AnimatedBuilder(
      animation: _progressController,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: teal.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: teal.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Profile Strength',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '$pct%',
                    key: ValueKey(pct),
                    style: TextStyle(
                      color: pct >= 80 ? gold : teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _completionPercent,
                backgroundColor: surface,
                valueColor: AlwaysStoppedAnimation(pct >= 80 ? gold : teal),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _strengthLabel(pct),
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _strengthLabel(int pct) {
    if (pct == 100) return '🏆 Outstanding! Your profile is complete.';
    if (pct >= 80) return '🌟 Almost there! A few more details to go.';
    if (pct >= 50) return '📈 Good start! Keep filling in your info.';
    if (pct >= 20)
      return '🚀 Just getting started — you\'re on the right track!';
    return '💡 Fill in your details to get noticed by recruiters.';
  }

  // ── Section Card ──────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required _SectionConfig section,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: section.color.withOpacity(0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: section.color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    section.subtitle,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(color: section.color.withOpacity(0.1), height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: children),
        ),
      ],
    ),
  );

  // ── Text Field ────────────────────────────────────────────────────────────

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: textPrimary, fontSize: 15),
      cursorColor: teal,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: Icon(icon, color: textSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? 'This field is required'
                : null
          : null,
    );
  }

  // ── Skill Chips ───────────────────────────────────────────────────────────

  Widget _buildSkillChips() {
    const suggestedSkills = [
      'Flutter',
      'Python',
      'React',
      'Node.js',
      'ML/AI',
      'Firebase',
      'Java',
      'Swift',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add:',
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedSkills.map((skill) {
            final added = skillsController.text.contains(skill);
            return GestureDetector(
              onTap: () {
                if (!kIsWeb) HapticFeedback.selectionClick();
                if (!added) {
                  final cur = skillsController.text;
                  skillsController.text = cur.isEmpty ? skill : '$cur, $skill';
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: added ? teal.withOpacity(0.2) : surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: added ? teal : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (added) ...[
                      const Icon(Icons.check_rounded, color: teal, size: 12),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      skill,
                      style: TextStyle(
                        color: added ? teal : textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSaving
                ? [textSecondary, textSecondary]
                : [const Color(0xFF3a9b9b), const Color(0xFF288282)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF3a9b9b).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEditing ? 'Update Profile' : 'Create Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _SectionConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
