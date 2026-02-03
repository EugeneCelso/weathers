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

class _weatherAppState extends State<weatherApp> with TickerProviderStateMixin {
  String currentLocation = "Arayat";
  Color selectedColor = CupertinoColors.systemYellow;
  int currentTab = 0;
  CupertinoTabController? _tabController;
  bool isMetric = true; // true = Metric (Celsius + km/h), false = Imperial (Fahrenheit + mph)
  String windSpeed = "0.0";
  String windSpeedUnit = "m/s";

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

  Widget getAnimatedWeatherIcon(String condition, Color color, double size) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return _SunAnimation(color: color, size: size);
      case 'clouds':
        return _CloudAnimation(color: color, size: size);
      case 'rain':
      case 'drizzle':
        return _RainAnimation(color: color, size: size);
      case 'thunderstorm':
        return _ThunderstormAnimation(color: color, size: size);
      case 'snow':
        return _SnowAnimation(color: color, size: size);
      case 'mist':
      case 'fog':
      case 'haze':
        return _FogAnimation(color: color, size: size);
      default:
        return _SunAnimation(color: color, size: size);
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

        double tempKelvin = weatherData["list"][0]["main"]["temp"];
        double feelsLikeKelvin = weatherData["list"][0]["main"]["feels_like"];

        if (isMetric) {
          temperature = (tempKelvin - 273.15).toStringAsFixed(0);
          feels_like = (feelsLikeKelvin - 273.15).toStringAsFixed(0);
        } else {
          // Convert to Fahrenheit: (K - 273.15) × 9/5 + 32
          temperature = ((tempKelvin - 273.15) * 9/5 + 32).toStringAsFixed(0);
          feels_like = ((feelsLikeKelvin - 273.15) * 9/5 + 32).toStringAsFixed(0);
        }

        humidity = (weatherData["list"][0]["main"]["humidity"]).toString();

        // Get wind speed (m/s by default from API)
        double windSpeedMs = weatherData["list"][0]["wind"]["speed"].toDouble();

