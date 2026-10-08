# Dispositivos-moviles-5-10-26
Repositorio para Dispositivos Móviles 5/10/26

## Pulso: evaluación de baile

Aplicación Flutter para registrar participantes o grupos con una ficha individual basada en la planilla de evaluación: carrera, turno, título del baile, cuatro criterios de hasta 25 puntos, datos del jurado y firma. El menú incluye inicio, formulario y consultas; desde consultas se puede generar un informe PDF.

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
