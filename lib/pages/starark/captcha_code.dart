
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CaptchaWidget extends StatefulWidget {
  CaptchaWidget({Key? key}) : super(key: key);

  Uint8List? captchaBytes;
  ValueChanged<String>? onCaptchaSubmitted;

  @override
  State<StatefulWidget> createState() {
    return CaptchaWidgetState();
  }

}

class CaptchaWidgetState extends State<CaptchaWidget> {

  final _captchaKey = GlobalKey<FormState>();
  late final TextEditingController _captchaController;
  String get _captcha => _captchaController.text.trim();

  @override
  void initState() {
    super.initState();
    _captchaController = TextEditingController();
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  void updateCaptcha(Uint8List? captchaBytes) {
    setState(() {
      widget.captchaBytes = captchaBytes;
    });
  }

  @override
  Widget build(BuildContext context) {

    return widget.captchaBytes == null
        ? const SizedBox.shrink()
        : Column(
      children: <Widget>[
        Image.memory(widget.captchaBytes!),
        Form(
            key: _captchaKey,
            autovalidateMode:
            AutovalidateMode.onUserInteraction,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    autofocus: true,
                    controller: _captchaController,
                    textInputAction: TextInputAction.go,
                    onFieldSubmitted: (value) {
                      if (widget.onCaptchaSubmitted != null) {
                        widget.onCaptchaSubmitted!(_captcha);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      hintText: '请输入验证码',
                      prefixIcon: Icon(Icons.text_snippet),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入验证码';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(0, 4, 8, 4),
                  child: TextButton(
                    // color: Theme.of(context).primaryColor,
                    onPressed: () {
                      if (widget.onCaptchaSubmitted != null) {
                        widget.onCaptchaSubmitted!(_captcha);
                      }
                    },
                    // textColor: Colors.white,
                    child: const Text('开始'),
                  ),
                ),
              ],
            )),
        const Divider(),
      ],
    );
  }
}