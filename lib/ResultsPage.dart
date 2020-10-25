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

    FirebaseApp firebase = await Firebase.initializeApp();
    FirebaseFirestore _fireStoreInstance = FirebaseFirestore.instance;

    var collectionReference = _fireStoreInstance.collection('Drinks');
    List<Drink> result = [];
    QuerySnapshot snap;

    for (int i = 0; i < this.fromMenu.length; i++) {

      if(this.fromMenu.elementAt(i).length > 1){
        String name = "";
      for(int k=fromMenu.elementAt(i).length ; k > 1 ; k--){
        List<String> subList = this.fromMenu.elementAt(i).sublist(1,k);
        name = "";
        for(int y = 0;y<subList.length;y++){
          name = name + subList.elementAt(y) + " ";
        }
        name = name.trim();
        var query = collectionReference.where("Name", isEqualTo: name);
        snap = await query.get();
        if(snap.docs.isNotEmpty){
          break;
        }
      }

      if (snap.docs.isNotEmpty) {

        for (DocumentSnapshot j in snap.docs) {
          double amount = 568;
          if (j.get("Type") == "Beer") {
            amount = 568;
          }
          else if (j.get("Type") == "Liquor") {
            amount = 50;
          }

          //Drink drink = new Drink(j.get("Name"), double.parse(this.fromMenu.elementAt(i).elementAt(0)), amount, j.get("%"));
          Drink drink = new Drink(j.get("Name"), double.parse(this.fromMenu.elementAt(i).elementAt(0)), amount, double.parse(j.get("%").toString()));

          result.add(drink); //need to read the price and the amount from the menu

        }
      } else{

      }

    }}

    Comparator<Drink> compareValue = (a, b) => a.value.compareTo(b.value);
    result.sort(compareValue);
    List<Drink> outputList = result.reversed.toList();

    return (outputList);
  }

  AppBar resultsAppBar(){
    return AppBar(
      title: Text("Results"),
      centerTitle: true,
      backgroundColor: Color.fromARGB(255, 192, 57, 43),
    );
  }
  @override
  Widget build(BuildContext context) {
    Future<List<Drink>> listOfDrinks = _getDrinks();

    return FutureBuilder(
      future: listOfDrinks,
      builder: (context, drinksList) {

        return drinksList.connectionState == ConnectionState.done ?
        Scaffold(
            appBar: resultsAppBar(),
            body: Container(
                child: Container(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 1,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white,
                        height: 15,
                      ),
                      itemCount: drinksList.data.length,
                      itemBuilder: (context, index) {

                      final Drink drink = drinksList.data[index];

                      return Container(
                        
                        decoration: BoxDecoration(color: Color.fromRGBO(194,39,35, 60), borderRadius: BorderRadius.circular(25), ),

                        child: ListTile(
                          title: Text(drink.name, style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(drink.value.toStringAsFixed(2) + " Units per £", style: TextStyle(fontWeight: FontWeight.w500),),
                        ),
                      );

                    },
                    )


                )
            ),


        ) : Scaffold(backgroundColor: Colors.white,appBar: resultsAppBar(),body: Center(child: CircularProgressIndicator(),));
      },
    );
  }

  saveData(String pubName, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = pubName;
    final value = list;
    prefs.setStringList(key, value);

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

    }
  }


//pass a list of drinks

}