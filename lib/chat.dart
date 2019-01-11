import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_player/video_player.dart';

class ChatPage extends StatefulWidget {
  ChatPage(this._userName);

  final String _userName;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  File file;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  VideoPlayerController _controller1;

  Future getFile(bool selectType, int type) async {
    if (type == 1)
      file = selectType
          ? await ImagePicker.pickImage(source: ImageSource.gallery)
          : await ImagePicker.pickImage(source: ImageSource.camera);
    else
      file = selectType
          ? await ImagePicker.pickVideo(source: ImageSource.gallery)
          : await ImagePicker.pickVideo(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile(file, type);
    }
  }

  Future uploadFile(File file, int type) async {
    print('upload file entered');
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    StorageReference reference =
        FirebaseStorage.instance.ref().child("img_" + timestamp.toString());
    StorageUploadTask uploadTask = reference.putFile(file);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      print(imageUrl);
      setState(() {
        isLoading = false;
        _imageSubmit(imageUrl, type);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Chat Screen"),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: <Widget>[
              new Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance
                      .collection("chat_room")
                      .orderBy("created_at", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container();
                    return new ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      reverse: true,
                      itemBuilder: (_, int index) {
                        DocumentSnapshot document =
                            snapshot.data.documents[index];
                        bool isOwnMessage = false;
                        if (document['user_name'] == widget._userName) {
                          isOwnMessage = true;
                        }
                        return isOwnMessage
                            ? _ownMessage(
                                document['message'],
                                document['user_name'],
                                document['created_at'],
                                document['image'],
                                document['messageType'])
                            : _message(
                                document['message'],
                                document['user_name'],
                                document['created_at'],
                                document['image'],
                                document['messageType']);
                      },
                      itemCount: snapshot.data.documents.length,
                    );
                  },
                ),
              ),
              Divider(height: 2.0),
              Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                margin: EdgeInsets.only(bottom: 20.0, right: 10.0, left: 10.0),
                child: Row(
                  children: <Widget>[
                    new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 4.0),
                        child: new IconButton(
                          icon: new Icon(
                            Icons.attach_file,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: _selectFile,
                        )),
                    Flexible(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _handleSubmit,
                        decoration:
                            InputDecoration.collapsed(hintText: "Send message"),
                      ),
                    ),
                    Container(
                      child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.lightBlue,
                          ),
                          onPressed: () {
                            _handleSubmit(_controller.text);
                          }),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }

  void _handleSubmit(String message) {
    _controller.text = "";
    var db = Firestore.instance;
    db.collection("chat_room").add({
      "user_name": widget._userName,
      "message": message,
      "created_at": DateTime.now(),
      "image": "",
      "messageType": 0,
    }).then((val) {
      print("sucess");
    }).catchError((err) {
      print(err);
    });
  }

  void _imageSubmit(String img, int msgType) {
    var db = Firestore.instance;
    db.collection("chat_room").add({
      "user_name": widget._userName,
      "message": "",
      "created_at": DateTime.now(),
      "image": img,
      "messageType": msgType,
    }).then((val) {
      print("sucess");
    }).catchError((err) {
      print(err);
    });
  }

  Widget _ownMessage(String message, String userName, DateTime time,
      String ownUrl, int messageType) {
    if (messageType == 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  )),
              Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    message,
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
              Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    dateFormatter(time),
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CachedNetworkImage(
              placeholder: Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                ),
                width: 150.0,
                height: 150.0,
                padding: EdgeInsets.all(70.0),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              errorWidget: Material(
                child: Image.asset(
                  'images/img_not_available.jpeg',
                  width: 150.0,
                  height: 150.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              imageUrl: ownUrl,
              width: 150.0,
              height: 150.0,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    } else if (messageType == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  )),
              Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    message,
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
              Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    dateFormatter(time),
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      );
    } else if (messageType == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  )),
              Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    message,
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
              Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    dateFormatter(time),
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: new Container(),
          ),
        ],
      );
    }
  }

// Date formatter
  String dateFormatter(DateTime date) {
    String formattedDate = DateFormat('kk:mm').format(date);
    return formattedDate;
  }

  Widget _message(String message, String userName, DateTime time, String msgUrl,
      int msgType) {
    if (msgUrl != "") {
      return Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Colors.deepPurple,
            ),
          ),
          Column(
            // crossAxisAlignment: CrossAxisAlignment.center,

            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  userName,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  message,
                  style: new TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  dateFormatter(time),
                  style: new TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: CachedNetworkImage(
                  placeholder: Container(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                    ),
                    width: 150.0,
                    height: 150.0,
                    padding: EdgeInsets.all(70.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
                  errorWidget: Material(
                    child: Image.asset(
                      'images/img_not_available.jpeg',
                      width: 150.0,
                      height: 150.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                  imageUrl: msgUrl,
                  width: 150.0,
                  height: 150.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
          )
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Colors.deepPurple,
            ),
          ),
          Column(
            // crossAxisAlignment: CrossAxisAlignment.center,

            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  userName,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  message,
                  style: new TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  dateFormatter(time),
                  style: new TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          )
        ],
      );
    }
  }

// user defined function
  void _selectFile() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog

        return AlertDialog(
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                  child: Row(
                    // Replace with a Row for horizontal icon + text
                    children: <Widget>[Icon(Icons.camera), Text("Camera")],
                  ),
                  onPressed: () {
                    getFile(false, 0);
                    Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: Row(
                    // Replace with a Row for horizontal icon + text
                    children: <Widget>[Icon(Icons.photo), Text("Image")],
                  ),
                  onPressed: () {
                    getFile(true, 0);
                    Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: Row(
                    // Replace with a Row for horizontal icon + text
                    children: <Widget>[
                      Icon(Icons.video_library),
                      Text("Video")
                    ],
                  ),
                  onPressed: () {
                    getFile(true, 1);
                    Navigator.of(context).pop();
                  },
                )
              ],
            )
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
}
