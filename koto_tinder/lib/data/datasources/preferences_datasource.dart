import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDatasource {
  static const String _likeCountKey = 'like_count';

  Future<int> getLikeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_likeCountKey) ?? 0;
  }

  Future<void> saveLikeCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_likeCountKey, count);
  }

  Future<void> incrementLikeCount() async {
    final currentCount = await getLikeCount();
    await saveLikeCount(currentCount + 1);
  }
}