        if (isMetric) {
          // Metric: convert to km/h
          // 1 m/s = 3.6 km/h
          double windSpeedKmh = windSpeedMs * 3.6;
          windSpeed = windSpeedKmh.toStringAsFixed(1);
          windSpeedUnit = "km/h";
        } else {
          // Imperial: convert to mph (miles per hour)
          // 1 m/s = 2.237 mph
          double windSpeedMph = windSpeedMs * 2.237;
          windSpeed = windSpeedMph.toStringAsFixed(1);
          windSpeedUnit = "mph";
        }
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
        inactiveColor: Color(0xFFFFFFFF),
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
                            // Animated Weather Icon
                            getAnimatedWeatherIcon(
                                weatherCondition,
                                selectedColor,
                                isWideScreen ? 200 : 160
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
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(isWideScreen ? 24 : 20),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: CupertinoColors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.wind,
                                      color: CupertinoColors.white,
                                      size: isWideScreen ? 28 : 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Wind Speed",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 15 : 13,
                                            color: CupertinoColors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "$windSpeed $windSpeedUnit",
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 32 : 28,
                                            fontWeight: FontWeight.w300,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsTile(
                                  icon: CupertinoIcons.paintbrush_fill,
                                  iconColor: Color(0xFFFF9500),
                                  title: "Icon Color",
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: selectedColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: CupertinoColors.systemGrey3,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        CupertinoIcons.chevron_forward,
                                        color: CupertinoColors.systemGrey3,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showColorPicker(context, isWideScreen),
                                  isWideScreen: isWideScreen,
                                ),
                                Container(
                                  height: 0.5,
                                  margin: EdgeInsets.only(left: 53),
                                  color: CupertinoColors.systemGrey4.darkColor,
                                ),
                                _buildSettingsTileWithSwitch(
                                  icon: CupertinoIcons.globe,
                                  iconColor: Color(0xFF007AFF),
                                  title: "Metrics",
                                  value: isMetric,
                                  onChanged: (value) {
                                    setState(() {
                                      isMetric = value;
                                    });
                                    getWeatherData();
                                  },
                                  isWideScreen: isWideScreen,
                                ),
                                Container(
                                  height: 0.5,
                                  margin: EdgeInsets.only(left: 53),
                                  color: CupertinoColors.systemGrey4.darkColor,
                                ),
                                _buildSettingsTile(
                                  icon: CupertinoIcons.location_fill,
                                  iconColor: Color(0xFF5856D6),
                                  title: "Location",
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentLocation,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: CupertinoColors.systemGrey,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        CupertinoIcons.chevron_forward,
                                        color: CupertinoColors.systemGrey3,
                                        size: 20,
                                      ),
                                    ],
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
    required Color iconColor,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    required bool isWideScreen,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(6.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: CupertinoColors.white,
                  size: 17,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTileWithSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isWideScreen,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(6.5),
            ),
            child: Center(
              child: Icon(
                icon,
                color: CupertinoColors.white,
                size: 17,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, bool isWideScreen) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => _DraggableColorPicker(
        selectedColor: selectedColor,
        isWideScreen: isWideScreen,
        onColorSelected: (color) {
          setState(() {
            selectedColor = color;
          });
        },
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
                  _tabController?.index = 0;
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Draggable Color Picker Widget
class _DraggableColorPicker extends StatefulWidget {
  final Color selectedColor;
  final bool isWideScreen;
  final Function(Color) onColorSelected;

  const _DraggableColorPicker({
    required this.selectedColor,
    required this.isWideScreen,
    required this.onColorSelected,
  });

  @override
  State<_DraggableColorPicker> createState() => _DraggableColorPickerState();
}

class _DraggableColorPickerState extends State<_DraggableColorPicker> {
  double dragOffset = 0;

  final List<Color> colors = [
    CupertinoColors.systemYellow,
    CupertinoColors.systemOrange,
    CupertinoColors.systemRed,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemBlue,
    CupertinoColors.systemTeal,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemCyan,
    CupertinoColors.systemMint,
    Color(0xFFFF1493), // Deep Pink
    Color(0xFF9370DB), // Medium Purple
    Color(0xFF00CED1), // Dark Turquoise
    Color(0xFFFF6347), // Tomato
    Color(0xFF32CD32), // Lime Green
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.6;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          dragOffset += details.delta.dy;
          if (dragOffset > 0) {
            // Allow dragging down
          } else {
            dragOffset = 0;
          }
        });
      },
      onVerticalDragEnd: (details) {
        if (dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
          Navigator.pop(context);
        } else {
          setState(() {
            dragOffset = 0;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, dragOffset, 0),
        height: maxHeight,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Choose Icon Color",
                  style: TextStyle(
                    fontSize: widget.isWideScreen ? 22 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Color Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isWideScreen ? 40 : 24,
                    vertical: 16,
                  ),
                  mainAxisSpacing: widget.isWideScreen ? 24 : 20,
                  crossAxisSpacing: widget.isWideScreen ? 24 : 20,
                  children: colors.map((color) => _buildColorOption(color)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    bool isSelected = widget.selectedColor == color;
    return GestureDetector(
      onTap: () {
        widget.onColorSelected(color);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
            size: widget.isWideScreen ? 36 : 32,
          ),
        )
            : null,
      ),
    );
  }
}

// Animated Weather Icons
class _SunAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _SunAnimation({required this.color, required this.size});

  @override
  State<_SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<_SunAnimation> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_glowAnimation.value),
                blurRadius: 40,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Icon(
              CupertinoIcons.sun_max_fill,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class _CloudAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _CloudAnimation({required this.color, required this.size});

  @override
  State<_CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<_CloudAnimation> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _scaleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut)
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _scaleController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatAnimation.value, -_floatAnimation.value.abs() * 0.3),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: 0.85 + (_scaleAnimation.value - 0.92) * 0.5,
              child: Icon(
                CupertinoIcons.cloud_fill,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RainAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _RainAnimation({required this.color, required this.size});

  @override
  State<_RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<_RainAnimation> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -8, end: 12).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut)
    );

    _shakeAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _shakeController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.rotate(
            angle: _shakeAnimation.value,
            child: Icon(
              CupertinoIcons.cloud_rain_fill,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class _ThunderstormAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _ThunderstormAnimation({required this.color, required this.size});

  @override
  State<_ThunderstormAnimation> createState() => _ThunderstormAnimationState();
}

class _ThunderstormAnimationState extends State<_ThunderstormAnimation> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _shakeController;
  late Animation<double> _flashAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);

    _flashAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeInOut)
    );

    _shakeAnimation = Tween<double>(begin: -3, end: 3).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn)
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flashController, _shakeController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_flashAnimation.value * 0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Opacity(
              opacity: _flashAnimation.value,
              child: Icon(
                CupertinoIcons.cloud_bolt_rain_fill,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SnowAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _SnowAnimation({required this.color, required this.size});

  @override
  State<_SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<_SnowAnimation> with TickerProviderStateMixin {
  late AnimationController _fallController;
  late AnimationController _swayController;
  late AnimationController _rotateController;
  late Animation<double> _fallAnimation;
  late Animation<double> _swayAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _fallController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _swayController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _fallAnimation = Tween<double>(begin: -10, end: 18).animate(
        CurvedAnimation(parent: _fallController, curve: Curves.easeInOut)
    );

    _swayAnimation = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _swayController, curve: Curves.easeInOut)
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_rotateController);
  }

  @override
  void dispose() {
    _fallController.dispose();
    _swayController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fallController, _swayController, _rotateController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_swayAnimation.value, _fallAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Icon(
              CupertinoIcons.snow,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class _FogAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _FogAnimation({required this.color, required this.size});

  @override
  State<_FogAnimation> createState() => _FogAnimationState();
}

class _FogAnimationState extends State<_FogAnimation> with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _fadeController;
  late Animation<double> _driftAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _driftAnimation = Tween<double>(begin: -15, end: 15).animate(
        CurvedAnimation(parent: _driftController, curve: Curves.easeInOut)
    );

    _fadeAnimation = Tween<double>(begin: 0.4, end: 0.85).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _driftController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_driftController, _fadeController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_driftAnimation.value, 0),
          child: Transform.scale(
            scale: 0.95 + (_fadeAnimation.value - 0.4) * 0.2,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Icon(
                CupertinoIcons.cloud_fog_fill,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
