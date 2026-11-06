import 'package:flutter/widgets.dart';

import '../mq_theme.dart';

@immutable
class MqIconData {
  final double viewBox;
  final String path;

  const MqIconData(this.viewBox, this.path);
}

abstract final class MqIcons {
  static const alertCircle = MqIconData(20,
      'M10 6.66667V10M10 13.3333H10.0083M18.3333 10C18.3333 14.6024 14.6024 18.3333 10 18.3333C5.39763 18.3333 1.66667 14.6024 1.66667 10C1.66667 5.39763 5.39763 1.66667 10 1.66667C14.6024 1.66667 18.3333 5.39763 18.3333 10Z');
  static const arrowLeft = MqIconData(20, 'M16.6667 10H3.33333M8.33333 5L3.33333 10L8.33333 15');
  static const arrowRight = MqIconData(20, 'M4.16667 10H15.8333M10 15.8333L15.8333 10L10 4.16667');
  static const camera = MqIconData(20,
      'M12.0157 1.66667H7.98428C7.8731 1.66667 7.81751 1.66667 7.76718 1.66971C7.12449 1.70864 6.56171 2.11427 6.32155 2.71167C6.30274 2.75845 6.28516 2.81119 6.25 2.91667C6.21484 3.02214 6.19726 3.07488 6.17845 3.12167C5.93829 3.71906 5.37551 4.1247 4.73282 4.16362C4.68249 4.16667 4.62321 4.16667 4.50465 4.16667C4.19696 4.16667 4.04312 4.16667 3.92018 4.17885C2.73439 4.29633 1.79633 5.23439 1.67885 6.42018C1.66667 6.54312 1.66667 6.68909 1.66667 6.98102V13.5C1.66667 14.9001 1.66667 15.6002 1.93915 16.135C2.17883 16.6054 2.56129 16.9878 3.03169 17.2275C3.56647 17.5 4.26654 17.5 5.66667 17.5H14.3333C15.7335 17.5 16.4335 17.5 16.9683 17.2275C17.4387 16.9878 17.8212 16.6054 18.0608 16.135C18.3333 15.6002 18.3333 14.9001 18.3333 13.5V6.98102C18.3333 6.68909 18.3333 6.54312 18.3212 6.42018C18.2037 5.23439 17.2656 4.29633 16.0798 4.17885C15.9569 4.16667 15.803 4.16667 15.4953 4.16667C15.3768 4.16667 15.3175 4.16667 15.2672 4.16362C14.6245 4.1247 14.0617 3.71906 13.8215 3.12167C13.8027 3.07488 13.7852 3.02214 13.75 2.91667C13.7148 2.81119 13.6973 2.75845 13.6785 2.71167C13.4383 2.11427 12.8755 1.70864 12.2328 1.66971C12.1825 1.66667 12.1269 1.66667 12.0157 1.66667ZM13.3333 10.4167C13.3333 12.2576 11.8409 13.75 10 13.75C8.15905 13.75 6.66667 12.2576 6.66667 10.4167C6.66667 8.57572 8.15905 7.08333 10 7.08333C11.8409 7.08333 13.3333 8.57572 13.3333 10.4167Z');
  static const checkCircle = MqIconData(20,
      'M6.25 10L8.75 12.5L13.75 7.5M18.3333 10C18.3333 14.6024 14.6024 18.3333 10 18.3333C5.39763 18.3333 1.66667 14.6024 1.66667 10C1.66667 5.39763 5.39763 1.66667 10 1.66667C14.6024 1.66667 18.3333 5.39763 18.3333 10Z');
  static const chevronRight = MqIconData(20, 'M7.5 15L12.5 10L7.5 5');
  static const clock = MqIconData(20,
      'M10 5V10L13.3333 11.6667M18.3333 10C18.3333 14.6024 14.6024 18.3333 10 18.3333C5.39763 18.3333 1.66667 14.6024 1.66667 10C1.66667 5.39763 5.39763 1.66667 10 1.66667C14.6024 1.66667 18.3333 5.39763 18.3333 10Z');
  static const file = MqIconData(20,
      'M11.6667 1.89128V5.33339C11.6667 5.8001 11.6667 6.03346 11.7575 6.21172C11.8374 6.36852 11.9648 6.496 12.1217 6.5759C12.2999 6.66672 12.5332 6.66672 13 6.66672H13H16.4421M13.3333 10.8333H6.66667M13.3333 14.1667H6.66667M8.33333 7.5H6.66667M11.6667 1.66667H7.33333C5.9332 1.66667 5.23313 1.66667 4.69836 1.93915C4.22795 2.17883 3.8455 2.56128 3.60582 3.03169C3.33333 3.56647 3.33333 4.26653 3.33333 5.66667V14.3333C3.33333 15.7335 3.33333 16.4335 3.60582 16.9683C3.8455 17.4387 4.22795 17.8212 4.69836 18.0608C5.23313 18.3333 5.9332 18.3333 7.33333 18.3333H12.6667C14.0668 18.3333 14.7668 18.3333 15.3017 18.0608C15.7721 17.8212 16.1545 17.4387 16.3942 16.9683C16.6667 16.4335 16.6667 15.7335 16.6667 14.3333V6.66667L11.6667 1.66667Z');
  static const heartRate = MqIconData(24,
      'M15.5 11.5H14.5L13 14.5L11 8.5L9.5 11.5H8.5M11.9932 5.13581C9.9938 2.7984 6.65975 2.16964 4.15469 4.31001C1.64964 6.45038 1.29697 10.029 3.2642 12.5604C4.75009 14.4724 8.97129 18.311 10.948 20.0749C11.3114 20.3991 11.4931 20.5613 11.7058 20.6251C11.8905 20.6805 12.0958 20.6805 12.2805 20.6251C12.4932 20.5613 12.6749 20.3991 13.0383 20.0749C15.015 18.311 19.2362 14.4724 20.7221 12.5604C22.6893 10.029 22.3797 6.42787 19.8316 4.31001C17.2835 2.19216 13.9925 2.7984 11.9932 5.13581Z');
  static const infoCircle = MqIconData(20,
      'M10 13.3333V10M10 6.66667H10.0083M18.3333 10C18.3333 14.6024 14.6024 18.3333 10 18.3333C5.39763 18.3333 1.66667 14.6024 1.66667 10C1.66667 5.39763 5.39763 1.66667 10 1.66667C14.6024 1.66667 18.3333 5.39763 18.3333 10Z');
  static const plus = MqIconData(16, 'M8 3.33333V8M8 8V12.6667M8 8H3.33333M8 8H12.6667');
  static const receipt = MqIconData(20,
      'M16.6667 17.5V6.5C16.6667 5.09987 16.6667 4.3998 16.3942 3.86502C16.1545 3.39462 15.772 3.01217 15.3016 2.77248C14.7669 2.5 14.0668 2.5 12.6667 2.5H7.33333C5.9332 2.5 5.23314 2.5 4.69836 2.77248C4.22795 3.01217 3.8455 3.39462 3.60582 3.86502C3.33333 4.3998 3.33333 5.09987 3.33333 6.5V17.5L5.625 15.8333L7.70833 17.5L10 15.8333L12.2917 17.5L14.375 15.8333L16.6667 17.5Z');
  static const xClose = MqIconData(20, 'M15 5L10 10M10 10L5 15M10 10L5 5M10 10L15 15');
  static const lock = MqIconData(24,
      'M17 11V8C17 5.23858 14.7614 3 12 3C9.23858 3 7 5.23858 7 8V11M8.2 21H15.8C16.9201 21 17.4802 21 17.908 20.782C18.2843 20.5903 18.5903 20.2843 18.782 19.908C19 19.4802 19 18.9201 19 17.8V14.2C19 13.0799 19 12.5198 18.782 12.092C18.5903 11.7157 18.2843 11.4097 17.908 11.218C17.4802 11 16.9201 11 15.8 11H8.2C7.0799 11 6.51984 11 6.09202 11.218C5.71569 11.4097 5.40973 11.7157 5.21799 12.092C5 12.5198 5 13.0799 5 14.2V17.8C5 18.9201 5 19.4802 5.21799 19.908C5.40973 20.2843 5.71569 20.5903 6.09202 20.782C6.51984 21 7.0799 21 8.2 21Z');
}

