import 'package:flutter/material.dart';

import '../resource/theme/colors.dart';

enum AppSection {
  dashboard,
  empresas,
  categorias,
  impuestos,
  productos,
  clientes,
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
  });

  final AppSection section;
  final String title;
  final String icon;
  final String description;
  final Color color;
}

const List<AppSectionItem> appSections = [
  AppSectionItem(
    section: AppSection.dashboard,
    title: 'Inicio',
    icon: 'assets/icons/menu_dashboard.svg',
    description: 'Resumen y accesos rapidos.',
    color: AppColors.primary,
  ),
  AppSectionItem(
    section: AppSection.empresas,
    title: 'Empresas',
    icon: 'assets/icons/menu_store.svg',
    description: 'Alta de empresas y firma digital.',
    color: Color(0xFF26E5FF),
  ),
  AppSectionItem(
    section: AppSection.categorias,
    title: 'Categorias',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Clasificacion de productos.',
    color: Color(0xFFFFA113),
  ),
  AppSectionItem(
    section: AppSection.impuestos,
    title: 'Impuestos',
    icon: 'assets/icons/menu_tran.svg',
    description: 'Reglas de impuestos e IVA.',
    color: Color(0xFFA4CDFF),
  ),
  AppSectionItem(
    section: AppSection.productos,
    title: 'Productos',
    icon: 'assets/icons/menu_task.svg',
    description: 'Catalogo de productos.',
    color: Color(0xFF4F9CFB),
  ),
  AppSectionItem(
    section: AppSection.clientes,
    title: 'Clientes',
    icon: 'assets/icons/menu_profile.svg',
    description: 'Registro de clientes.',
    color: Color(0xFF6FCF97),
  ),
  AppSectionItem(
    section: AppSection.inventarios,
    title: 'Inventarios',
    icon: 'assets/icons/menu_tran.svg',
    description: 'Control de stock.',
    color: Color(0xFFFFC542),
  ),
  AppSectionItem(
    section: AppSection.bodegas,
    title: 'Bodegas',
    icon: 'assets/icons/menu_store.svg',
    description: 'Gestion de bodegas.',
    color: Color(0xFF2F80ED),
  ),
  AppSectionItem(
    section: AppSection.preordenes,
    title: 'Preordenes',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Reservas y preordenes.',
    color: Color(0xFF3F8CFF),
  ),
  AppSectionItem(
    section: AppSection.facturacion,
    title: 'Facturacion',
    icon: 'assets/icons/menu_task.svg',
    description: 'Emision y estados.',
    color: Color(0xFFEE2727),
  ),
  AppSectionItem(
    section: AppSection.usuarios,
    title: 'Usuarios',
    icon: 'assets/icons/menu_setting.svg',
    description: 'Control de usuarios y roles.',
    color: Color(0xFF7B61FF),
  ),
  AppSectionItem(
    section: AppSection.roles,
    title: 'Roles y acciones',
    icon: 'assets/icons/menu_doc.svg',
    description: 'Permisos y acciones del sistema.',
    color: Color(0xFF8E44AD),
  ),
];
