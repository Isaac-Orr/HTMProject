import 'package:cloud_firestore/cloud_firestore.dart';

FireStore _fireStoreInstance = Firestore.instance;

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

void getDrinks(Set names){
  var collectionReference = _fireStoreInstance.collection('Drinks');
  List<Drink> result = [];

  for(int i = 0; i < names.length; i++){
     String name = names.elementAt(i);
     var query = collectionReference.where("Name", "==", name);

     QuerySnapshot snap = await query.getDocuments();

     if(snap.documents.lenght > 0){
       for(DocumentSnapshot j in snap.documents){
         result.add(new Drink(j.data["name"], 3, 500, j.data["percent"])); //need to read the price and the amount from the menu
       }
     }




  }



}