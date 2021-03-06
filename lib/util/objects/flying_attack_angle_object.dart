import 'dart:math';

import 'package:bonfire/util/collision/collision.dart';
import 'package:bonfire/util/collision/object_collision.dart';
import 'package:bonfire/util/interval_tick.dart';
import 'package:bonfire/util/lighting/lighting_config.dart';
import 'package:bonfire/util/lighting/with_lighting.dart';
import 'package:bonfire/util/objects/animated_object.dart';
import 'package:bonfire/util/objects/animated_object_once.dart';
import 'package:flame/animation.dart' as FlameAnimation;
import 'package:flame/position.dart';
import 'package:flutter/widgets.dart';

class FlyingAttackAngleObject extends AnimatedObject
    with ObjectCollision, WithLighting {
  final int id;
  final FlameAnimation.Animation flyAnimation;
  final FlameAnimation.Animation destroyAnimation;
  final double radAngle;
  final double speed;
  final double damage;
  final double width;
  final double height;
  final Position initPosition;
  final bool damageInPlayer;
  final bool damageInEnemy;
  final bool withCollision;
  final VoidCallback destroyedObject;
  final LightingConfig lightingConfig;

  double _cosAngle;
  double _senAngle;
  double _rotate;

  final IntervalTick _timerVerifyCollision = IntervalTick(40);

  FlyingAttackAngleObject({
    @required this.initPosition,
    @required this.flyAnimation,
    @required this.radAngle,
    @required this.width,
    @required this.height,
    this.id,
    this.destroyAnimation,
    this.speed = 150,
    this.damage = 1,
    this.damageInPlayer = true,
    this.damageInEnemy = true,
    this.withCollision = true,
    this.destroyedObject,
    this.lightingConfig,
    Collision collision,
  }) {
    if (lightingConfig != null) lightingConfig.gameComponent = this;
    animation = flyAnimation;
    position = Rect.fromLTWH(
      initPosition.x,
      initPosition.y,
      width,
      height,
    );

    this.collision = collision ?? Collision(width: width, height: height / 2);
    _cosAngle = cos(radAngle);
    _senAngle = sin(radAngle);
    _rotate = radAngle == 0.0 ? 0.0 : radAngle + (pi / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    double nextX = (speed * dt) * _cosAngle;
    double nextY = (speed * dt) * _senAngle;
    Offset nextPoint = Offset(nextX, nextY);

    Offset diffBase = Offset(position.center.dx + nextPoint.dx,
            position.center.dy + nextPoint.dy) -
        position.center;

    position = position.shift(diffBase);

    if (!_verifyExistInWorld()) {
      remove();
    } else {
      _verifyCollision(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (this.isVisibleInMap()) {
      canvas.save();
      canvas.translate(position.center.dx, position.center.dy);
      canvas.rotate(_rotate);
      canvas.translate(-position.center.dx, -position.center.dy);
      super.render(canvas);
      if (gameRef != null && gameRef.showCollisionArea) {
        drawCollision(canvas, position, gameRef.collisionAreaColor);
      }
      canvas.restore();
    }
  }

  void _verifyCollision(double dt) {
    if (!_timerVerifyCollision.update(dt)) return;

    bool destroy = false;

    if (withCollision)
      destroy = isCollision(position, gameRef, onlyVisible: false);

    if (damageInPlayer) {
      if (position.overlaps(gameRef.player.rectCollision)) {
        gameRef.player.receiveDamage(damage, id);
        destroy = true;
      }
    }

    if (damageInEnemy) {
      gameRef
          .livingEnemies()
          .where((enemy) => enemy.rectCollision.overlaps(position))
          .forEach((enemy) {
        enemy.receiveDamage(damage, id);
        destroy = true;
      });
    }

    if (destroy) {
      if (destroyAnimation != null) {
        double nextX = (width / 2) * _cosAngle;
        double nextY = (height / 2) * _senAngle;
        Offset nextPoint = Offset(nextX, nextY);

        Offset diffBase = Offset(position.center.dx + nextPoint.dx,
                position.center.dy + nextPoint.dy) -
            position.center;

        Rect positionDestroy = position.shift(diffBase);

        gameRef.add(
          AnimatedObjectOnce(
            animation: destroyAnimation,
            position: positionDestroy,
            lightingConfig: lightingConfig,
          ),
        );
      }
      remove();
      if (this.destroyedObject != null) this.destroyedObject();
    }
  }

  bool _verifyExistInWorld() {
    bool result = true;
    Size mapSize = gameRef.map.mapSize;
    if (position.left < gameRef.gameCamera.position.x) {
      result = false;
    }
    if (position.right > gameRef.gameCamera.position.x + mapSize.width) {
      result = false;
    }
    if (position.top < gameRef.gameCamera.position.y) {
      result = false;
    }
    if (position.bottom > gameRef.gameCamera.position.y + mapSize.height) {
      result = false;
    }
    return result;
  }
}
