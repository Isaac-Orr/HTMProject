import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moneyshare/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Drink{
  String name;
  double price;  //1.0 for pound
  double amount; //ml
  double percent; //0.5 = 50%
  double value;   //Units per pound

  Drink(this.name, this.price, this.amount,this.percent){
    double alc = percent * amount;
    this.value = alc/price/10;
  }

  String toString()
  {
    return this.name + " " + this.price.toString() +
        " " + this.percent.toString() + " " + this.value.toString();
  }
}



class ResultsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _ResultsPageState();
  }
}

class _ResultsPageState extends State<ResultsPage> {
  var result;

  @override
  void initState() {
    super.initState();
    generateResult();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Results"),
      ),
      body: Column(
        children: [
          Text(result)


        ],
      ),
    );
    // TODO: implement build
    throw UnimplementedError();
  }

  generateResult() {
    result = "test";
  }


  saveData(String pubName, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = pubName;
    final value = list;
    prefs.setStringList(key, value);
    print('saved $value to $key');
  }

  readData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    var value;
    var key;
    var i = keys.iterator;
    while (i.moveNext()) {
      key = i.current;
      value = prefs.getStringList(key);
      print('read $value from $key');
    }
  }

}





//pass a list of drinks
void _getDrinks() async {
  FirebaseApp firebase = await Firebase.initializeApp();
  FirebaseFirestore _fireStoreInstance = FirebaseFirestore.instance;

  var collectionReference = _fireStoreInstance.collection('Drinks');
  List<Drink> result = [];

  for(int i = 0; i < 1; i++){
    //String name = names.elementAt(i);
    var query = collectionReference.where("Name", isEqualTo: "Hopstach");

    QuerySnapshot snap = await query.get();

    if(snap.docs.isNotEmpty){
      for(DocumentSnapshot j in snap.docs){
        double amount = 568;
        if(j.get("Type") == "Beer"){
          amount = 568;
        }
        else if(j.get("Type") == "Liquor"){
          amount = 50;
        }
        Drink drink = new Drink(j.get("Name"), 3, amount, j.get("%"));
        result.add(drink); //need to read the price and the amount from the menu
        print(drink.name + " " + drink.percent.toString() + " " +drink.value.toString());
      }
    }

  }
  Comparator<Drink> compareValue = (a,b) => a.value.compareTo(b.value);
  result.sort(compareValue);
}