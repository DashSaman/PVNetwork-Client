import 'package:flutter/foundation.dart';
import 'core/import/profile_detector.dart';
import 'core/model/pv_profile.dart';
import 'core/storage/profile_repository.dart';

class PVController extends ChangeNotifier {
  PVController(this.repository);
  final ProfileRepository repository;
  final ProfileDetector detector = ProfileDetector();
  final List<PVProfile> profiles = <PVProfile>[];
  String? selectedId;

  PVProfile? get selected {
    for (final profile in profiles) {
      if (profile.id == selectedId) return profile;
    }
    return null;
  }

  Future<void> load() async {
    profiles.addAll(await repository.loadProfiles());
    selectedId = await repository.loadSelectedProfileId();
    if (selected == null && profiles.isNotEmpty) selectedId = profiles.first.id;
  }

  Future<void> addRaw(String value, {String source = 'text'}) async {
    final profile = detector.detect(value, sourceType: source).toProfile();
    profiles.insert(0, profile);
    selectedId ??= profile.id;
    await persist();
  }

  Future<void> select(String id) async {
    selectedId = id;
    await repository.saveSelectedProfileId(id);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    profiles.removeWhere((profile) => profile.id == id);
    if (selectedId == id) selectedId = profiles.isEmpty ? null : profiles.first.id;
    await persist();
  }

  Future<void> persist() async {
    await repository.saveProfiles(profiles);
    await repository.saveSelectedProfileId(selectedId);
    notifyListeners();
  }
}
