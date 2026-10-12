# Dispositivos-moviles-5-10-26
<!-- Camila expone: descripcion general y documentacion del proyecto. -->
Repositorio para Dispositivos Móviles 5/10/26

## Pulso: evaluación de baile

Aplicación Flutter para registrar participantes o grupos con una ficha individual basada en la planilla de evaluación: carrera, turno, título del baile, cuatro criterios de hasta 25 puntos, datos del jurado y firma. El menú incluye inicio, formulario y consultas; desde consultas se puede generar un informe PDF.

Los registros se envían por HTTP a la API PHP en `xampp/pulso_api/` y se guardan en MySQL de XAMPP. La guía de instalación está en [docs/nota_explicativa_base_datos.txt](docs/nota_explicativa_base_datos.txt). El índice de tareas está en [docs/ARCHIVOS_POR_RESPONSABLE.txt](docs/ARCHIVOS_POR_RESPONSABLE.txt).

Los materiales de Camila quedaron agrupados en [su carpeta de entregables](camila/README.md): informe, guion, esquema de diapositivas y lista de capturas.

### División para exponer

1. Abraham Espinoza Vargas: Aplicación Flutter, parte gráfica, logo y menú, conexión a la base de datos y generación del PDF.
2. Josue Ramos: Base de datos, normalización, diagrama E-R, modelo relacional, consultas y vistas.
3. Camila: Documentación y presentación, informe escrito, capturas y armado de la presentación.

### Ejecutar

Requiere Flutter, Git disponible en `PATH` y un emulador Android o teléfono con depuración USB activada.

```powershell
flutter pub get
flutter run
```

Para ver la aplicación en la web:

```powershell
flutter run -d chrome
```

### Modelo de datos

El diagrama entidad-relación, modelo relacional, normalización y consultas SQL sobre vistas están en [docs/modelo_datos.md](docs/modelo_datos.md).
