import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// 1. Importar Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // 2. Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Obtener rol del usuario actual
  Future<String> getUserRole() async {
    if (currentUser == null) return 'user';
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['role'] ?? 'user';
  }

  Future<User?> signInWithGoogle() async {
    try {
      User? user;
      
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        user = userCredential.user;
      } else {
        // (Lógica móvil omitida para brevedad, es la misma de antes)
        // ...
      }

      // 3. GUARDAR USUARIO EN FIRESTORE
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastSeen': FieldValue.serverTimestamp(),
          // Usamos merge: true para no sobrescribir el rol si ya existe
        }, SetOptions(merge: true));
        
        // Asegurar que tenga un rol si es nuevo
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.data()!.containsKey('role')) {
             await _firestore.collection('users').doc(user.uid).update({'role': 'user'});
        }
      }

      return user;
    } catch (e) {
      print("Error en Google Sign-In Web: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}