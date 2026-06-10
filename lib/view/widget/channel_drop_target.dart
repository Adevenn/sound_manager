import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';

/// Wraps a channel panel so audio files dragged in from the OS file explorer
/// (Windows Explorer, Finder, Nautilus…) are added to that channel.
///
/// Non-audio files are ignored. While a drag hovers, an accent-tinted overlay
/// invites the drop. [onFiles] receives the accepted (audio-only) paths.
class ChannelDropTarget extends StatefulWidget {
  final Widget child;
  final Color accent;
  final void Function(List<String> paths) onFiles;

  const ChannelDropTarget({
    super.key,
    required this.child,
    required this.accent,
    required this.onFiles,
  });

  @override
  State<ChannelDropTarget> createState() => _ChannelDropTargetState();
}

class _ChannelDropTargetState extends State<ChannelDropTarget> {
  bool _hovering = false;

  /// desktop_drop dispatches by screen region, so a drop aimed at a dialog
  /// (e.g. the fullscreen playlist editor) would also land on the channel
  /// hidden underneath. Only react while this route is on top.
  bool get _routeIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) {
        if (_routeIsCurrent) setState(() => _hovering = true);
      },
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (details) {
        final accept = _routeIsCurrent;
        setState(() => _hovering = false);
        if (!accept) return;
        final paths = details.files
            .map((f) => f.path)
            .where(isAudioFile)
            .toList(growable: false);
        if (paths.isNotEmpty) widget.onFiles(paths);
      },
      child: Stack(
        children: [
          widget.child,
          if (_hovering)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.accent, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_add_rounded,
                          color: widget.accent,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drop audio files here',
                          style: TextStyle(
                            color: widget.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
