import 'dart:math';

import 'package:bonfire/enemy/extensions.dart';
import 'package:bonfire/enemy/rotation_enemy.dart';
import 'package:bonfire/player/player.dart';
import 'package:bonfire/util/collision/collision.dart';
import 'package:bonfire/util/objects/animated_object_once.dart';
import 'package:bonfire/util/objects/flying_attack_angle_object.dart';
import 'package:flame/animation.dart' as FlameAnimation;
import 'package:flame/position.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

extension RotationEnemyExtensions on RotationEnemy {
  void seeAndMoveToPlayer({
    Function(Player) closePlayer,
    int visionCells = 3,
    double margin = 10,
  }) {
    if (!isVisibleInMap() || isDead || this.position == null) return;
    seePlayer(
      visionCells: visionCells,
      observed: (player) {
        double _radAngle = getAngleFomPlayer();

        Rect rectPlayerCollision = Rect.fromLTWH(
          player.rectCollision.left - margin,
          player.rectCollision.top - margin,
          player.rectCollision.width + (margin * 2),
          player.rectCollision.height + (margin * 2),
        );

        if (this.rectCollision.overlaps(rectPlayerCollision)) {
          if (closePlayer != null) closePlayer(player);
          this.idle();
          this.moveFromAngleDodgeObstacles(0, _radAngle);
          return;
        }

        this.moveFromAngleDodgeObstacles(speed, _radAngle, notMove: () {
          this.idle();
        });
      },
      notObserved: () {
        this.idle();
      },
    );
  }

  void simpleAttackMelee({
    @required FlameAnimation.Animation attackEffectTopAnim,
    @required double damage,
    int id,
    double heightArea = 32,
    double widthArea = 32,
    bool withPush = false,
    VoidCallback execute,
    int interval = 1000,
  }) {
    if (!this.checkPassedInterval('attackMelee', interval)) return;

    Player player = gameRef.player;

    if (player.isDead || !isVisibleInMap() || isDead || this.position == null)
      return;

    double nextX = this.height * cos(this.currentRadAngle);
    double nextY = this.height * sin(this.currentRadAngle);
    Offset nextPoint = Offset(nextX, nextY);

    Offset diffBase = Offset(this.positionInWorld.center.dx + nextPoint.dx,
            this.positionInWorld.center.dy + nextPoint.dy) -
        this.positionInWorld.center;

    Rect positionAttack = this.positionInWorld.shift(diffBase);

    gameRef.add(AnimatedObjectOnce(
      animation: attackEffectTopAnim,
      position: positionAttack,
      rotateRadAngle: this.currentRadAngle,
    ));

    player.receiveDamage(damage, id);

    if (withPush) {
      Rect rectAfterPush = player.position.translate(diffBase.dx, diffBase.dy);
      if (!player.isCollision(rectAfterPush, this.gameRef)) {
        player.position = rectAfterPush;
      }
    }

    if (execute != null) execute();
  }

  void simpleAttackRange({
    @required FlameAnimation.Animation animationTop,
    @required FlameAnimation.Animation animationDestroy,
    @required double width,
    @required double height,
    int id,
    double speed = 150,
    double damage = 1,
    int interval = 1000,
    bool withCollision = true,
    VoidCallback destroy,
    Collision collision,
    VoidCallback execute,
  }) {
    if (!this.checkPassedInterval('attackRange', interval)) return;
    Player player = this.gameRef.player;
    if (isDead || player == null || player.isDead) return;

    double _radAngle = getAngleFomPlayer();

    double nextX = this.height * cos(_radAngle);
    double nextY = this.height * sin(_radAngle);
    Offset nextPoint = Offset(nextX, nextY);

    Offset diffBase = Offset(this.positionInWorld.center.dx + nextPoint.dx,
            this.positionInWorld.center.dy + nextPoint.dy) -
        this.positionInWorld.center;

    Rect position = this.positionInWorld.shift(diffBase);
    gameRef.add(FlyingAttackAngleObject(
      id: id,
      initPosition: Position(position.left, position.top),
      radAngle: _radAngle,
      width: width,
      height: height,
      damage: damage,
      speed: speed,
      damageInPlayer: true,
      collision: collision,
      withCollision: withCollision,
      damageInEnemy: false,
      destroyedObject: destroy,
      flyAnimation: animationTop,
      destroyAnimation: animationDestroy,
    ));

    if (execute != null) execute();
  }
}