import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_firestore/videoplay.dart';
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
  VideoPlayerController playerController;
  VoidCallback listener;
  File file;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

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
      setState(() {});
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
        _imageSubmit(imageUrl, type);
        buildLoading(false);
      });
    }, onError: (err) {
      setState(() {
        buildLoading(false);
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void createVideo() {
    if (playerController == null) {
      playerController = VideoPlayerController.network(
          "https://firebasestorage.googleapis.com/v0/b/chatflutter-c3caa.appspot.com/o/img_1547187850813?alt=media&token=565fe956-f39b-4021-987a-1de902f85521")
        ..addListener(listener)
        ..setVolume(1.0)
        ..initialize()
        ..play();
      playerController.play();
    } else {
      if (playerController.value.isPlaying) {
        playerController.pause();
      } else {
        playerController.initialize();
        playerController.play();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    listener = () {
      setState(() {});
    };
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
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 10.0,
            ),
            Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  message,
                  style: new TextStyle(
                      fontWeight: FontWeight.normal, color: Colors.grey),
                )),
          ],
        ),
        Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                openDialog(ownUrl, messageType);
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    child: Material(
                      child: CachedNetworkImage(
                        placeholder: Container(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                          ),
                          width: 170.0,
                          height: 170.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
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
                            Radius.circular(10.0),
                          ),
                        ),
                        imageUrl: ownUrl,
                        width: 150.0,
                        height: 150.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Text(
                  dateFormatter(time),
                  style: new TextStyle(
                      fontWeight: FontWeight.w400, color: Colors.grey,fontSize: 13.0,),
                )),
          ],
        ),
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CircleAvatar(
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            Container(
              child: Text(
                userName,
                style: new TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
            ),
          ],
        )
      ]);
    } else if (messageType == 0) {
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  Container(
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          message,
                          style: new TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            decorationStyle: TextDecorationStyle.wavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            dateFormatter(time),
                            textAlign: TextAlign.right,
                            style: new TextStyle(
                                fontWeight: FontWeight.w200,
                                color: Colors.white),
                          )),
                    ],
                  )
                ],
              ),
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0)),
            ),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    } else if (messageType == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        image: DecorationImage(
                            image: ExactAssetImage('images/playbutton.png'),
                            fit: BoxFit.cover)),
                    width: 150.0,
                    height: 150.0,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, anim1, anim2) => VideoPlay(
                          url: ownUrl,
                        ),
                        transitionsBuilder: (context, anim1, anim2, child) =>
                            FadeTransition(opacity: anim1, child: child),
                        transitionDuration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        message,
                        style: new TextStyle(
                            fontWeight: FontWeight.normal, color: Colors.grey),
                      )),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    dateFormatter(time),
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),

            ],
          ),
          Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            )
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
      int messageType) {
    if (messageType == 1) {
      return Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 10.0,
            ),
            Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  message,
                  style: new TextStyle(
                      fontWeight: FontWeight.normal, color: Colors.grey),
                )),
          ],
        ),
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CircleAvatar(
                child: Icon(Icons.person, color: Colors.white),
                backgroundColor: Colors.indigo,
              ),
            ),
            Container(
              child: Text(
                userName,
                style: new TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                openDialog(msgUrl, messageType);
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    child: Material(
                      child: CachedNetworkImage(
                        placeholder: Container(
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                          width: 170.0,
                          height: 170.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
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
                            Radius.circular(10.0),
                          ),
                        ),
                        imageUrl: msgUrl,
                        width: 150.0,
                        height: 150.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Text(
                  dateFormatter(time),
                  style: new TextStyle(
                    fontWeight: FontWeight.w400, color: Colors.grey,fontSize: 13.0,),
                )),
          ],
        ),
      ]);
    }else if(messageType==0) {

      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: Colors.indigo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    userName,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: Column(
                children: <Widget>[
                  Container(
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          message,
                          style: new TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            decorationStyle: TextDecorationStyle.wavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            dateFormatter(time),
                            textAlign: TextAlign.right,
                            style: new TextStyle(
                                fontWeight: FontWeight.w200,
                                color: Colors.white),
                          )),
                    ],
                  )
                ],
              ),
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(8.0)),
            ),
          ],
        ),
      );
    } else if (messageType == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                  backgroundColor: Colors.indigo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  userName,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        image: DecorationImage(
                            image: ExactAssetImage('images/playbutton.png'),
                            fit: BoxFit.cover)),
                    width: 150.0,
                    height: 150.0,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, anim1, anim2) => VideoPlay(
                          url: msgUrl,
                        ),
                        transitionsBuilder: (context, anim1, anim2, child) =>
                            FadeTransition(opacity: anim1, child: child),
                        transitionDuration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        message,
                        style: new TextStyle(
                            fontWeight: FontWeight.normal, color: Colors.grey),
                      )),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    dateFormatter(time),
                    style: new TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.grey),
                  )),

            ],
          ),
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

  Widget buildLoading(bool loading) {
    return Positioned(
      child: loading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
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
                    getFile(false, 1);
                    Navigator.of(context).pop();
                    buildLoading(true);
                  },
                ),
                new FlatButton(
                  child: Row(
                    // Replace with a Row for horizontal icon + text
                    children: <Widget>[Icon(Icons.photo), Text("Image")],
                  ),
                  onPressed: () {
                    getFile(true, 1);
                    buildLoading(true);
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
                    getFile(true, 2);
                    buildLoading(true);
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

  void openDialog(String url, int msgType) {
    if (msgType == 1) {
      showDialog(
          context: context,
          builder: (ctxt) => new AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: Container(
                  decoration: new BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius:
                        new BorderRadius.all(new Radius.circular(32.0)),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fadeInCurve: Curves.bounceIn,
                    fadeInDuration: const Duration(milliseconds: 500),
                    fit: BoxFit.contain,
                  ),
                ),
              ));
    } else if (msgType == 2) {
      showDialog(
          context: context,
          builder: (ctxt) => new AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: Container(
                  width: 400.0,
                  height: 400.0,
                  decoration: new BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius:
                        new BorderRadius.all(new Radius.circular(32.0)),
                  ),
                  child: (playerController != null
                      ? VideoPlayer(
                          playerController,
                        )
                      : Container(
                          height: 400.0,
                          width: 400.0,
                          child: Center(
                              child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              "Some thing went wrong !",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 20.0,
                              ),
                            ),
                          )),
                        )),
                ),
              ));
    }
  }
}
