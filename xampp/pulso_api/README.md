# API Pulso para XAMPP

Josue Ramos expone esta parte: endpoints PHP/PDO, validacion y consultas MySQL.

La carpeta debe estar publicada como `C:\xampp\htdocs\pulso_api`. En el equipo
de desarrollo esa ruta apunta a esta carpeta del proyecto.

## Preparar la base

Inicia Apache y MySQL en XAMPP. Si la base aun no existe, importa
`docs/xampp_pulso_dance.sql` desde phpMyAdmin. La configuracion local espera
MySQL en `127.0.0.1`, base `pulso_dance`, usuario `root` y contraseña vacía,
que son los valores habituales de XAMPP. Se pueden cambiar mediante las
variables `PULSO_DB_HOST`, `PULSO_DB_NAME`, `PULSO_DB_USER` y
`PULSO_DB_PASSWORD` del entorno de Apache.

Prueba `http://localhost/pulso_api/catalogs.php`; una respuesta correcta empieza
con `{"success":true,...}`.

## Endpoints

- `GET catalogs.php`: catálogos para el formulario.
- `GET dashboard.php`: totales y promedio general.
- `GET reports.php`: evaluaciones y promedios por criterio.
- `POST evaluations.php`: valida y registra una evaluación en una transacción.

Flutter Web usa `http://localhost/pulso_api` por defecto. Para Android Emulator,
inicia Flutter con `--dart-define=PULSO_API_URL=http://10.0.2.2/pulso_api`.
CORS está limitado a orígenes locales de desarrollo. No uses la configuración
predeterminada ni las credenciales locales para publicar el API en Internet.