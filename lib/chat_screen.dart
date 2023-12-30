import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_firebase/text_composer.dart';

import 'dart:developer';

import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});


  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  void _sendMessage({String? text, XFile? imgFile}) async{
    Map<String, dynamic> data = {};

    final String imageUrl;
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDir = referenceRoot.child('images');


    if(imgFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        Reference referenceImage = referenceDir.child(fileName);
        await referenceImage.putFile(File(imgFile.path));

        imageUrl = await referenceImage.getDownloadURL();

        data['imgUrl'] = imageUrl;
      }
      catch(error){
        if (kDebugMode) {
          print(error);
        }
      }
    }
    if (text != null) data['text'] = text;

    FirebaseFirestore.instance.collection("messages").add(data);


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Olá',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: TextComposer(
        _sendMessage
      ),
    );
  }
}
