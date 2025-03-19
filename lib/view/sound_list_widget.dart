import 'package:flutter/material.dart';

class SoundListWidget extends StatelessWidget {
  const SoundListWidget({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.2,
      height: MediaQuery.sizeOf(context).height / 1.2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: Center(child: Text('Selected sounds'))),
              VerticalDivider(),
              Expanded(child: Center(child: Text('List sounds'))),
            ],
          ),
        ),
      ),
    ),
  );
}
