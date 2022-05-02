import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/rush_page.dart';
import 'package:ok_rush/utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends AuthRequiredState<HomePage> {
  final List<String> _platforms = [];
  final Map<String, List<RushContainer>> _rushContainers = {};

  bool _isLoading = false;
  String? _currentUserEmail;
  String? _currentUserAvatarSrc;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null) {
      _currentUserEmail = supabase.auth.currentUser!.email;
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
      _platforms.clear();
      _rushContainers.clear();
      response.data.forEach((item) {
        final container = RushContainer.jsonDecode(item);
        if (!_platforms.contains(container.platform)) {
          _platforms.add(container.platform);
          _rushContainers.putIfAbsent(container.platform, () => []);
        }
        _rushContainers[container.platform]?.add(container);
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
          IconButton(
              onPressed: () {
                _fetchRushes();
              },
              icon: const Icon(Icons.refresh)),
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
                    itemCount: _platforms.length,
                          itemBuilder: (context, index) {
                            final item = _platforms[index];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, top: 16, bottom: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.red.withAlpha(50),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        for (var rushContainer
                                            in _rushContainers[item]!)
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          RushPage(
                                                              rushContainer:
                                                                  rushContainer)));
                                            },
                                            // textColor: Colors.white,
                                            child: Text(rushContainer.category),
                                            style: ButtonStyle(
                                                shape: MaterialStateProperty
                                                    .all(RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    24.0)))),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
