import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCity;
  final List<String> _cities = ["Paris", "Bédée", "Lyon", "Marseille", "Toulouse", "Bordeaux"];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Vérifier si l'utilisateur est déjà connecté
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Connexion anonyme si l'utilisateur n'existe pas
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
    }

    // Vérifier si une ville est déjà enregistrée
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCity = prefs.getString('selected_city');

    if (savedCity != null) {
      // Si une ville est déjà choisie, rediriger directement vers l’écran des poubelles
      Navigator.pushReplacementNamed(context, '/trash_dates');
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCity() async {
    if (_selectedCity != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_city', _selectedCity!);

      // Sauvegarder dans Firestore (optionnel)
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'city': _selectedCity,
        });
      }

      // Aller à la page des dates des poubelles
      Navigator.pushReplacementNamed(context, '/trash_dates');
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Bienvenue")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Choisissez votre ville",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedCity,
              hint: Text("Sélectionnez une ville"),
              isExpanded: true,
              items: _cities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedCity != null ? _saveCity : null,
              child: Text("Continuer"),
            ),
          ],
        ),
      ),
    );
  }
}

