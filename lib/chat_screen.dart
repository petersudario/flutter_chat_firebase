import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_firebase/text_composer.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:image_picker/image_picker.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  GoogleSignIn googleSignIn = GoogleSignIn();
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication gAuth = await gUser!.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;

      return user;
    } catch (error) {
      if (kDebugMode) {
        print('COULD NOT LOGIN');
        print(error);
      }
      return null;
    }
  }

  void _sendMessage({String? text, XFile? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possivel fazer login.")));
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "senderName": user?.displayName,
      "senderPhotoUrl": user?.photoURL,
      "datetime": Timestamp.now(),
    };

    final String imageUrl;

    if (imgFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        UploadTask task = FirebaseStorage.instance.ref().child('images').child('${user!.uid}_$fileName.png').putFile(File(imgFile.path));

        setState(() {
          _isLoading = true;
        });

        TaskSnapshot taskSnapshot = await task.whenComplete(() => null);
        imageUrl = await taskSnapshot.ref.getDownloadURL();
        data['imgUrl'] = imageUrl;

        setState(() {
          _isLoading = false;
        });
      } catch (error) {
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
        title: Text(
          _currentUser != null
              ? 'Olá, ${_currentUser?.displayName}.'
              : 'PearlChat - Você não está logado.',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  icon: const Icon(
                    Icons.exit_to_app,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Você deslogou com sucesso!")));
                  },
                )
              : Container()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('messages').orderBy('datetime').snapshots(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                default:
                  List<DocumentSnapshot> documents =
                      snapshot.data!.docs.reversed.toList();

                  return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return ChatMessage(
                            documents[index].data() as Map<String, dynamic>,
                            documents[index].get('uid') == _currentUser?.uid);
                      });
              }
            },
          )),
          _isLoading ? const LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
