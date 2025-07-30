import '../services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataInitializer {
  static final FirestoreService _firestoreService = FirestoreService();
  static const String _dataInitializedKey = 'sample_data_initialized';
  
  static Future<void> initializeSampleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_dataInitializedKey) ?? false;
      
      if (!isInitialized) {
        // Add sample chemistry books
        await _firestoreService.addSampleChemistryBooks();
        
        // Mark as initialized
        await prefs.setBool(_dataInitializedKey, true);
        
        print('Sample data initialized successfully!');
      } else {
        print('Sample data already initialized, skipping...');
      }
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
  
  // Reset initialization flag (for testing)
  static Future<void> resetInitialization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataInitializedKey);
  }
}
