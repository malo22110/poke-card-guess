import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pokecardguess/config/app_config.dart';
import 'package:pokecardguess/services/auth_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? authToken;

  const ProfileScreen({super.key, this.authToken});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String? _userPicture;
  Map<String, dynamic> _socials = {};
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _cardsGuessed = 0;
  int _highScore = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _marketplaceController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _xController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _tiktokController.dispose();
    _marketplaceController.dispose();
    _facebookController.dispose();
    _xController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (widget.authToken == null) {
      setState(() {
        _userName = 'Guest';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        Map<String, dynamic> loadedSocials = {};
        if (data['socials'] != null) {
           try {
             loadedSocials = jsonDecode(data['socials']);
           } catch (e) {
             print('Error parsing socials JSON: $e');
           }
        }

        if (mounted) {
          setState(() {
            _userName = data['name'] ?? 'User';
            _userPicture = data['picture'];
            _gamesPlayed = data['gamesPlayed'] ?? 0;
            _gamesWon = data['gamesWon'] ?? 0;
            _currentStreak = data['currentStreak'] ?? 0;
            _bestStreak = data['bestStreak'] ?? 0;
            _cardsGuessed = data['cardsGuessed'] ?? 0;
            _highScore = data['highScore'] ?? 0;
            _socials = loadedSocials;
            _instagramController.text = _socials['instagram'] ?? '';
            _tiktokController.text = _socials['tiktok'] ?? '';
            // Backward compatibility for 'voggt' if present
            _marketplaceController.text = _socials['marketplace'] ?? _socials['voggt'] ?? '';
            _facebookController.text = _socials['facebook'] ?? '';
            _xController.text = _socials['x'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
           setState(() {
            _userName = 'Unknown User';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Error loading profile';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final socialsToSave = {
      'instagram': _instagramController.text.trim(),
      'tiktok': _tiktokController.text.trim(),
      'marketplace': _marketplaceController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'x': _xController.text.trim(),
    };

    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'socials': socialsToSave,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2937),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.amber,
                    backgroundImage: _userPicture != null ? NetworkImage(_userPicture!) : null,
                    child: _userPicture == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard('Games', '$_gamesPlayed', Icons.videogame_asset, Colors.blue),
                      _buildStatCard('Wins', '$_gamesWon', Icons.emoji_events, Colors.amber),
                      _buildStatCard('Streak', '$_currentStreak', Icons.local_fire_department, Colors.orange),
                      _buildStatCard('Best Streak', '$_bestStreak', Icons.whatshot, Colors.deepOrange),
                      _buildStatCard('Cards', '$_cardsGuessed', Icons.style, Colors.purple),
                      _buildStatCard('High Score', '$_highScore', Icons.stars, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (widget.authToken != null) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Social Links', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialField('Instagram URL', _instagramController, Icons.camera_alt),
                    const SizedBox(height: 12),
                    _buildSocialField('TikTok URL', _tiktokController, Icons.music_note),
                    const SizedBox(height: 12),
                    _buildSocialField('Marketplace URL (Vinted, Voggt, eBay...)', _marketplaceController, Icons.store),
                    const SizedBox(height: 12),
                    _buildSocialField('Facebook URL', _facebookController, Icons.facebook),
                    const SizedBox(height: 12),
                    _buildSocialField('X (Twitter) URL', _xController, Icons.alternate_email),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Text('Save Changes'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuthStorageService().clearSession();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                    ),
                  )
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.amber),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
