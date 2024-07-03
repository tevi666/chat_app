import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String getInitials(String name) {
  List<String> nameParts = name.split(' ');
  if (nameParts.length > 1) {
    return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
  } else {
    return nameParts[0][0].toUpperCase();
  }
}

Color getColorFromString(String input, List<Color> colors) {
  final hash = input.codeUnits.fold(0, (prev, element) => prev + element);
  return colors[hash % colors.length];
}

String getMessageTime(DateTime messageTime) {
  var now = DateTime.now();
  var difference = now.difference(messageTime).inMinutes;

  if (difference < 1) {
    return 'Только что';
  } else if (difference < 5) {
    return '$difference минут назад';
  } else if (messageTime.year == now.year &&
      messageTime.month == now.month &&
      messageTime.day == now.day - 1) {
    return 'Вчера';
  } else if (messageTime.isBefore(DateTime(now.year, now.month, now.day))) {
    return DateFormat.yMd().format(messageTime);
  } else {
    return DateFormat.Hm().format(messageTime);
  }
}
