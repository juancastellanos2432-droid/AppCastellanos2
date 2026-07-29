import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ISSWeatherApp());
}

//======================================================================
// APP RAÍZ - TEMA OSCURO
//======================================================================

class ISSWeatherApp extends StatelessWidget {
  const ISSWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AppCastellanos - ISS y Clima",
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          indicatorColor: Colors.indigo.withValues(alpha: 0.35),
        ),
      ),
      home: const RootShell(),
    );
  }
}

//======================================================================
// SHELL PRINCIPAL: navegación inferior con 3 páginas independientes
//======================================================================

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  // IndexedStack conserva el estado de cada página al cambiar de pestaña,
  // así no se vuelve a llamar la API cada vez que el usuario navega.
  final List<Widget> _pages = const [
    IssPage(),
    ClimaPage(),
    TurismoPage(),
  ];

  static const List<String> _titles = [
    "Ubicación de la ISS",
    "Clima en Barrancabermeja",
    "Turismo en Colombia",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.satellite_alt_outlined),
            selectedIcon: Icon(Icons.satellite_alt),
            label: "ISS",
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: "Clima",
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: "Turismo",
          ),
        ],
      ),
    );
  }
}

//======================================================================
// WIDGETS REUTILIZABLES
//======================================================================

Widget infoTile(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.indigo.shade900,
          child: Icon(icon, color: Colors.indigo.shade100),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

//======================================================================
// PÁGINA 1: UBICACIÓN DE LA ISS
//======================================================================

class IssPage extends StatefulWidget {
  const IssPage({super.key});

  @override
  State<IssPage> createState() => _IssPageState();
}

class _IssPageState extends State<IssPage> {
  String latitude = "...";
  String longitude = "...";
  String timestamp = "";
  bool loadingISS = false;

  @override
  void initState() {
    super.initState();
    getISSLocation();
  }

  Future<void> getISSLocation() async {
    setState(() {
      loadingISS = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse("https://api.wheretheiss.at/v1/satellites/25544"),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          latitude = (data["latitude"] as num).toStringAsFixed(4);
          longitude = (data["longitude"] as num).toStringAsFixed(4);
          timestamp = DateTime.now().toString().substring(0, 19);
        });
      } else {
        setState(() {
          latitude = "Error (${response.statusCode})";
          longitude = "Error (${response.statusCode})";
        });
      }
    } catch (_) {
      setState(() {
        latitude = "Sin conexión";
        longitude = "Sin conexión";
      });
    }

    setState(() {
      loadingISS = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: getISSLocation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: loadingISS
                ? const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      const Icon(Icons.satellite_alt, size: 90, color: Colors.indigo),
                      const SizedBox(height: 20),
                      infoTile(Icons.location_on, "Latitud", latitude),
                      infoTile(Icons.location_searching, "Longitud", longitude),
                      infoTile(Icons.access_time, "Actualizado", timestamp),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: getISSLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Actualizar ubicación"),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

//======================================================================
// PÁGINA 2: CLIMA EN BARRANCABERMEJA
//======================================================================

class ClimaPage extends StatefulWidget {
  const ClimaPage({super.key});

  @override
  State<ClimaPage> createState() => _ClimaPageState();
}

class _ClimaPageState extends State<ClimaPage> {
  String temperature = "...";
  String pressure = "...";
  String humidity = "...";
  String weather = "...";
  String wind = "...";
  bool loadingWeather = false;

  final String apiKey = "643ebcf0046acf0c33b18cb43be1838d";

  @override
  void initState() {
    super.initState();
    getWeather();
  }

  Future<void> getWeather() async {
    setState(() {
      loadingWeather = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
                "https://api.openweathermap.org/data/2.5/weather?q=Barrancabermeja,CO&appid=$apiKey&units=metric&lang=es"),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          temperature = "${data["main"]["temp"]} °C";
          humidity = "${data["main"]["humidity"]}%";
          pressure = "${data["main"]["pressure"]} hPa";
          weather = data["weather"][0]["description"];
          wind = "${data["wind"]["speed"]} m/s";
        });
      } else {
        setState(() {
          temperature = "Error (${response.statusCode})";
          humidity = pressure = weather = wind = "-";
        });
      }
    } catch (_) {
      setState(() {
        temperature = "Sin conexión";
        humidity = pressure = weather = wind = "-";
      });
    }

    setState(() {
      loadingWeather = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: getWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: loadingWeather
                ? const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      const Icon(Icons.cloud, size: 90, color: Colors.orangeAccent),
                      const SizedBox(height: 20),
                      infoTile(Icons.thermostat, "Temperatura", temperature),
                      infoTile(Icons.water_drop, "Humedad", humidity),
                      infoTile(Icons.speed, "Presión", pressure),
                      infoTile(Icons.air, "Viento", wind),
                      infoTile(Icons.cloud_queue, "Estado", weather),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: getWeather,
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text("Actualizar clima"),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

//======================================================================
// PÁGINA 3: TURISMO EN COLOMBIA
//======================================================================

class TourismSite {
  final String title;
  final String department;
  final String description;
  final String imageUrl;
  final List<String> highlights;

  const TourismSite({
    required this.title,
    required this.department,
    required this.description,
    required this.imageUrl,
    required this.highlights,
  });
}

// Imágenes reales de Wikimedia Commons (licencia libre CC-BY / CC-BY-SA),
// servidas a través de Special:FilePath para obtener siempre el archivo
// original sin depender de un hash de miniatura que pueda cambiar.
const String _wiki = "https://commons.wikimedia.org/wiki/Special:FilePath/";

final List<TourismSite> tourismSites = [
  TourismSite(
    title: "Cartagena de Indias",
    department: "Bolívar",
    imageUrl: "${_wiki}Ciudad_Amurallada_Cartagena.JPG?width=1000",
    description:
        "Ciudad amurallada de la época colonial, Patrimonio de la Humanidad. Sus calles empedradas, balcones floridos y el Castillo de San Felipe de Barajas la convierten en uno de los destinos más visitados del Caribe colombiano.",
    highlights: ["Patrimonio UNESCO", "Playas cercanas", "Ciudad amurallada"],
  ),
  TourismSite(
    title: "Parque Nacional del Chicamocha",
    department: "Santander",
    imageUrl: "${_wiki}Teleferico_sobre_el_Rio_Chicamocha.JPG?width=1000",
    description:
        "Ubicado sobre uno de los cañones más profundos del mundo, cerca de Bucaramanga y San Gil. Su teleférico de más de 6 km cruza el cañón y ofrece deportes de aventura, miradores y una vista impresionante del río Chicamocha.",
    highlights: ["Teleférico 6.3 km", "Deportes extremos", "Cerca de Bucaramanga"],
  ),
  TourismSite(
    title: "Parque Tayrona",
    department: "Magdalena",
    imageUrl: "${_wiki}116_Tayrona_Cabo_San_Juan_Colombia.JPG?width=1000",
    description:
        "Parque natural en la costa Caribe con playas rodeadas de selva y la Sierra Nevada de Santa Marta de fondo. Cabo San Juan es su playa más icónica, con senderos ecológicos y gran biodiversidad marina y terrestre.",
    highlights: ["Cabo San Juan", "Senderismo", "Snorkel"],
  ),
  TourismSite(
    title: "Valle de Cocora",
    department: "Quindío",
    imageUrl: "${_wiki}Paisaje_Valle_del_Cocora.jpg?width=1000",
    description:
        "Hogar de la palma de cera del Quindío, el árbol nacional de Colombia y la palma más alta del mundo. Cerca del pueblo de Salento, en pleno Eje Cafetero declarado Paisaje Cultural Cafetero por la UNESCO.",
    highlights: ["Palma de cera", "Cerca de Salento", "Eje Cafetero"],
  ),
  TourismSite(
    title: "Guatapé y la Piedra del Peñol",
    department: "Antioquia",
    imageUrl:
        "${_wiki}El_Pe%C3%B1ol_de_Guatap%C3%A9_(The_Rock_of_Guatape)_2017-04-10.jpg?width=1000",
    description:
        "El Peñón de Guatapé es un monolito de 220 metros con 740 escalones hasta la cima, desde donde se ve el embalse y sus islas. El pueblo de Guatapé es famoso por los coloridos zócalos que decoran sus fachadas.",
    highlights: ["740 escalones", "Vista al embalse", "Pueblo colorido"],
  ),
  TourismSite(
    title: "Villa de Leyva",
    department: "Boyacá",
    imageUrl: "${_wiki}Plaza_Mayor_Villa_de_Leyva.jpg?width=1000",
    description:
        "Uno de los pueblos coloniales mejor conservados de Colombia, con una de las plazas empedradas más grandes de América. Rodeado de fósiles, desiertos pequeños y viñedos en un clima seco poco común en el país.",
    highlights: ["Plaza más grande", "Arquitectura colonial", "Fósiles"],
  ),
  TourismSite(
    title: "Caño Cristales",
    department: "Meta",
    imageUrl:
        "${_wiki}CA%C3%91O_CRISTALES_EL_R%C3%8DO_DE_LOS_CINCO_COLORES.jpg?width=1000",
    description:
        "Conocido como 'el río de los cinco colores' o 'el arcoíris líquido'. Una planta acuática endémica tiñe su lecho de rojo, amarillo, verde, azul y negro entre julio y noviembre, cuando el caudal es ideal para visitarlo.",
    highlights: ["Río de 5 colores", "Sierra de la Macarena", "Visita jul-nov"],
  ),
  TourismSite(
    title: "San Andrés",
    department: "San Andrés y Providencia",
    imageUrl: "${_wiki}Mar_de_los_siete_colores._San_Andres_Islas.JPG?width=1000",
    description:
        "Isla caribeña famosa por su 'mar de siete colores', con tonos que van del azul profundo al verde turquesa gracias a sus arrecifes de coral. Ideal para buceo, snorkel y playas de arena blanca.",
    highlights: ["Mar de 7 colores", "Arrecifes de coral", "Puerto libre"],
  ),
  TourismSite(
    title: "Catedral de Sal de Zipaquirá",
    department: "Cundinamarca",
    imageUrl: "${_wiki}Zipaquira_-_Catedral_de_Sal_(12).JPG?width=1000",
    description:
        "Iglesia construida dentro de una mina de sal en explotación, a poco más de una hora de Bogotá. Sus túneles y capillas talladas en roca la convierten en una de las obras arquitectónicas más singulares del país.",
    highlights: ["Bajo tierra", "Cerca de Bogotá", "Arquitectura única"],
  ),
  TourismSite(
    title: "Desierto de la Tatacoa",
    department: "Huila",
    imageUrl:
        "${_wiki}Paisaje_del_Desierto_de_La_Tatacoa_en_el_Huila_Colombia.jpg?width=1000",
    description:
        "Bosque seco tropical con paisajes ocres y grises formados por erosión, la segunda zona árida más extensa de Colombia. De noche, su cielo despejado lo hace uno de los mejores lugares del país para observación astronómica.",
    highlights: ["Observación astronómica", "Paisaje semiárido", "Cerca de Neiva"],
  ),
  TourismSite(
    title: "Comuna 13",
    department: "Antioquia (Medellín)",
    imageUrl: "${_wiki}Graffitour,_Medell%C3%ADn_02.jpg?width=1000",
    description:
        "Barrio de Medellín transformado por sus escaleras eléctricas públicas y un recorrido de grafitis ('graffitour') que cuenta la historia social de la ciudad. Símbolo de la renovación urbana y cultural de la comuna.",
    highlights: ["Escaleras eléctricas", "Graffitour", "Metrocable"],
  ),
];

class TurismoPage extends StatelessWidget {
  const TurismoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: tourismSites.length,
      itemBuilder: (context, index) {
        return _TourismCard(site: tourismSites[index]);
      },
    );
  }
}

class _TourismCard extends StatelessWidget {
  final TourismSite site;

  const _TourismCard({required this.site});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            site.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                alignment: Alignment.center,
                color: Colors.grey.shade900,
                child: const CircularProgressIndicator(),
              );
            },
            errorBuilder: (_, __, ___) {
              return Container(
                height: 200,
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 60),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  site.department,
                  style: TextStyle(
                    color: Colors.indigo.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  site.description,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: site.highlights
                      .map(
                        (h) => Chip(
                          label: Text(h, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.indigo.shade900,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
