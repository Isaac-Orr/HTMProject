import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moneyshare/HomePage.dart';
import 'package:quiver/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Drink {
  String name;
  double price; //1.0 for pound
  double amount; //ml
  double percent ; //0.5 = 50%
  double value; //Units per pound

  Drink(this.name, this.price, this.amount, this.percent) {
    print("B:LAH" + this.name);
    print("BHAL" + this.amount.toString());
    double alc = (percent/100) * amount;
    this.value = alc / price / 10;
  }

  String toString() {
    return this.name + " " + this.price.toString() +
        " " + this.percent.toString() + " " + this.value.toString();
  }
}


class ResultsPage extends StatefulWidget {

  final List<List<String>> fromMenu;

  ResultsPage(this.fromMenu);
  @override
  State<StatefulWidget> createState() {
    return _ResultsPageState(this.fromMenu);
  }
}

class _ResultsPageState extends State<ResultsPage> {

  final List<List<String>> fromMenu;
  _ResultsPageState(this.fromMenu);

  @override
  void initState() {
    super.initState();

  }

  Future<List<Drink>> _getDrinks() async {
    print("Called");
    FirebaseApp firebase = await Firebase.initializeApp();
    FirebaseFirestore _fireStoreInstance = FirebaseFirestore.instance;

    var collectionReference = _fireStoreInstance.collection('Drinks');
    List<Drink> result = [];
    print("Length of fromMenu drinks is " + this.fromMenu.length.toString());
    for (int i = 0; i < this.fromMenu.length; i++) {
      print("iteration" + i.toString());
      if(this.fromMenu.elementAt(i).length > 1){
      String name = this.fromMenu.elementAt(i).elementAt(1);
      print("Searching for " + name);
      var query = collectionReference.where("Name", isEqualTo: name);
      print("awaiting query");
      QuerySnapshot snap = await query.get();
      print("queryreturns");
      if (snap.docs.isNotEmpty) {
        print("Query not empty, data gained");
        print("NUMBER OF DOCS IS" + snap.docs.length.toString());
        for (DocumentSnapshot j in snap.docs) {
          double amount = 568;
          if (j.get("Type") == "Beer") {
            amount = 568;
          }
          else if (j.get("Type") == "Liquor") {
            amount = 50;
          }
          print("drink creating");
          print(j.get("Name"));
          print(j.get("%"));
          //Drink drink = new Drink(j.get("Name"), double.parse(this.fromMenu.elementAt(i).elementAt(0)), amount, j.get("%"));
          Drink drink = new Drink(j.get("Name"), 3.23, 568, double.parse(j.get("%").toString()));
          print("drink added");
          result.add(drink); //need to read the price and the amount from the menu
          print(drink.name + " " + drink.percent.toString() + " " +
              drink.value.toString());
        }
      } else{
        print("no match in db");
      }

    }}
    print(result.length);
    Comparator<Drink> compareValue = (a, b) => a.value.compareTo(b.value);
    result.sort(compareValue);
    List<Drink> outputList = result.reversed.toList();
    print("returning list of drinks length" + result.length.toString());
    print(result.elementAt(0).name);
    return (outputList);
  }

  @override
  Widget build(BuildContext context) {
    Future<List<Drink>> listOfDrinks = _getDrinks();
    print("LEMON TEST");
    return FutureBuilder(
      future: listOfDrinks,
      builder: (context, drinksList) {
        print("test0");
        return drinksList.connectionState == ConnectionState.done ?
        Scaffold(
            appBar: AppBar(
              title: Text("Results"),
            ),
            body: Container(
                child: Container(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.7,
                    child: ListView.builder(
                      itemCount: drinksList.data.length,
                      itemBuilder: (context, index) {
                      print(drinksList.data[index]);
                      print("test 1");
                      final Drink drink = drinksList.data[index];

                      return ListTile(
                        title: Text(drink.name),
                        subtitle: Text(drink.value.toStringAsFixed(2) + " Units per £"),
                      );
                    },
                    )


                )
            )
        ) : Center(child: CircularProgressIndicator(),);
      },
    );
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


//pass a list of drinks

}