import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> suggestions = [];
  Map<String, dynamic>? suggestedPlace;
  Map<String, dynamic>? weatherData;

  // Fetch suggestions from Geoapify API
  void fetchSuggestion(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    const String geoapifyApiKey = "API";
    final String api =
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&format=json&apiKey=$geoapifyApiKey';

    final response = await http.get(Uri.parse(api));

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['results'];
      setState(() {
        suggestions = data;
      });
    } else {
      print("Failed to load suggestion");
      setState(() {
        suggestions = [];
      });
    }
  }

  // Fetch weather data using OpenWeatherMap API
  void fetchWeather(double lat, double lon) async {
    const String weatherApiKey = "API";
    final String api =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$weatherApiKey';

    final response = await http.get(Uri.parse(api));

    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
      });
    } else {
      print("Failed to fetch weather");
      setState(() {
        weatherData = null;
      });
    }
  }

  void tappedSuggestion(var place) {
    if (place != null) {
      setState(() {
        _searchController.text = place["formatted"];
        suggestions = [];
        suggestedPlace = {
          "coords": {"lat": place['lat'], "lng": place['lon']},
          "city": place['county'],
          "state": place['state'],
          "country": place['country']
        };
      });
      fetchWeather(place['lat'], place['lon']); // Fetch weather for the location
    }
  }

  Widget buildWeatherInfo() {
    if (weatherData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weather Updates",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.red),
              SizedBox(width: 8),
              Text("Temperature: ${weatherData?['main']['temp']}°C"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue),
              SizedBox(width: 8),
              Text("Condition: ${weatherData?['weather'][0]['description']}"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue),
              SizedBox(width: 8),
              Text("Humidity: ${weatherData?['main']['humidity']}%"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.wind_power, color: Colors.green),
              SizedBox(width: 8),
              Text("Wind Speed: ${weatherData?['wind']['speed']} m/s"),
            ],
          ),
        ],
      );
    } else {
      return Text(
        "Weather data not available.",
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.cloud, size: 28, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Weather",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'lib/weather_image.jpg',
                  height: 180,
                  width:1080,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Search for a place...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                style: TextStyle(fontSize: 16),
                onChanged: fetchSuggestion,
              ),
              const SizedBox(height: 16),
              if (suggestions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final place = suggestions[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(
                            place['formatted'],
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () => tappedSuggestion(place),
                        ),
                      );
                    },
                  ),
                ),
              if (suggestedPlace != null) ...[
                Divider(height: 32, color: Colors.teal),
                Text(
                  "Selected Place:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                Text(
                  "${suggestedPlace?['city']}, ${suggestedPlace?['state']}, ${suggestedPlace?['country']}",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text("Latitude: ${suggestedPlace?['coords']['lat']}"),
                Text("Longitude: ${suggestedPlace?['coords']['lng']}"),
                const SizedBox(height: 8),
                Divider(height: 32, color: Colors.teal),
                buildWeatherInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}