import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moneyshare/HomePage.dart';

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


}