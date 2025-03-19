import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: 80, height: 80, child: CircularProgressIndicator()),
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Loading ...'),
          ),
        ],
      ),
    ),
  );
}
