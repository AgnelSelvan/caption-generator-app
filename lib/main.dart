import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart' as mime;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caption Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Caption Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File selectedImage;
  final picker = ImagePicker();
  var op;
  bool isLoading = false;
  final FlutterTts _flutterTts = FlutterTts();

  Future _speak(String message) async {
    await _flutterTts.speak(message);
  }

  getResponse() async {
    setState(() {
      isLoading = true;
    });
    print("EHllo");
    String filename = selectedImage.path.split('/').last;
    print(filename);
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          "http://max-image-caption-generator.codait-prod-41208c73af8fca213512856c7a09db52-0000.us-east.containers.appdomain.cloud/model/predict"),
    );
    Map<String, String> headers = {"Content-type": "multipart/form-data"};
    request.files.add(
      http.MultipartFile(
        'image',
        selectedImage.readAsBytes().asStream(),
        selectedImage.lengthSync(),
        filename: filename,
        contentType: mime.MediaType("image", "jpg"),
      ),
    );
    request.headers.addAll(headers);
    print("request: " + request.toString());
    var res = await request.send();
    var response = await http.Response.fromStream(res);
    print("This is response:" + response.body);
    print("This is response: ${res.statusCode} ");
    print("This is response: ${res.statusCode} ");
    var resJson = jsonDecode(response.body);
    if (resJson['status'] == 'ok') {
      setState(() {
        op = resJson['predictions'][0]['caption'];
      });
      if (op != null && op != "") _speak(op.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  selectedImage == null
                      ? Container(
                          child: Text("No Image Selected"),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Image.file(selectedImage)),
                              RaisedButton(
                                onPressed: () async {
                                  getResponse();
                                  // print(res.body);
                                },
                                color: Colors.blue[400],
                                textColor: Colors.white,
                                child: Text("Upload"),
                              ),
                              op == null || op == ""
                                  ? Container()
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                          Text(op),
                                          IconButton(
                                              onPressed: () {
                                                if (op != null && op != "")
                                                  _speak(op.toString());
                                              },
                                              icon: Icon(Icons.play_arrow,
                                                  color: Colors.green[500])),
                                        ])
                              // Text("Result : ")
                            ],
                          ),
                        )
                ],
              ),
            ),
            isLoading
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator()),
                      ],
                    ),
                  )
                : Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showImageDialog(context);
        },
        tooltip: 'Add Photo',
        child: Icon(Icons.photo),
      ),
    );
  }

  showImageDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(title: Text("Select Image"), children: [
            InkWell(
              onTap: () async {
                final pickedFile =
                    await picker.getImage(source: ImageSource.gallery);

                setState(() {
                  if (pickedFile != null) {
                    selectedImage = File(pickedFile.path);
                  } else {
                    print('No image selected.');
                  }
                });
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Gallery"),
              ),
            ),
            InkWell(
              onTap: () async {
                final pickedFile =
                    await picker.getImage(source: ImageSource.camera);

                setState(() {
                  if (pickedFile != null) {
                    selectedImage = File(pickedFile.path);
                  } else {
                    print('No image selected.');
                  }
                });
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Camera"),
              ),
            )
          ]);
        });
  }
}

class MediaType {}
