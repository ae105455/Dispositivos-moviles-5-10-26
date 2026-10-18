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

### Direccion de XAMPP y codigo QR

En la pantalla Inicio, pulsa **Cambiar IP y ver QR**. La configuración ofrece
tres códigos:

- **XAMPP:** escribe la IPv4 actual de la computadora donde está XAMPP. En la
  red actual es `172.20.10.9`; puede cambiar al cambiar de red.
  El QR se actualiza y la dirección se guarda automáticamente. Al escanearlo,
  abre el API en el navegador.
- **Pulso para iPhone y Android:** compila la versión web y cópiala en XAMPP:
  ejecuta `flutter build web --release --base-href /pulso/`,
  `New-Item -ItemType Directory -Force C:\xampp\htdocs\pulso` y luego
  `Copy-Item .\build\web\* C:\xampp\htdocs\pulso -Recurse -Force`.
  Escanea el QR web desde un teléfono conectado a la misma red. En iPhone,
  abre el enlace con Safari, toca **Compartir > Añadir a pantalla de inicio**.
  La computadora con XAMPP debe permanecer encendida; el acceso web local no
  es una app nativa ni funciona fuera de esa red.
- **Wi-Fi:** escribe el SSID y la contraseña para generar un QR de conexión.
  El código se actualiza al escribir; la contraseña no se guarda ni se envía
  a GitHub.
- **Descargar Pulso:** escanea para descargar el APK desde el último GitHub
  Release. El Release debe incluir el archivo `pulso-dance.apk`; que el
  repositorio sea público no basta si el APK no está adjunto.

Para publicar el APK, crea y sube una etiqueta de versión nueva, por ejemplo
`v1.0.4` (`git tag v1.0.4; git push origin v1.0.4`). GitHub Actions compila la
aplicación Android ARM64 y adjunta `pulso-dance.apk` al Release. El QR de
descarga apunta automáticamente al APK del último Release publicado. El
repositorio y el Release deben ser públicos para que los estudiantes puedan
descargarlo sin iniciar sesión.

### Modelo de datos

El diagrama entidad-relación, modelo relacional, normalización y consultas SQL sobre vistas están en [docs/modelo_datos.md](docs/modelo_datos.md).
