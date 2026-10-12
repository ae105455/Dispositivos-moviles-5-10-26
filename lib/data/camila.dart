// ignore_for_file: avoid_print

class CamilaPresentationData {
  const CamilaPresentationData._();

  static const slides = <PresentationSlide>[
    PresentationSlide(
      number: 1,
      title: 'Pulso: evaluacion de baile',
      responsible: 'Camila',
      points: [
        'Aplicacion para registrar y consultar evaluaciones de baile.',
        'Integrantes: Abraham Espinoza Vargas, Josue Ramos y Camila.',
      ],
      speakerNotes:
          'Buenos dias. Presentamos Pulso, una aplicacion para registrar y consultar evaluaciones de baile.',
    ),
    PresentationSlide(
      number: 2,
      title: 'Problema y objetivo',
      responsible: 'Camila',
      points: [
        'Digitalizar el registro de participantes y calificaciones.',
        'Facilitar el almacenamiento y la consulta de resultados.',
      ],
      speakerNotes:
          'El objetivo es reemplazar el registro manual por un flujo digital que permita guardar y consultar las evaluaciones.',
    ),
    PresentationSlide(
      number: 3,
      title: 'Aplicacion Flutter',
      responsible: 'Abraham Espinoza Vargas',
      points: [
        'Menu, formulario de evaluacion y consultas.',
        'Validacion de cuatro criterios y calculo del total sobre 100.',
        'Conexion HTTP con la API y generacion de PDF.',
      ],
      speakerNotes:
          'Abraham desarrollo la aplicacion Flutter. En esta parte mostraremos el menu, el formulario, el calculo del total y los reportes PDF.',
    ),
    PresentationSlide(
      number: 4,
      title: 'Base de datos',
      responsible: 'Josue Ramos',
      points: [
        'Tablas para participantes, jurados, bailes, criterios y evaluaciones.',
        'Relaciones mediante claves primarias y foraneas.',
        'Notas restringidas al intervalo de 0 a 25.',
      ],
      speakerNotes:
          'Josue preparo la base de datos. Las tablas separan la informacion y sus relaciones ayudan a mantener los datos organizados.',
    ),
    PresentationSlide(
      number: 5,
      title: 'Consultas y vistas',
      responsible: 'Josue Ramos',
      points: [
        'Resumen de evaluaciones.',
        'Promedio y cantidad de notas por criterio.',
      ],
      speakerNotes:
          'Las vistas resumen las evaluaciones y calculan el rendimiento por criterio para mostrarlo en las consultas y reportes.',
    ),
    PresentationSlide(
      number: 6,
      title: 'Resultados y documentacion',
      responsible: 'Camila',
      points: [
        'Informe escrito y capturas del flujo de la aplicacion.',
        'Evidencia del guardado, las consultas y los PDF.',
      ],
      speakerNotes:
          'Mi responsabilidad fue elaborar el informe, reunir las capturas y organizar la presentacion. Flutter captura los datos, PHP los valida y MySQL los almacena.',
    ),
  ];

  static const screenshots = <String>[
    '01_menu_inicio.png',
    '02_formulario.png',
    '03_puntajes_total.png',
    '04_guardado_mysql.png',
    '05_consultas.png',
    '06_pdf_ficha.png',
    '07_pdf_reporte.png',
  ];
}

class PresentationSlide {
  const PresentationSlide({
    required this.number,
    required this.title,
    required this.responsible,
    required this.points,
    required this.speakerNotes,
  });

  final int number;
  final String title;
  final String responsible;
  final List<String> points;
  final String speakerNotes;
}

void main() {
  for (final slide in CamilaPresentationData.slides) {
    print('\nDIAPOSITIVA ${slide.number}: ${slide.title}');
    print('Responsable: ${slide.responsible}');
    for (final point in slide.points) {
      print('- $point');
    }
    print('Guion: ${slide.speakerNotes}');
  }

  print('\nCAPTURAS PENDIENTES:');
  for (final screenshot in CamilaPresentationData.screenshots) {
    print('- $screenshot');
  }
}
