import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> writeCounter(int newCount) async {
    await _firestore.collection('counterCollection').doc('cins467').set({
      'count': newCount,
    }).then((_) {
      if (kDebugMode) {
        print("Count written successfully.");
      }
    }).catchError((error) {
      if (kDebugMode) {
        print("writeCounter error: $error");
      }
    });
  }

  Future<int> readCounter() async {
    try {
      DocumentSnapshot ds = await _firestore
          .collection('counterCollection')
          .doc('cins467')
          .get();

      if (ds.data() != null) {
        Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
        if (data.containsKey('count')) {
          return data['count'] as int;
        } else {
          if (kDebugMode) {
            print('data does not contain count key');
          }
        }
      } else {
        if (kDebugMode) {
          print('Document data is null');
        }
      }
    } catch (e) {
      print("Error reading counter: $e");
    }

    return 0;
  }
}
