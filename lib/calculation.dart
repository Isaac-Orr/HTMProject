import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
}

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
          Drink drink = new Drink(j.get("name"), 3, 500, j.get("%"));
          result.add(drink); //need to read the price and the amount from the menu
          print(drink);
        }
      }

    }
  }


