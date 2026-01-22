import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'variables.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,
    theme: const CupertinoThemeData(
      brightness: Brightness.dark,
    ),
    home: weatherApp(),));
}

class weatherApp extends StatefulWidget {
  const weatherApp({super.key});

  @override
  State<weatherApp> createState() => _weatherAppState();
}

class _weatherAppState extends State<weatherApp> {
  String currentLocation = "Arayat";
  Color selectedColor = CupertinoColors.systemYellow;
  int currentTab = 0;
  CupertinoTabController? _tabController;

  @override
  void initState() {
    _tabController = CupertinoTabController(initialIndex: 0);
    getWeatherData();
    setState(() {
      weatherCondition = "";
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return CupertinoIcons.sun_max_fill;
      case 'clouds':
        return CupertinoIcons.cloud_fill;
      case 'rain':
        return CupertinoIcons.cloud_rain_fill;
      case 'drizzle':
        return CupertinoIcons.cloud_drizzle_fill;
      case 'thunderstorm':
        return CupertinoIcons.cloud_bolt_rain_fill;
      case 'snow':
        return CupertinoIcons.snow;
      case 'mist':
      case 'fog':
      case 'haze':
        return CupertinoIcons.cloud_fog_fill;
      default:
        return CupertinoIcons.sun_max;
    }
  }

  String getWeatherImage(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'assets/clears.jpg';
      case 'clouds':
        return 'assets/clouds.jpg';
      case 'rain':
      case 'drizzle':
        return 'assets/ra.jpg';
      case 'thunderstorm':
        return 'assets/storjm.jpg';
      case 'snow':
        return 'assets/snow.jpg';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'assets/fog.jpg';
      default:
        return 'assets/clears.jpg';
    }
  }

  Future<void> getWeatherData() async {
    final uri = "https://api.openweathermap.org/data/2.5/forecast?q=$currentLocation&appid=$api";
    final response = await http.get(Uri.parse(uri));

    weatherData = jsonDecode(response.body);
    print(weatherData["cod"]);
    if (weatherData["cod"] == "200") {
      setState(() {
        city = weatherData["city"]["name"];
        weatherCondition = weatherData["list"][0]["weather"][0]["main"];
        temperature = (weatherData["list"][0]["main"]["temp"] - 273.15).toStringAsFixed(0);
        feels_like = (weatherData["list"][0]["main"]["feels_like"] - 273.15).toStringAsFixed(0);
        humidity = (weatherData["list"][0]["main"]["humidity"]).toString();
      });
      print(weatherData["list"][0]["main"]["temp"] - 273.15);
    } else if (weatherData["cod"] == "404") {
      showCupertinoDialog(context: context, builder: (context){
        return CupertinoAlertDialog(
          title: Text("Error"),
          content: Text("Invalid City"),
          actions: [CupertinoButton(child: Text("Close"), onPressed: (){
            Navigator.pop(context);
          })],
        );
      });
    }
  }

