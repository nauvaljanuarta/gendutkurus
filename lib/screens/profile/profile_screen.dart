import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../services/user_service.dart';
import '../../services/category_service.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  UserModel? _userModel;
  bool _isLoadingProfile = false;
  bool _isUploadingAvatar = false;
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndCategories();
  }

  Future<void> _loadProfileAndCategories() async {
    final user = ApiClient.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final results = await Future.wait([
        UserService.fetchUserProfile(user.id),
        CategoryService.fetchCategories(),
      ]);
      setState(() {
        _userModel = results[0] as UserModel?;
        _allCategories = results[1] as List<Category>;
      });
    } catch (e) {
      debugPrint('Error loading profile or categories: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = ApiClient.client.auth.currentUser;
    if (user == null) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last.toLowerCase();

      await UserService.uploadAvatar(
        userId: user.id,
        fileBytes: bytes,
        fileExtension: extension.isEmpty ? 'png' : extension,
      );

      await _loadProfileAndCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diunggah!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto profil: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveUserInterests(List<int> selectedIds) async {
    final user = ApiClient.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.updateUserInterests(user.id, selectedIds);
      await _loadProfileAndCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minat latihan berhasil diperbarui!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui minat latihan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditInterestsDialog() {
    if (_allCategories.isEmpty) return;

    List<int> tempSelectedIds = List.from(_userModel?.interestCategoryIds ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Pilih Fokus Latihan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allCategories.map((category) {
                    final isSelected = tempSelectedIds.contains(category.id);
                    return FilterChip(
                      label: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      onSelected: (selected) {
                        setStateDialog(() {
                          if (selected) {
                            tempSelectedIds.add(category.id);
                          } else {
                            tempSelectedIds.remove(category.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _saveUserInterests(tempSelectedIds);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getUserInterestsText() {
    if (_userModel == null || _userModel!.interestCategoryIds.isEmpty) {
      return 'Belum diatur';
    }
    final names = _userModel!.interestCategoryIds.map((id) {
      final cat = _allCategories.firstWhere((c) => c.id == id, orElse: () => Category(id: 0, name: ''));
      return cat.name;
    }).where((name) => name.isNotEmpty).toList();

    if (names.isEmpty) return 'Belum diatur';
    return names.join(', ');
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiClient.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda telah berhasil keluar dari akun.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar akun: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: user == null ? _buildUnauthenticatedBody() : _buildAuthenticatedBody(user),
      ),
    );
  }

  Widget _buildUnauthenticatedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Belum Masuk Akun',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk untuk dapat menyimpan gym favorit Anda dan mengakses fitur premium lainnya.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) {
                _loadProfileAndCategories();
                setState(() {});
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Masuk Akun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ).then((_) {
              _loadProfileAndCategories();
              setState(() {});
            });
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Daftar Akun Baru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedBody(dynamic user) {
    final String fullName = _userModel?.fullName ?? user.userMetadata?['full_name'] ?? 'User Gendut Kurus';
    final String email = user.email ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      image: _userModel?.avatarUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(_userModel!.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: _userModel?.avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _isUploadingAvatar
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 24,
                            color: Colors.white70,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pencari Gym Aktif',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Detail Akun',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        _ProfileTile(label: 'Email', value: email),
        const _ProfileTile(label: 'Lokasi', value: 'Surabaya, Jawa Timur'),
        const SizedBox(height: 20),
        Text(
          'Preferensi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : InkWell(
                onTap: _showEditInterestsDialog,
                borderRadius: BorderRadius.circular(20),
                child: _ProfileTile(
                  label: 'Fokus Latihan',
                  value: _getUserInterestsText(),
                  isInteractive: true,
                ),
              ),
        const SizedBox(height: 32),

        _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
            : SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Keluar Akun',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isInteractive;

  const _ProfileTile({
    required this.label,
    required this.value,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isInteractive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isInteractive) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
