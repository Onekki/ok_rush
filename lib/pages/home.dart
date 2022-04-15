import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/rush_page.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends AuthRequiredState<HomePage> {
  final List<RushContainer> _rushContainers = [];

  bool _isLoading = false;
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
      _fetchRushes();
    }
  }

  void _fetchRushes() async {
    setState(() {
      _isLoading = true;
    });
    final response =
        await supabase.from("rushes").select("platform,category").execute();
    if (response.error != null) {
      context.showErrorSnackBar(message: response.error!.message);
    } else {
      _rushContainers.clear();
      response.data.forEach((item) {
        final container = RushContainer.jsonDecode(item);
        _rushContainers.add(container);
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("首页"),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/reset_pwd');
              },
              icon: const Icon(Icons.admin_panel_settings)),
        ],
      ),
      body: _currentUserEmail != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                  child: _currentUserAvatarSrc != null
                      ? Image.network(_currentUserAvatarSrc!)
                      : const Text("当前用户"),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(_currentUserEmail!),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ListView.builder(
                          itemCount: _rushContainers.length,
                          itemBuilder: (context, index) {
                            final item = _rushContainers[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RushPage(rushContainer: item)));
                              },
                              child: Chip(
                                // textColor: Colors.white,
                                label:
                                    Text("${item.platform}:${item.category}"),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  void _signOut() {
    showDialog(
        context: context,
        builder: (context) {
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
