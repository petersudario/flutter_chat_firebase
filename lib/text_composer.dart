

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {

  const TextComposer(this.sendMessage, {super.key});

  final Function({String text, XFile imgFile}) sendMessage;
  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {

  final TextEditingController _controller = TextEditingController();

  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () async {
              final XFile? imgFile = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (imgFile == null) return;
              widget.sendMessage(imgFile: imgFile);
            },
            icon: const Icon(Icons.photo_camera),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(
                  hintText: 'Enviar uma mensagem'),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                widget.sendMessage(text: text);
                _controller.clear();
              },
            ),
          ),
          IconButton(
            onPressed: _isComposing ? () {
              widget.sendMessage(text: _controller.text);
              _controller.clear();
            } : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
