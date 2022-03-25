import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends AuthRequiredState<HomePage> {
  String? _currentUserEmail;
  String? _currentUserAvatarSrc;

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _currentUserEmail = session.user!.email;
      final qq = _currentUserEmail!.split("@")[0];
      if (_currentUserEmail!.endsWith("@qq.com")) {
        _currentUserAvatarSrc = "http://q1.qlogo.cn/g?b=qq&nk=$qq&s=100";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("首页"),
        actions: [
          IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout)
          ),
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/reset_pwd');
              },
              icon: const Icon(Icons.admin_panel_settings)
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _currentUserEmail != null
              ? Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                      child: _currentUserAvatarSrc != null ?
                      Image.network(_currentUserAvatarSrc!) :
                      const Text("当前用户"),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(_currentUserEmail!),
                    )
                  ],
                )
              : const SizedBox.shrink(),
          Expanded(
            child: Center(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: TextButton(
                            // color: Theme.of(context).primaryColor,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/starark');
                            },
                            // textColor: Colors.white,
                            child: const Text('Go StarArk'),
                          ),
                        )
                      ),
                    ],
                  )),
            ),
          ),
        ],
      ),
    );
  }

  void _signOut() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("确认退出登陆"),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确认'),
            onPressed: () async {
              final response = await supabase.auth.signOut();
              final error = response.error;
              if (error != null) {
                context.showErrorSnackBar(message: error.message);
              }
            },
          ),
        ],
      );
    });
  }
}
