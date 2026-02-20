import 'package:flutter/material.dart';

import '../domain/models/menu_accion.dart';

import '../resource/theme/colors.dart';

enum AppSection {
  dashboard,
  empresas,
  categorias,
  impuestos,
  productos,
  clientes,
  proveedores,
  inventarios,
  bodegas,
  preordenes,
  facturacion,
  usuarios,
  roles,
}

class AppSectionItem {
  const AppSectionItem({
    required this.section,
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.codigo,
    required this.tipo,
  });

  final AppSection section;
  final String title;
  final String icon;
  final String description;
  final Color color;
  final String codigo;
  final String tipo;

  bool matchesAccion(MenuAccion accion) {
    final codigoKey = _normalizeKey(codigo);
    if (codigoKey.isEmpty) {
      return false;
    }
    final urlKey = _normalizeKey(accion.url);
    return urlKey.isNotEmpty && urlKey == codigoKey;
  }
}

String _normalizeKey(String value) {
  final lower = value.trim().toLowerCase();
  return lower
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}

AppSectionItem? resolveSectionForAccion(MenuAccion accion) {
  for (final item in appSections) {
    if (item.matchesAccion(accion)) {
      return item;
    }
  }
  return null;
}

List<AppSectionItem> resolveSectionsFromAcciones(List<MenuAccion> acciones) {
  final resolved = <AppSectionItem>[];
  final seen = <AppSection>{};
  for (final accion in acciones) {
    final match = resolveSectionForAccion(accion);
    if (match != null && !seen.contains(match.section)) {
      seen.add(match.section);
      resolved.add(match);
    }
  }
  return resolved;
}

const List<AppSectionItem> appSections = [
  AppSectionItem(
    section: AppSection.dashboard,
    title: 'Inicio',
    icon: 'assets/icons/menu_dashboard.svg',
    description: 'Resumen y accesos rapidos.',
    color: AppColors.primary,
    codigo: 'dashboard',
    tipo: 'General',
  ),
  AppSectionItem(
    section: AppSection.empresas,
    title: 'Empresas',
    icon: 'assets/icons/menu_store.svg',
    description: 'Alta de empresas y firma digital.',
    color: Color(0xFF26E5FF),
    codigo: 'empresas',
    tipo: 'Administracion',
  ),
  AppSectionItem(
    section: AppSection.categorias,
    title: 'Categorias',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Clasificacion de productos.',
    color: Color(0xFFFFA113),
    codigo: 'categorias',
    tipo: 'Catalogos',
  ),
  AppSectionItem(
    section: AppSection.impuestos,
    title: 'Impuestos',
    icon: 'assets/icons/menu_tran.svg',
    description: 'Reglas de impuestos e IVA.',
    color: Color(0xFFA4CDFF),
    codigo: 'impuestos',
    tipo: 'Operaciones',
  ),
  AppSectionItem(
    section: AppSection.productos,
    title: 'Productos',
    icon: 'assets/icons/menu_task.svg',
    description: 'Catalogo de productos.',
    color: Color(0xFF4F9CFB),
    codigo: 'productos',
    tipo: 'Catalogos',
  ),
  AppSectionItem(
    section: AppSection.clientes,
    title: 'Clientes',
    icon: 'assets/icons/menu_profile.svg',
    description: 'Registro de clientes.',
    color: Color(0xFF6FCF97),
    codigo: 'clientes',
    tipo: 'Catalogos',
  ),
  AppSectionItem(
    section: AppSection.proveedores,
    title: 'Proveedores',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Gestion de proveedores.',
    color: Color(0xFF4F9CFB),
    codigo: 'proveedores',
    tipo: 'Catalogos',
  ),
  AppSectionItem(
    section: AppSection.inventarios,
    title: 'Inventarios',
    icon: 'assets/icons/menu_tran.svg',
    description: 'Control de stock.',
    color: Color(0xFFFFC542),
    codigo: 'inventarios',
    tipo: 'Operaciones',
  ),
  AppSectionItem(
    section: AppSection.bodegas,
    title: 'Bodegas',
    icon: 'assets/icons/menu_store.svg',
    description: 'Gestion de bodegas.',
    color: Color(0xFF2F80ED),
    codigo: 'bodegas',
    tipo: 'Operaciones',
  ),
  AppSectionItem(
    section: AppSection.preordenes,
    title: 'Preordenes',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Reservas y preordenes.',
    color: Color(0xFF3F8CFF),
    codigo: 'preordenes',
    tipo: 'Operaciones',
  ),
  AppSectionItem(
    section: AppSection.facturacion,
    title: 'Facturacion',
    icon: 'assets/icons/menu_task.svg',
    description: 'Emision y estados.',
    color: Color(0xFFEE2727),
    codigo: 'facturacion',
    tipo: 'Operaciones',
  ),
  AppSectionItem(
    section: AppSection.usuarios,
    title: 'Usuarios',
    icon: 'assets/icons/menu_setting.svg',
    description: 'Control de usuarios y roles.',
    color: Color(0xFF7B61FF),
    codigo: 'usuarios',
    tipo: 'Administracion',
  ),
  AppSectionItem(
    section: AppSection.roles,
    title: 'Roles y acciones',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Permisos y acciones del sistema.',
    color: Color(0xFF8E44AD),
    codigo: 'roles',
    tipo: 'Administracion',
  ),
];
