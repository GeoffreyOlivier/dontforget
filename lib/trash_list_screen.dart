import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrashDatesScreen extends StatefulWidget {
  const TrashDatesScreen({super.key});

  @override
  _TrashDatesScreenState createState() => _TrashDatesScreenState();
}

class _TrashDatesScreenState extends State<TrashDatesScreen> {
  String? _selectedCity;
  List<Map<String, dynamic>> _trashDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCityAndData();
  }

  Future<void> _loadCityAndData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? city = prefs.getString('selected_city'); // Récupération de la valeur
    print("Ville sélectionnée : $city");

    String? savedCity = prefs.getString('selected_city');

    if (savedCity != null) {
      setState(() {
        _selectedCity = savedCity;
      });

      await _fetchTrashDates(savedCity);
    } else {
      // Si aucune ville n'est enregistrée, retour à la sélection
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _fetchTrashDates(String city) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('collectionsGarbage')
          .doc(city)
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> data = (doc.data() as Map<String, dynamic>)['collections'];

        setState(() {
          _trashDates = data.cast<Map<String, dynamic>>(); // Convertir en liste de Map
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des données: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetSelection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_city');

    // Retour à la sélection de la ville
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Collectes - ${_selectedCity ?? ''}"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _resetSelection,
            tooltip: "Changer de ville",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _trashDates.isEmpty
          ? Center(child: Text("Aucune donnée trouvée."))
          : ListView.builder(
        itemCount: _trashDates.length,
        itemBuilder: (context, index) {
          var trash = _trashDates[index];
          return ListTile(
            leading: Icon(Icons.delete, color: Colors.green),
            title: Text(trash['name']),
            subtitle: Text(trash['date']),
          );
        },
      ),
    );
  }
}
