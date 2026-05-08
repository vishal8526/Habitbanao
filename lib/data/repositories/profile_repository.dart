import 'package:hive/hive.dart';
import '../models/user_profile_model.dart';
import '../../core/constants/hive_constants.dart';

class ProfileRepository {
  final Box<UserProfileModel> _box = Hive.box<UserProfileModel>(
    HiveConstants.profileBox,
  );

  UserProfileModel getProfile() {
    final profile = _box.get(HiveConstants.profileKey);
    if (profile == null) {
      final newProfile = UserProfileModel();
      _box.put(HiveConstants.profileKey, newProfile);
      return newProfile;
    }
    return profile;
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    await _box.put(HiveConstants.profileKey, profile);
  }

  Future<void> addXP(int xp) async {
    final profile = getProfile();
    profile.totalXP += xp;
    profile.level = _calculateLevel(profile.totalXP);
    await profile.save();
  }

  int _calculateLevel(int xp) {
    int level = 1;
    const thresholds = {
      1: 0,
      2: 100,
      3: 250,
      4: 500,
      5: 800,
      6: 1200,
      7: 1700,
      8: 2300,
      9: 3000,
      10: 3800,
      11: 4700,
      12: 5700,
      13: 6800,
      14: 8000,
      15: 9500,
      16: 11000,
      17: 13000,
      18: 15000,
      19: 17500,
      20: 20000,
      21: 23000,
      22: 26500,
      23: 30000,
      24: 34000,
      25: 38500,
      26: 43000,
      27: 47000,
      28: 50000,
      29: 53000,
      30: 55000,
    };
    for (final entry in thresholds.entries) {
      if (xp >= entry.value) level = entry.key;
    }
    return level;
  }
}
