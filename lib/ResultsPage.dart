import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moneyshare/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _ResultsPageState();
  }
}

class _ResultsPageState extends State<ResultsPage>{
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
    result =  "test";
  }


  saveData(String pubName, List<String> list) async{
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
    while(i.moveNext())
    {
      key = i.current;
      value = prefs.getStringList(key);
      print('read $value from $key');
    }

}