import 'dart:io';
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
            body:Row(crossAxisAlignment: CrossAxisAlignment.start,children: [

                Container(
                  height: MediaQuery.of(context).size.height * .7,
                  width: MediaQuery.of(context).size.width,
                  child: cameraPreviewScreen(camera.data),
                ),

            ],),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      ResolutionPreset.medium,
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

    print("BOOOGIEEEE" + text);

    for (DocumentTextBlock block in visionDocumentText.blocks) {
      final Rect boundingBox = block.boundingBox;
      final String text = block.text;
      final List<RecognizedLanguage> languages = block.recognizedLanguages;
      final DocumentTextRecognizedBreak = block.recognizedBreak;

      for (DocumentTextParagraph paragraph in block.paragraphs) {
        // Same getters as DocumentTextBlock
        for (DocumentTextWord word in paragraph.words) {
          // Same getters as DocumentTextBlock
          for (DocumentTextSymbol symbol in word.symbols) {
            // Same getters as DocumentTextBlock
          }
        }
      }
    }

    cloudDocumentTextRecognizer.close();
  }
}
