import 'dart:ui';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/rpg_game.dart';
import 'package:bonfire/util/collision/collision.dart';
import 'package:flutter/material.dart';

mixin ObjectCollision {
  Collision collision = Collision();

  void triggerSensors(Rect displacement, RPGGame game) {
    Rect rectCollision = getRectCollision(displacement);

    final sensors = game.visibleDecorations().where(
          (decoration) => decoration.isSensor,
        );

    sensors.forEach((decoration) {
      if (decoration.rectCollision.overlaps(rectCollision))
        decoration.onContact(this);
    });
  }

  bool isCollision(
    Rect displacement,
    RPGGame game, {
    bool onlyVisible = true,
    bool shouldTriggerSensors = true,
  }) {
    Rect rectCollision = getRectCollision(displacement);
    if (shouldTriggerSensors) triggerSensors(displacement, game);

    final collisions = (onlyVisible
            ? game.map.getCollisionsRendered()
            : game.map.getCollisions())
        .where((i) => i.position.overlaps(rectCollision));

    if (collisions.length > 0) return true;

    final collisionsDecorations =
        (onlyVisible ? game.visibleDecorations() : game.decorations()).where(
            (i) =>
                !i.isSensor &&
                i.collision != null &&
                i.rectCollision.overlaps(rectCollision));

    if (collisionsDecorations.length > 0) return true;

    return false;
  }

  bool isCollisionTranslate(
      Rect position, double translateX, double translateY, RPGGame game,
      {bool onlyVisible = true}) {
    var moveToCurrent = position.translate(translateX, translateY);
    return isCollision(moveToCurrent, game, onlyVisible: onlyVisible);
  }

  Rect getRectCollision(Rect displacement) {
    double left =
        displacement.left + (displacement.width - collision.width) / 2;

    double top =
        displacement.top + (displacement.height - collision.height) / 2;

    switch (collision.align) {
      case CollisionAlign.BOTTOM_CENTER:
        top = displacement.bottom - collision.height;
        break;
      case CollisionAlign.CENTER:
        top = displacement.top + (displacement.height - collision.height) / 2;
        break;
      case CollisionAlign.TOP_CENTER:
        top = displacement.top;
        break;
      case CollisionAlign.LEFT_CENTER:
        left = displacement.left;
        break;
      case CollisionAlign.RIGHT_CENTER:
        left = displacement.right - collision.width;
        break;
      case CollisionAlign.TOP_LEFT:
        top = displacement.top;
        left = displacement.left;
        break;
      case CollisionAlign.TOP_RIGHT:
        top = displacement.top;
        left = displacement.right - collision.width;
        break;
      case CollisionAlign.BOTTOM_LEFT:
        top = displacement.bottom - collision.height;
        left = displacement.left;
        break;
      case CollisionAlign.BOTTOM_RIGHT:
        top = displacement.bottom - collision.height;
        left = displacement.right - collision.width;
        break;
    }
    return Rect.fromLTWH(left, top, collision.width, collision.height);
  }

  void drawCollision(Canvas canvas, Rect currentPosition, Color color) {
    if (collision == null) return;
    canvas.drawRect(
      getRectCollision(currentPosition),
      new Paint()..color = color ?? Colors.lightGreenAccent.withOpacity(0.5),
    );
  }
}
