import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';

/// `mq-skeleton`: a placeholder block that pulses while content loads.
class MqSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const MqSkeleton({super.key, this.width, required this.height, this.radius = MqRadius.md});

  @override
  State<MqSkeleton> createState() => _MqSkeletonState();
}

class _MqSkeletonState extends State<MqSkeleton> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.6).animate(_pulse),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: MqTheme.of(context).borderDefault,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
