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

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraDescription>(
      future: getCamera(),
      builder: (context, camera) {
        return Scaffold(
            appBar: AppBar(
              title: Text("This is a title"),
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * .7,
                  width: MediaQuery.of(context).size.width,
                  child: cameraPreviewScreen(camera.data),
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
                      child: Icon(Icons.camera_alt),
                      // Provide an onPressed callback.
                      onPressed: () async {
                        // Take the Picture in a try / catch block. If anything goes wrong, catch error
                        try {
                          String path = await takePicture();
                          getTextFromPicture(path);
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

  getTextFromPicture(String path) async {
    final File imageFile = File(path);

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final DocumentTextRecognizer cloudDocumentTextRecognizer =
        FirebaseVision.instance.cloudDocumentTextRecognizer();

    final VisionDocumentText visionDocumentText =
        await cloudDocumentTextRecognizer.processImage(visionImage);

    String text = visionDocumentText.text;

    List<String> stringList = new List<String>();
    for (DocumentTextBlock block in visionDocumentText.blocks) {
      final Rect boundingBox = block.boundingBox;
      final String text = block.text;
      final List<RecognizedLanguage> languages = block.recognizedLanguages;
      final DocumentTextRecognizedBreak = block.recognizedBreak;

      cleanPargraphs(block, 0);

      for (int i = 0; i < block.paragraphs.length; i++) {
        DocumentTextParagraph currentParagraph = block.paragraphs.elementAt(i);
        for (int j = 0; j < currentParagraph.words.length; j++) {
          DocumentTextWord currentWord = currentParagraph.words.elementAt(j);

          if (currentWord.text.contains("%") || currentWord.text.contains("ml") ||
              currentWord.text.contains("ML") ||
              currentWord.text.contains("Ml")) {
            if (j > 0 && stringList.length > 0) {
              if (!isRightCurrencyFormat(
                  stringList.elementAt(stringList.length - 1))) {
                print("Removing bc of percent" +
                    stringList.elementAt(stringList.length - 1));
                stringList.removeLast();
              }
            }
            continue;
          }

          if (currentWord.text.startsWith("£")) {
            print(currentWord.text);
            if (currentWord.text.length == 1 &&
                currentParagraph.words.length < j + 1 &&
                currentParagraph.words.elementAt(j + 1).text != null) {
              String newWord = currentWord.text +
                  currentParagraph.words.elementAt(j + 1).text;
              String sanatisedPrice = checkWordLengthAndSanatise(newWord, currentWord);
              if (sanatisedPrice != null) {
                print("Break Type" + currentWord.recognizedBreak.detectedBreakType.index.toString());
                stringList.add(sanatisedPrice);
                createEntryWithName(sanatisedPrice, j, currentParagraph, i, block);
                j++;
              }
              continue;
            }
          } else if (double.tryParse(currentWord.text) != null) {
            String sanatisedPrice = checkWordLengthAndSanatise(currentWord.text, currentWord);
            if (sanatisedPrice != null) {
              stringList.add(sanatisedPrice);
              createEntryWithName(sanatisedPrice, j, currentParagraph, i, block);
            }
          }
        }
      }
    }

    print(stringList.toString());
    print(priceNameSorted);

    cloudDocumentTextRecognizer.close();
  }

  checkWordLengthAndSanatise(String word, DocumentTextWord documentTextWord) {
    print("Going in to sanatiser " + word);

    if(documentTextWord.recognizedBreak != null && documentTextWord.recognizedBreak.detectedBreakType != null) {
      print("Break Type " +
          documentTextWord.recognizedBreak.detectedBreakType.index.toString());
    }
      if (word.length == 4 && word.indexOf(".") == 1
          && documentTextWord.recognizedBreak.detectedBreakType.index != 1
          && documentTextWord.recognizedBreak.detectedBreakType.index != 2
          && documentTextWord.recognizedBreak.detectedBreakType.index != 4) {
        print(4);
        return word;
      } else if (word.length == 5 && word.indexOf(".") == 2
          && documentTextWord.recognizedBreak.detectedBreakType.index != 1
          && documentTextWord.recognizedBreak.detectedBreakType.index != 2
          && documentTextWord.recognizedBreak.detectedBreakType.index != 4) {
        print(5);
        word = word.substring(1);
        return word;
      } else {
        return null;
      }
    }
  }

  List<List<String>> priceNameSorted = new List<List<String>>();

  cleanPargraphs(DocumentTextBlock documentTextBlock, int startingParagraphIndex){
      for(int i = 0;i<documentTextBlock.paragraphs.length;i++){
        //print("Paragraph" + documentTextBlock.paragraphs.elementAt(i).text + "Has Length" + documentTextBlock.paragraphs.elementAt(i).words.length.toString());
      }
  }

  createEntryWithName(String price, int priceIndex, DocumentTextParagraph paragraph, int paragraphIndex, DocumentTextBlock documentTextBlock){
    print("Working with price " + price);
    int i = 0;
    List<String> list = new List<String>();

    Rect priceBounding = paragraph.words.elementAt(priceIndex).boundingBox;    //gets the bounding of the price we're trying to find the name for

    SplayTreeMap<double, DocumentTextParagraph> sortingParasByOverlap = new SplayTreeMap();

    int j = 0;

    paragraphIndex = 0;

    while(paragraphIndex < documentTextBlock.paragraphs.length){
      paragraph = documentTextBlock.paragraphs.elementAt(paragraphIndex);

      Rect paragraphBounding = paragraph.words.last.boundingBox;

      double requiredLeftShift = priceBounding.right - paragraphBounding.right;

      Rect tempPriceBounding = priceBounding;
      //print("OPERATING ON PARAGRAPH " + paragraph.text);
      //print("paragraph POINTS before " + paragraphBounding.left.toString());
      //print("TEMPPRICEBOUNDING POINTS before" + tempPriceBounding.left.toString());
      //print("REQUIREDLEFTSHIFT "+ requiredLeftShift.toString());
      tempPriceBounding = new Rect.fromLTRB(tempPriceBounding.left - requiredLeftShift, tempPriceBounding.top, tempPriceBounding.right - requiredLeftShift, tempPriceBounding.bottom);
      //print("paragraph POINTS " + paragraphBounding.left.toString());
      //print("TEMPPRICEBOUNDING POINTS " + tempPriceBounding.left.toString());
      Rect intersection = tempPriceBounding.intersect(paragraphBounding);

      double currentAreaOfIntersection = intersection.width * intersection.height;

      //print("Overlap is " + currentAreaOfIntersection.toString() + "For Paragraph " + paragraph.text);
      sortingParasByOverlap[currentAreaOfIntersection] = paragraph;
      paragraphIndex++;
    }

    DocumentTextParagraph overlapParagraph = sortingParasByOverlap.values.last;
    print("BIGGEST OVERLAP PARA WAS " + sortingParasByOverlap.values.last.text + "FOR PRICE " + price);


    while(i < overlapParagraph.words.length && list.length<4 && (overlapParagraph.words.elementAt(i).recognizedBreak == null || overlapParagraph.words.elementAt(i).recognizedBreak.detectedBreakType.index != 2)){
      if(overlapParagraph.words.elementAt(i).text.trim().startsWith(new RegExp(r"^[A-Z][a-zA-Z0-9]+$", caseSensitive: true))){
        print(overlapParagraph.words.elementAt(i).text + "Matches");
        print("List before " + list.toString());
        list.add(overlapParagraph.words.elementAt(i).text);
        print("List After " + list.toString());
      }
      i++;
    }

    if(i < overlapParagraph.words.length && list.length<4 && overlapParagraph.words.elementAt(i) != null){
      if(overlapParagraph.words.elementAt(i).text.trim().startsWith(new RegExp(r"^[A-Z][a-zA-Z0-9]+$", caseSensitive: true))){
        print(overlapParagraph.words.elementAt(i).text + "Matches");
        print("List before " + list.toString());
        list.add(overlapParagraph.words.elementAt(i).text);
        print("List After " + list.toString());
      }
    }

    list.insert(0, price);


    priceNameSorted.add(list);
  }

  bool isRightCurrencyFormat(String word) {
    if (word.length == 4 && word.indexOf(".") == 1) {
      return true;
    }
    return false;
  }

