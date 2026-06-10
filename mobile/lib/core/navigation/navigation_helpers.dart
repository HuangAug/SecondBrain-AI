import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void goBackOrHome(BuildContext context, {String fallback = '/home'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
