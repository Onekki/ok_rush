import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPwdPage extends StatefulWidget {
  const ResetPwdPage({Key? key}) : super(key: key);

  @override
  _ResetPwdPageState createState() => _ResetPwdPageState();
}

class _ResetPwdPageState extends AuthRequiredState<ResetPwdPage> {
  bool _isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  final GlobalKey _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    super.initState();
  }

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _emailController.text = session.user!.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('重置密码')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        autofocus: true,
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                          hintText: '请输入邮箱',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入邮箱';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: '密码',
                            hintText: '请输入密码',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            )),
                        obscureText: !showPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _confirmController,
                        textInputAction: TextInputAction.go,
                        decoration: InputDecoration(
                            labelText: '密码',
                            hintText: '请再次输入密码',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            )),
                        obscureText: !showConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          if (value != _passwordController.text) {
                            return '两次密码不一样';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 25),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints.expand(height: 44.0),
                          child: ElevatedButton(
                            // color: Theme.of(context).primaryColor,
                            onPressed: _resetPwd,
                            // textColor: Colors.white,
                            child: const Text('重置'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _resetPwd() async {
    setState(() {
      _isLoading = true;
    });
    final response = await supabase.auth.update(UserAttributes(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()));
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    } else {
      context.showSnackBar(message: '重置成功');
      Navigator.of(context).pop();
    }
    setState(() {
      _isLoading = false;
    });
  }
}
