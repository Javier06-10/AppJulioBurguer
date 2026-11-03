import 'package:flutter/widgets.dart';
import 'package:uicons/uicons.dart';

/// Iconos Flaticon UIcons centralizados para toda la app.
/// Cambiar el estilo aquí (rounded/straight, regular/solid) lo cambia en todas partes.
class AppIcons {
  AppIcons._();

  static final _r = UIcons.regularRounded;
  static final _s = UIcons.solidRounded;

  // Marca / comida
  static IconData get brand => _s.flame;
  static IconData get burger => _r.hamburger;
  static IconData get pizza => _r.pizza_slice;
  static IconData get fries => _r.french_fries;
  static IconData get drink => _r.drink_alt;
  static IconData get chef => _r.hat_chef;

  // Navegación admin
  static IconData get dashboard => _r.apps;
  static IconData get dashboardActive => _s.apps;
  static IconData get orders => _r.receipt;
  static IconData get ordersActive => _s.receipt;
  static IconData get products => _r.hamburger;
  static IconData get productsActive => _s.hamburger;
  static IconData get categories => _r.tags;
  static IconData get categoriesActive => _s.tags;
  static IconData get users => _r.users;
  static IconData get usersActive => _s.users;

  // Métricas
  static IconData get revenue => _r.sack_dollar;
  static IconData get ticket => _r.chart_line_up;
  static IconData get pending => _r.hourglass_end;
  static IconData get delayed => _r.alarm_exclamation;
  static IconData get trophy => _r.trophy;
  static IconData get stock => _r.box_alt;

  // Estados de pedido
  static IconData get statusPending => _r.time_past;
  static IconData get statusPreparing => _r.flame;
  static IconData get statusReady => _r.bell_ring;
  static IconData get statusDelivered => _r.check;
  static IconData get statusCancelled => _r.ban;

  // Acciones
  static IconData get add => _r.plus;
  static IconData get edit => _r.pencil;
  static IconData get delete => _r.trash;
  static IconData get search => _r.search;
  static IconData get close => _r.cross_small;
  static IconData get logout => _r.sign_out_alt;
  static IconData get next => _r.angle_small_right;
  static IconData get back => _r.angle_small_left;
  static IconData get filter => _r.filter;
  static IconData get store => _r.shop;
  static IconData get clock => _r.clock;
  static IconData get note => _r.comment_alt;
  static IconData get user => _r.user;
  static IconData get email => _r.envelope;
  static IconData get location => _r.marker;
  static IconData get shield => _r.shield_check;
  static IconData get lock => _r.lock;
  static IconData get eye => _r.eye;
  static IconData get eyeOff => _r.eye_crossed;
  static IconData get cart => _r.shopping_cart;
  static IconData get money => _r.dollar;
  static IconData get empty => _r.inbox;
}