class MqIcon extends StatelessWidget {
  final MqIconData icon;
  final double size;
  final Color? color;

  const MqIcon(this.icon, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color ?? MqTheme.of(context).textPrimary;
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _MqIconPainter(icon, color)),
    );
  }
}

class _MqIconPainter extends CustomPainter {
  final MqIconData icon;
  final Color color;

  _MqIconPainter(this.icon, this.color);

  static final _paths = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / icon.viewBox;
    canvas.scale(scale);
    canvas.drawPath(
      _paths.putIfAbsent(icon.path, () => parseSvgPath(icon.path)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_MqIconPainter old) => old.icon != icon || old.color != color;
}

final _token = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');

Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _token.allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  double next() => double.parse(tokens[i++]);
  var x = 0.0, y = 0.0;
  var command = 'M';
  while (i < tokens.length) {
    if (RegExp('[A-Za-z]').hasMatch(tokens[i])) command = tokens[i++];
    switch (command) {
      case 'M':
        path.moveTo(x = next(), y = next());
        command = 'L';
      case 'L':
        path.lineTo(x = next(), y = next());
      case 'H':
        path.lineTo(x = next(), y);
      case 'V':
        path.lineTo(x, y = next());
      case 'C':
        path.cubicTo(next(), next(), next(), next(), x = next(), y = next());
      case 'Z':
        path.close();
      default:
        throw FormatException('Unsupported SVG path command $command', d);
    }
  }
  return path;
}
