import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/collection.dart';
import 'package:recase/recase.dart';

import 'ResultsPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  ButtonStyle buttonStyle = ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Color.fromARGB(255, 192, 57, 43)));
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraDescription>(
      future: getCamera(),
      builder: (context, camera) {
        return Scaffold(
          backgroundColor: Color.fromARGB(255, 39, 174, 96),
            appBar: AppBar(
              title: Text("Alcohol/£ Analyser"),
              centerTitle: true,
              backgroundColor: Color.fromARGB(255, 192, 57, 43),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * .75,
                  width: MediaQuery.of(context).size.width,
                  child: cameraPreviewScreen(camera.data),
                ),
                ElevatedButton(
                  style: buttonStyle,
                  child: RichText(text: TextSpan(text: "Show Results", style: TextStyle(color: Colors.white))),

                  onPressed: () {showResults(context);},
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned(
                  bottom: 0,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Color.fromARGB(255, 192, 57, 43),

                      child: Icon(Icons.camera_alt),
                      // Provide an onPressed callback.
                      onPressed: () async {
                        // Take the Picture in a try / catch block. If anything goes wrong, catch error
                        try {
                          String path = await takePicture();
                          showDialog(context: context, builder: (_) => showPicturePreview(path, context), barrierDismissible: false);
                        } catch (e) {
                          // If an error occurs, log the error to the console.
                          print(e);
                        }
                      },
                    ),
                  ),
                )
              ],
            ));
      },
    );
    throw UnimplementedError();
  }

  showResults(BuildContext context){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsPage(priceNameSorted)));
  }


  showPicturePreview(String imagePath, BuildContext context){
    return AlertDialog(
      title: Text("Find Alchohol In Image?"),
      content: Image.file(File(imagePath)),
      actions: [
        FlatButton(color: Colors.red ,onPressed: () => Navigator.pop(context), child: Text("No")),
        FlatButton(color: Colors.green ,onPressed: () => {getTextFromPicture(imagePath, context), Navigator.pop(context)}, child: Text("Yes")),
        ],
    );
  }
  FutureBuilder cameraPreviewScreen(CameraDescription camera) {
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      camera,
      // Define the resolution to use.
      ResolutionPreset.veryHigh,
    );

    _initializeControllerFuture = _controller.initialize();

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return CameraPreview(_controller);
        } else {
          // Otherwise, display a loading indicator.
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<CameraDescription> getCamera() async {
    // Ensure that plugin services are initialized so that `availableCameras()`
    // can be called before `runApp()`
    WidgetsFlutterBinding.ensureInitialized();

    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    return firstCamera;
  }

  //todo add popup that shows image taken
  Future<String> takePicture() async {
    // Ensure that the camera is initialized.
    await _initializeControllerFuture;

    // Construct the path where the image should be saved using the path
    // package.
    final path = join(
      // Store the picture in the temp directory.
      // Find the temp directory using the `path_provider` plugin.
      (await getTemporaryDirectory()).path, '${DateTime.now()}.png',
    );

    // Attempt to take a picture and log where it's been saved.
    await _controller.takePicture(path);

    return path;
  }

  List<DocumentTextParagraph> allParagraphs = new List<DocumentTextParagraph>();

  getTextFromPicture(String path, BuildContext context) async {
    final File imageFile = File(path);

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final DocumentTextRecognizer cloudDocumentTextRecognizer =
        FirebaseVision.instance.cloudDocumentTextRecognizer();

    final VisionDocumentText visionDocumentText =
        await cloudDocumentTextRecognizer.processImage(visionImage);

    List<String> stringList = new List<String>();

    //adds all paragraphs in to single list
    for (int i = 0; i < visionDocumentText.blocks.length; i++) {
      DocumentTextBlock currentBlock = visionDocumentText.blocks.elementAt(i);
      for (int j = 0; j < currentBlock.paragraphs.length; j++) {
        allParagraphs.add(currentBlock.paragraphs.elementAt(j));
      }
    }

    for (int i = 0; i < allParagraphs.length; i++) {
      DocumentTextParagraph currentParagraph = allParagraphs.elementAt(i);
      for (int j = 0; j < currentParagraph.words.length; j++) {
        DocumentTextWord currentWord = currentParagraph.words.elementAt(j);

        if (currentWord.text.contains("%") ||
            currentWord.text.contains("ml") ||
            currentWord.text.contains("ML") ||
            currentWord.text.contains("Ml")) {
          if (j > 0 && stringList.length > 0) {
            if (!isRightCurrencyFormat(
                stringList.elementAt(stringList.length - 1))) {

              stringList.removeLast();
            }
          }
          continue;
        }

        if (currentWord.text.startsWith("£")) {

          if (currentWord.text.length == 1 &&
              currentParagraph.words.length < j + 1 &&
              currentParagraph.words.elementAt(j + 1).text != null) {
            String newWord =
                currentWord.text + currentParagraph.words.elementAt(j + 1).text;
            String sanatisedPrice =
                checkWordLengthAndSanatise(newWord, currentWord);
            if (sanatisedPrice != null) {

              stringList.add(sanatisedPrice);
              createEntryWithName(sanatisedPrice, j, currentParagraph,i);
              j++;
            }
            continue;
          }
        } else if (double.tryParse(currentWord.text) != null) {
          String sanatisedPrice =
              checkWordLengthAndSanatise(currentWord.text, currentWord);
          if (sanatisedPrice != null) {
            stringList.add(sanatisedPrice);
            createEntryWithName(sanatisedPrice, j, currentParagraph, i);
          }
        }
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsPage(priceNameSorted)));


    cloudDocumentTextRecognizer.close();
  }

  checkWordLengthAndSanatise(String word, DocumentTextWord documentTextWord) {


    if (documentTextWord.recognizedBreak != null &&
        documentTextWord.recognizedBreak.detectedBreakType != null) {

    }
    if (word.length == 4 &&
        word.indexOf(".") == 1 &&
        documentTextWord.recognizedBreak != null &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 1 &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 2 &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 4) {
      return word;
    } else if (word.length == 5 &&
        word.indexOf(".") == 2 &&
        documentTextWord.recognizedBreak != null &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 1 &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 2 &&
        documentTextWord.recognizedBreak.detectedBreakType.index != 4) {

      word = word.substring(1);
      return word;
    } else {
      return null;
    }
  }

  List<List<String>> priceNameSorted = new List<List<String>>();

  createEntryWithName(
      String price, int priceIndex, DocumentTextParagraph paragraph, int oldParagraphIndex) {
    int i = 0;
    List<String> list = new List<String>();

    Rect priceBounding = paragraph.words
        .elementAt(priceIndex)
        .boundingBox; //gets the bounding of the price we're trying to find the name for

    SplayTreeMap<double, DocumentTextParagraph> sortingParasByOverlap =
        new SplayTreeMap();

    int paragraphIndex = 0;

    while (paragraphIndex < allParagraphs.length) {
      if(paragraphIndex == oldParagraphIndex){
        paragraphIndex++;
        continue;
      }
      paragraph = allParagraphs.elementAt(paragraphIndex);

      Rect paragraphBounding = paragraph.words.last.boundingBox;

      double requiredLeftShift = priceBounding.right - paragraphBounding.right;

      Rect tempPriceBounding = priceBounding;
      tempPriceBounding = new Rect.fromLTRB(
          tempPriceBounding.left - requiredLeftShift,
          tempPriceBounding.top,
          tempPriceBounding.right - requiredLeftShift,
          tempPriceBounding.bottom);
      Rect intersection = tempPriceBounding.intersect(paragraphBounding);

      double currentAreaOfIntersection =
          intersection.width * intersection.height;

      sortingParasByOverlap[currentAreaOfIntersection] = paragraph;
      paragraphIndex++;
    }


    DocumentTextParagraph overlapParagraph = sortingParasByOverlap.values.last;

    while (i < overlapParagraph.words.length &&
        list.length < 4 &&
        (overlapParagraph.words.elementAt(i).recognizedBreak == null ||
            overlapParagraph.words
                    .elementAt(i)
                    .recognizedBreak
                    .detectedBreakType
                    .index !=
                2)) {


      if (overlapParagraph.words.elementAt(i).text.trim().startsWith(
          new RegExp(r"^[A-Z][a-zA-Z0-9]+$", caseSensitive: true))) {

        ReCase recase = new ReCase(overlapParagraph.words.elementAt(i).text);
        list.add(recase.sentenceCase);
      }
      i++;
    }

    if (i < overlapParagraph.words.length &&
        list.length < 4 &&
        overlapParagraph.words.elementAt(i) != null) {
      if (overlapParagraph.words.elementAt(i).text.trim().startsWith(
          new RegExp(r"^[A-Z][a-zA-Z0-9]+$", caseSensitive: true))) {
        ReCase recase = new ReCase(overlapParagraph.words.elementAt(i).text);
        list.add(recase.sentenceCase);
      }
    }

    list.insert(0, price);
    for (int position = 0; position<list.length; position++){
      if (list.elementAt(position).startsWith("A")  && (list.elementAt(position).substring(2).startsWith("V") || list.elementAt(position).substring(2).startsWith("v"))) {
        list.removeAt(position);
      }
    }
    priceNameSorted.add(list);
  }

  bool isRightCurrencyFormat(String word) {
    if (word.length == 4 && word.indexOf(".") == 1) {
      return true;
    }
    return false;
  }
}
