# Informe del proyecto Pulso

**Responsable:** Camila  
**Integrantes:** Abraham Espinoza Vargas, Josue Ramos y Camila

## Introducción

Pulso es una aplicación para registrar y consultar evaluaciones de baile. La
ficha guarda el participante o grupo, carrera, turno, título del baile, datos
del jurado, firma y observaciones. Cada presentación recibe una nota en cuatro
criterios: técnica, expresión y arte, coreografía, y vestuario y puesta en
escena. Cada criterio tiene un máximo de 25 puntos y el total es de 100.

## Objetivo

Digitalizar el registro de las evaluaciones, almacenar las notas de forma
organizada y facilitar la consulta y generación de reportes en PDF.

## Aplicación

La aplicación se desarrolló en Flutter. Tiene una pantalla de inicio, un
formulario de evaluación y una sección de consultas. El formulario valida las
notas y calcula el total. Flutter se comunica por HTTP con una API escrita en
PHP; la API valida los datos y los guarda en MySQL de XAMPP. La sección de
consultas presenta los resultados y permite generar un PDF.

## Base de datos

El modelo contiene seis tablas principales:

- `dancers`: participante o grupo, carrera y turno.
- `evaluators`: nombre y cargo del jurado.
- `dance_styles`: título o estilo del baile.
- `criteria`: criterios activos de evaluación.
- `evaluations`: fecha, participante, jurado, baile, firma y observaciones.
- `scores`: nota de cada criterio para una evaluación.

Las claves foráneas relacionan las evaluaciones con participantes, jurados y
estilos. `scores` usa la clave primaria compuesta `(evaluation_id,
criterion_id)`, evitando guardar dos veces el mismo criterio para una
evaluación. La base restringe las notas al intervalo de 0 a 25.

## Normalización

- **Primera forma normal:** cada campo almacena un solo valor y las notas se
  separan en registros de `scores`.
- **Segunda forma normal:** la nota depende de la clave completa formada por
  evaluación y criterio.
- **Tercera forma normal:** los datos de participantes, jurados y criterios
  viven en sus tablas, evitando repetirlos en cada evaluación.

## Consultas y vistas

`v_evaluation_summary` presenta una fila por evaluación con participante,
carrera, turno, baile, jurado, fecha y promedio. `v_criterion_performance`
calcula el número de notas y el promedio por criterio. Estas vistas alimentan
el resumen de inicio, las consultas y los reportes.

## Conclusión

Pulso convierte la ficha de evaluación en un flujo digital: captura datos,
valida las notas, los guarda en MySQL por medio de PHP y permite revisar los
resultados en la aplicación. Para conectarse a la base local, Apache y MySQL de
XAMPP deben estar activos.