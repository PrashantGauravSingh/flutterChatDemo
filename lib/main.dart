import 'package:flutter/material.dart';
import 'package:flutter_chat_firestore/chat.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  final _controller=TextEditingController();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FrndzChat"),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[

                TextFormField(
                  controller: _controller,
                  autofocus: false,
                  decoration: new InputDecoration(labelText: "Enter username",
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
                  ),

                ),
              ],
            )
          ),
          RaisedButton(
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (builder) => ChatPage(_controller.text)));
            },
            child: Text(
              "PING",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
