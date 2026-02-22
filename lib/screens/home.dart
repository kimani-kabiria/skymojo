import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:skymojo/screens/nightly.dart';
import 'package:skymojo/screens/dash.dart';
import 'package:skymojo/screens/weather.dart';
import 'package:skymojo/screens/profile.dart';
import 'package:skymojo/services/auth_service.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:skymojo/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicons/unicons.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final btmNavItems = const [
    Icon(UniconsLine.home, size: 30,),
    Icon(UniconsLine.cloud_sun_tear, size: 30),
    Icon(UniconsLine.moonset, size: 30),
    Icon(Icons.person, size: 30),
  ];

  int index = 0;

  Icon customIcon = const Icon(UniconsLine.search_alt);
  Widget customSearchBar = Image.asset(
    'assets/logo.png',
    height: 48,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customSearchBar,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (customIcon.icon == UniconsLine.search_alt) {
                  customIcon = const Icon(UniconsLine.cancel);
                  customSearchBar = const ListTile(
                    leading: Icon(
                      Icons.search,
                      color: Color(0xFF083235),
                      size: 28,
                    ),
                    title: TextField(
                      decoration: InputDecoration(
                        hintText: 'type to start searching...',
                        hintStyle: TextStyle(
                          color: Color(0xFF083235),
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Color(0xFF083235),
                      ),
                    ),
                  );
                } else {
                  customIcon = const Icon(UniconsLine.search_alt);
                  customSearchBar = Image.asset(
                    'assets/logo.png',
                    height: 48,
                  );
                }
              });
            },
            icon: customIcon,
          )
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF083235),
      ),
      drawer: const NavBar(),
      body: SafeArea(
        child: getSelectedWidget(index: index),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context)
            .copyWith(iconTheme: const IconThemeData(color: Colors.white)),
        child: CurvedNavigationBar(
          backgroundColor: Colors.transparent,
          buttonBackgroundColor: Colors.orangeAccent,
          color: const Color(0xFF083235),
          items: btmNavItems,
          index: index,
          animationDuration: const Duration(
            milliseconds: 200,
          ),
          onTap: (selectedIndex) {
            setState(() {
              index = selectedIndex;
            });
          },
        ),
      ),
    );
  }

  Widget getSelectedWidget({required int index}) {
    Widget widget;
    switch (index) {
      case 0:
        widget = const HomeDash();
        break;
      case 1:
        widget = const WeatherDash();
        break;
      case 2:
        widget = const NightlyDash();
        break;
      case 3:
        widget = const ProfileScreen();
        break;
      default:
        widget = const HomeDash();
        break;
    }
    return widget;
  }
}

class NavBar extends StatefulWidget {
  const NavBar({
    super.key,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  UserProfile? _userProfile;
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserProfileService.getCurrentUserProfile();
      final avatarFromMetadata = await UserProfileService.getUserAvatarFromMetadata();
      final nameFromMetadata = await UserProfileService.getUserNameFromMetadata();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          // If no profile avatar, try to get from metadata
          if (_userProfile?.avatarUrl == null && avatarFromMetadata != null) {
            _userProfile = _userProfile?.copyWith(avatarUrl: avatarFromMetadata) ?? 
                           UserProfile(
                             id: user?.id ?? '',
                             fullName: nameFromMetadata,
                             avatarUrl: avatarFromMetadata,
                             createdAt: DateTime.now(),
                             updatedAt: DateTime.now(),
                           );
          }
          // If no profile name, try to get from metadata
          if (_userProfile?.fullName == null && nameFromMetadata != null) {
            _userProfile = _userProfile?.copyWith(fullName: nameFromMetadata) ??
                           UserProfile(
                             id: user?.id ?? '',
                             fullName: nameFromMetadata,
                             avatarUrl: avatarFromMetadata,
                             createdAt: DateTime.now(),
                             updatedAt: DateTime.now(),
                           );
          }
        });
      }
    } catch (e) {
      print('Error loading user profile for drawer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          // User card background
          Container(
            color: const Color(0xFF083235),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                // User Card Header
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF083235),
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orangeAccent,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _userProfile?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    _userProfile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFF083235),
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Color(0xFF083235),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userProfile?.fullName ?? 'SkyMojo User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Bellota',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu items on top with curve
          Positioned(
            top: 120 + MediaQuery.of(context).padding.top, // Adjust based on user card height
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Home'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sign Out', 
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await AuthService.signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
