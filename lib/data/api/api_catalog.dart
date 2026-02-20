import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../domain/models/api_models.dart';
import '../../resource/theme/colors.dart';

final List<ApiModule> apiModules = [
  ApiModule(
    title: "Salud",
    description: "Verifica disponibilidad del backend.",
    icon: "assets/icons/menu_dashboard.svg",
    color: AppColors.primary,
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/ping",
        title: "Ping",
        description: "Respuesta rápida para validar conectividad.",
        actionLabel: "Probar",
      ),
    ],
  ),
  ApiModule(
    title: "Dashboard",
    description: "Resumen y metricas del negocio.",
    icon: "assets/icons/menu_dashboard.svg",
    color: Color(0xFF2F80ED),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/dashboard/resumen",
        title: "Resumen dashboard",
        description: "Resumen general (usa empresa del usuario).",
        actionLabel: "Consultar",
      ),
    ],
  ),
  ApiModule(
    title: "Catalogos",
    description: "Gestion de productos, clientes y categorias.",
    icon: "assets/icons/menu_doc.svg",
    color: Color(0xFFFFA113),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/productos",
        title: "Crear producto",
        description: "Registra un nuevo producto.",
        actionLabel: "Crear",
        payload: '''
{
  "codigo": "P-001",
  "descripcion": "Arroz 1kg",
  "precioUnitario": 1.50,
  "categoriaId": 1,
  "impuestoId": 1
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/productos",
        title: "Listar productos",
        description: "Obtiene todos los productos.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/clientes",
        title: "Crear cliente",
        description: "Registra un nuevo cliente.",
        actionLabel: "Crear",
        payload: '''
{
  "tipoIdentificacion": "05",
  "identificacion": "0923456789",
  "razonSocial": "Juan Perez",
  "email": "juan@example.com",
  "direccion": "Av. Siempre Viva 123",
  "creditoDias": 30
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/clientes",
        title: "Listar clientes",
        description: "Obtiene todos los clientes.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/categorias",
        title: "Crear categoria",
        description: "Registra una nueva categoria.",
        actionLabel: "Crear",
        payload: '''
{
  "nombre": "Alimentos",
  "descripcion": "Productos de consumo masivo"
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/categorias",
        title: "Listar categorias",
        description: "Obtiene todas las categorias.",
        actionLabel: "Listar",
      ),
    ],
  ),
  ApiModule(
    title: "Empresas",
    description: "Alta de empresas y firma digital.",
    icon: "assets/icons/menu_store.svg",
    color: Color(0xFF26E5FF),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/empresas",
        title: "Crear empresa",
        description: "Registra una nueva empresa.",
        actionLabel: "Crear",
        payload: '''
{
  "ambiente": "PRUEBAS",
  "tipoEmision": "NORMAL",
  "razonSocial": "Mi Empresa S.A.",
  "nombreComercial": "Mi Empresa",
  "ruc": "9999999999999",
  "dirMatriz": "Av. Principal 100",
  "estab": "001",
  "ptoEmi": "002",
  "secuencial": "000000123",
  "creditoDiasDefault": 30
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/empresas",
        title: "Listar empresas",
        description: "Obtiene el listado de empresas.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/empresas/{empresaId}/firma",
        title: "Subir firma",
        description: "Adjunta la firma digital de la empresa.",
        actionLabel: "Adjuntar",
        contentType: "multipart/form-data",
        payload: '''
archivo: (file) firma.p12
clave: "1234"
''',
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/empresas/{empresaId}/logo",
        title: "Subir logo",
        description: "Adjunta el logo de la empresa.",
        actionLabel: "Adjuntar",
        contentType: "multipart/form-data",
        payload: '''
archivo: (file) logo.png
''',
      ),
    ],
  ),
  ApiModule(
    title: "Operaciones",
    description: "Preórdenes, inventarios e impuestos.",
    icon: "assets/icons/menu_tran.svg",
    color: Color(0xFFA4CDFF),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/preordenes",
        title: "Crear preorden",
        description: "Registra una preorden.",
        actionLabel: "Crear",
        payload: '''
{
  "empresaId": 1,
  "clienteId": 1,
  "dirEstablecimiento": "Sucursal Centro",
  "moneda": "USD",
  "observaciones": "Preorden de prueba",
  "reservaInventario": true,
  "items": [
    { "productoId": 10, "cantidad": 2, "descuento": 0 }
  ]
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/preordenes",
        title: "Listar preordenes",
        description: "Consulta las preordenes.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/inventarios",
        title: "Actualizar inventario",
        description: "Carga o ajusta inventario.",
        actionLabel: "Actualizar",
        payload: '''
{
  "productoId": 10,
  "stockActual": 100,
  "stockMinimo": 5,
  "stockMaximo": 200,
  "ubicacion": "Bodega A1",
  "costoPromedio": 1.25
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/inventarios",
        title: "Listar inventarios",
        description: "Consulta inventarios disponibles.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/impuestos",
        title: "Crear impuesto",
        description: "Registra una regla de impuesto.",
        actionLabel: "Crear",
        payload: '''
{
  "codigo": "2",
  "codigoPorcentaje": "2",
  "tarifa": 12.00,
  "descripcion": "IVA 12%",
  "activo": true
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/impuestos",
        title: "Listar impuestos",
        description: "Obtiene reglas de impuestos.",
        actionLabel: "Listar",
      ),
    ],
  ),
  ApiModule(
    title: "Facturacion",
    description: "Gestion de facturas y estados.",
    icon: "assets/icons/menu_task.svg",
    color: Color(0xFFEE2727),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/facturas",
        title: "Crear factura",
        description: "Genera una nueva factura.",
        actionLabel: "Crear",
        payload: '''
{
  "empresaId": 1,
  "clienteId": 1,
  "preordenId": 5,
  "dirEstablecimiento": "Sucursal Centro",
  "fechaEmision": "2024-01-10",
  "moneda": "USD",
  "codigoNumerico": "12345678",
  "items": [
    { "productoId": 10, "cantidad": 2, "descuento": 0 }
  ]
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/facturas/{numeroFactura}/estado",
        title: "Estado de factura",
        description: "Consulta el estado de una factura.",
        actionLabel: "Consultar",
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/facturas/{facturaId}/pdf",
        title: "PDF de factura",
        description: "Descarga el PDF de una factura.",
        actionLabel: "Descargar",
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/facturas/{facturaId}/xml",
        title: "XML de factura",
        description: "Descarga el XML de una factura.",
        actionLabel: "Descargar",
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/facturas/empresa/{empresaId}/en-proceso",
        title: "Facturas en proceso",
        description: "Lista facturas en proceso por empresa.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/facturas/empresa/{empresaId}/en-proceso/reenviar",
        title: "Reenviar facturas",
        description: "Reintenta envio de facturas en proceso.",
        actionLabel: "Reenviar",
      ),
    ],
  ),
  ApiModule(
    title: "CxC",
    description: "Cuentas por cobrar y cobros de clientes.",
    icon: "assets/icons/menu_doc.svg",
    color: Color(0xFF2F80ED),
    endpoints: const [
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/documentos-cliente",
        title: "Listar documentos cliente",
        description: "Obtiene documentos (opcional filtro por cliente).",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/clientes/{clienteId}/documentos",
        title: "Documentos por cliente",
        description: "Lista documentos filtrados por cliente.",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.patch,
        path: "/api/documentos-cliente/{documentoId}/estado",
        title: "Anular documento",
        description: "Actualiza estado de DocumentoCliente.",
        actionLabel: "Actualizar",
        payload: '''
{
  "estado": "ANULADA",
  "motivo": "Error de emision"
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/cxc",
        title: "Listar cuentas por cobrar",
        description: "Obtiene CxC (opcional filtro por cliente).",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.post,
        path: "/api/cobros-cliente",
        title: "Registrar cobro",
        description: "Registra un cobro aplicable a varias CxC.",
        actionLabel: "Registrar",
        payload: '''
{
  "clienteId": 10,
  "fecha": "2026-02-20",
  "formaPago": "TRANSFERENCIA",
  "referencia": "TRX-8899",
  "montoTotal": 150.00,
  "observacion": "Pago parcial",
  "detalles": [
    { "cuentaPorCobrarId": 1, "montoAplicado": 100.00 },
    { "cuentaPorCobrarId": 2, "montoAplicado": 50.00 }
  ]
}
''',
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/cobros-cliente",
        title: "Listar cobros cliente",
        description: "Obtiene cobros (opcional filtro por cliente).",
        actionLabel: "Listar",
      ),
      ApiEndpoint(
        method: ApiMethod.get,
        path: "/api/reportes/cxc/aging",
        title: "Reporte aging CxC",
        description: "Resumen de vencidas y por vencer.",
        actionLabel: "Listar",
      ),
    ],
  ),
];

List<ApiEndpoint> get apiEndpoints =>
    apiModules.expand((module) => module.endpoints).toList();

int get apiEndpointCount => apiEndpoints.length;

String get apiBaseUrl => ApiConfig.baseUrl;