  TextEditingController _location = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.transparent,
        activeColor: selectedColor,
        inactiveColor: Color(0xFFFFFFFF), // Changed to bright white
        iconSize: isWideScreen ? 30 : 28,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings_solid),
            label: "Settings",
          )
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 0) {
          return CupertinoPageScaffold(
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    getWeatherImage(weatherCondition),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E3A8A),
                              Color(0xFF3B82F6),
                              Color(0xFF60A5FA),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Dark overlay
                Positioned.fill(
                  child: Container(
                    color: CupertinoColors.black.withOpacity(0.3),
                  ),
                ),
                // Content
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWideScreen ? 40 : 24,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: isWideScreen ? 60 : 40),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: CupertinoColors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    color: CupertinoColors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$city',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: isWideScreen ? 24 : 20,
                                      letterSpacing: 0.5,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isWideScreen ? 80 : 60),
                            Icon(
                              getWeatherIcon(weatherCondition),
                              color: selectedColor,
                              size: isWideScreen ? 200 : 160,
                            ),
                            SizedBox(height: isWideScreen ? 40 : 30),
                            Text(
                              "$temperature°",
                              style: TextStyle(
                                fontSize: isWideScreen ? 120 : 96,
                                fontWeight: FontWeight.w200,
                                height: 1,
                                color: CupertinoColors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: CupertinoColors.black.withOpacity(0.5),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '$weatherCondition',
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: isWideScreen ? 28 : 24,
                                color: CupertinoColors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8.0,
                                    color: CupertinoColors.black.withOpacity(0.5),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isWideScreen ? 80 : 60),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(isWideScreen ? 24 : 20),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: CupertinoColors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.white.withOpacity(0.25),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.thermometer,
                                            color: CupertinoColors.white,
                                            size: isWideScreen ? 28 : 24,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          "Feels like",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 15 : 13,
                                            color: CupertinoColors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "$feels_like°",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 32 : 28,
                                            fontWeight: FontWeight.w300,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(isWideScreen ? 24 : 20),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: CupertinoColors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.white.withOpacity(0.25),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.drop_fill,
                                            color: CupertinoColors.white,
                                            size: isWideScreen ? 28 : 24,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          "Humidity",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 15 : 13,
                                            color: CupertinoColors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "$humidity%",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 32 : 28,
                                            fontWeight: FontWeight.w300,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isWideScreen ? 60 : 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.black,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isWideScreen ? 40 : 24,
                            isWideScreen ? 40 : 24,
                            isWideScreen ? 40 : 24,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Settings",
                                style: TextStyle(
                                  fontSize: isWideScreen ? 40 : 34,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Customize your weather experience",
                                style: TextStyle(
                                  fontSize: isWideScreen ? 18 : 16,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 40 : 24,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.darkColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsTile(
                                  icon: CupertinoIcons.paintbrush_fill,
                                  iconColor: LinearGradient(
                                    colors: [CupertinoColors.systemYellow, CupertinoColors.systemOrange],
                                  ),
                                  title: "Icon Color",
                                  subtitle: "Change weather icon color",
                                  trailing: Container(
                                    width: isWideScreen ? 36 : 32,
                                    height: isWideScreen ? 36 : 32,
                                    decoration: BoxDecoration(
                                      color: selectedColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedColor.withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _showColorPicker(context, isWideScreen),
                                  isWideScreen: isWideScreen,
                                ),
                                Container(
                                  height: 1,
                                  margin: EdgeInsets.only(left: isWideScreen ? 76 : 68),
                                  color: CupertinoColors.systemGrey4.darkColor,
                                ),
                                _buildSettingsTile(
                                  icon: CupertinoIcons.location_fill,
                                  iconColor: LinearGradient(
                                    colors: [CupertinoColors.systemBlue, CupertinoColors.systemIndigo],
                                  ),
                                  title: "Location",
                                  subtitle: currentLocation,
                                  trailing: Icon(
                                    CupertinoIcons.chevron_forward,
                                    color: CupertinoColors.systemGrey2,
                                    size: isWideScreen ? 22 : 20,
                                  ),
                                  onTap: () => _showLocationDialog(context),
                                  isWideScreen: isWideScreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required LinearGradient iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    required bool isWideScreen,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 20 : 16),
        child: Row(
          children: [
            Container(
              width: isWideScreen ? 48 : 44,
              height: isWideScreen ? 48 : 44,
              decoration: BoxDecoration(
                gradient: iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.white,
                size: isWideScreen ? 26 : 24,
              ),
            ),
            SizedBox(width: isWideScreen ? 18 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isWideScreen ? 19 : 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isWideScreen ? 15 : 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, bool isWideScreen) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: isWideScreen ? 400 : 350,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Choose Icon Color",
                  style: TextStyle(
                    fontSize: isWideScreen ? 22 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 40 : 24,
                    vertical: 16,
                  ),
                  mainAxisSpacing: isWideScreen ? 24 : 20,
                  crossAxisSpacing: isWideScreen ? 24 : 20,
                  children: [
                    _buildColorOption(CupertinoColors.systemYellow, isWideScreen),
                    _buildColorOption(CupertinoColors.systemOrange, isWideScreen),
                    _buildColorOption(CupertinoColors.systemRed, isWideScreen),
                    _buildColorOption(CupertinoColors.systemPink, isWideScreen),
                    _buildColorOption(CupertinoColors.systemPurple, isWideScreen),
                    _buildColorOption(CupertinoColors.systemBlue, isWideScreen),
                    _buildColorOption(CupertinoColors.systemTeal, isWideScreen),
                    _buildColorOption(CupertinoColors.systemGreen, isWideScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    _location.clear();
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Change Location"),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CupertinoTextField(
              controller: _location,
              placeholder: "Enter city name",
              padding: EdgeInsets.all(12),
              autocorrect: false,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("Save"),
              onPressed: () {
                if (_location.text.isNotEmpty) {
                  setState(() {
                    currentLocation = _location.text;
                  });
                  getWeatherData();
                  Navigator.pop(context);
                  // Switch to home tab
                  _tabController?.index = 0;
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorOption(Color color, bool isWideScreen) {
    bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? CupertinoColors.white : color.withOpacity(0.3),
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
              : [],
        ),
        child: isSelected
            ? Center(
          child: Icon(
            CupertinoIcons.checkmark_alt,
            color: CupertinoColors.white,
            size: isWideScreen ? 36 : 32,
          ),
        )
            : null,
      ),
    );
  }
}