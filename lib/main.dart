import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

// Define F1 team themes
class F1Theme {
  final String name;
  final MaterialColor primarySwatch;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const F1Theme({
    required this.name,
    required this.primarySwatch,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });
}

// Create a custom MaterialColor from a color
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final double r = color.r, g = color.g, b = color.b;

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      (r + (ds < 0 ? r : (255 - r)) * ds).round(),
      (g + (ds < 0 ? g : (255 - g)) * ds).round(),
      (b + (ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch);
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String _currentTheme = 'Ferrari'; // Default theme

  final Map<String, F1Theme> _themes = {
    'Ferrari': F1Theme(
      name: 'Ferrari',
      primarySwatch: createMaterialColor(Color(0xFFDC0000)), // Ferrari Red
      accentColor: Color(0xFFFFDF00), // Ferrari Yellow
      backgroundColor: Color(0xFFF8F8F8),
      textColor: Colors.black,
      iconColor: Color(0xFFDC0000),
    ),
    'McLaren': F1Theme(
      name: 'McLaren',
      primarySwatch: createMaterialColor(Color(0xFFFF8000)), // McLaren Orange
      accentColor: Color(0xFF0076FF), // McLaren Blue
      backgroundColor: Color(0xFF000000),
      textColor: Colors.white,
      iconColor: Color(0xFFFF8000),
    ),
    'Alpine': F1Theme(
      name: 'Alpine',
      primarySwatch: createMaterialColor(Color(0xFF0078C1)), // Alpine Blue
      accentColor: Color(0xFFFD4BC7), // Alpine Pink
      backgroundColor: Color(0xFF02192B),
      textColor: Colors.white,
      iconColor: Color(0xFFFD4BC7), // Alpine Pink
    ),
    'Mercedes': F1Theme(
      name: 'Mercedes',
      primarySwatch: createMaterialColor(Color(0xFF00A19B)), // Mercedes Teal
      accentColor: Color(0xFF000000), // Mercedes Black
      backgroundColor: Color(0xFFF0F0F0),
      textColor: Colors.black,
      iconColor: Color(0xFF00A19B),
    ),
    'Williams': F1Theme(
      name: 'Williams',
      primarySwatch: createMaterialColor(Color(0xFF00A0DE)), // Williams Blue
      accentColor: Color(0xFFFFFFFF), // Williams White
      backgroundColor: Color(0xFF041E42),
      textColor: Colors.white,
      iconColor: Color(0xFF00A0DE), // Williams Blue
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme') ?? 'Ferrari';
    });
  }

  // update the theme
  void _updateTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    F1Theme activeTheme = _themes[_currentTheme]!;

    return MaterialApp(
      title: 'Easy Scan',
      theme: ThemeData(
        primarySwatch: activeTheme.primarySwatch,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: activeTheme.primarySwatch,
          accentColor: activeTheme.accentColor,
          brightness:
              activeTheme.backgroundColor.computeLuminance() > 0.5
                  ? Brightness.light
                  : Brightness.dark,
        ),
        scaffoldBackgroundColor: activeTheme.backgroundColor,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: activeTheme.textColor),
          bodyMedium: TextStyle(color: activeTheme.textColor),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: activeTheme.primarySwatch,
          foregroundColor:
              activeTheme.backgroundColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
        ),
      ),
      home: MyHomePage(
        updateTheme: _updateTheme,
        currentTheme: _currentTheme,
        themes: _themes,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(String) updateTheme;
  final String currentTheme;
  final Map<String, F1Theme> themes;

  MyHomePage({
    required this.updateTheme,
    required this.currentTheme,
    required this.themes,
  });

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String _currentContent = 'login';
  String _resultMessage = '';
  bool _resultSuccess = false;
  bool _twosteps = false;
  String _acceptMessage = '';
  String _qrData = '';
  String _savedUrl = '';
  String _actionUrl = '';
  String _savedToken = '';
  int _timeout = 10; // Default timeout
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String _selectedTheme = 'Ferrari';

  MobileScannerController cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedUrl = prefs.getString('url') ?? '';
      _timeout = prefs.getInt('timeout') ?? 10;
      _selectedTheme = prefs.getString('theme') ?? widget.currentTheme;
      _twosteps = prefs.getBool("twosteps") ?? false;
      _urlController.text = _savedUrl; // Preset URL
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('url', _savedUrl);
    await prefs.setInt('timeout', _timeout);
    await prefs.setString('theme', _selectedTheme);
    await prefs.setBool("twosteps", _twosteps);
    widget.updateTheme(_selectedTheme);
  }

  Future<void> _sendPostRequest(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      Map<String, String> headers;

      headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(Duration(seconds: _timeout));

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'error') {
        setState(() {
          _resultMessage = responseData['message'];
          _resultSuccess = false;
          _currentContent = 'result';
        });
        Timer(Duration(seconds: _timeout), () {
          setState(() {
            if (_currentContent == 'result' && _qrData.isNotEmpty) {
              _currentContent = 'scan';
            } else {
              _currentContent = 'login';
            }
            _qrData = '';
          });
        });
      } else if (responseData['status'] == 'ok') {
        if (_currentContent == 'login') {
          setState(() {
            _actionUrl = responseData['url'];
            _savedToken = responseData['token'] ?? _savedToken;
            _currentContent = 'scan';
          });
        } else {
          setState(() {
            _resultMessage = responseData['message'] ?? 'OK';
            _resultSuccess = true;
            _currentContent = 'result';
          });
          Timer(Duration(seconds: _timeout), () {
            setState(() {
              _currentContent = 'scan';
            });
          });
        }
      } else if (responseData['status'] == 'warning') {
        setState(() {
          _resultMessage = responseData['message'] ?? 'Warning occurred';
          _resultSuccess = false;
          _currentContent = 'result';
        });
        Timer(Duration(seconds: _timeout), () {
          setState(() {
            _currentContent = 'scan';
          });
        });
      } else {
        // Handle unknown status
        setState(() {
          _resultMessage =
              responseData['message'] ??
              'Unknown status: ${responseData['status']}';
          _resultSuccess = false;
          _currentContent = 'result';
        });
        Timer(Duration(seconds: _timeout), () {
          setState(() {
            _currentContent = 'scan';
          });
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
        _resultSuccess = false;
        _currentContent = 'result';
      });
      Timer(Duration(seconds: _timeout), () {
        setState(() {
          if (_currentContent == 'result' && _qrData.isNotEmpty) {
            _currentContent = 'scan';
          } else {
            _currentContent = 'login';
          }
          _qrData = '';
        });
      });
    }
  }

  void _onDetect(BarcodeCapture barcodes) {
    final barcode = barcodes.barcodes.first;
    if (barcode.rawValue == null) {
      debugPrint('Failed to scan QR Code');
    } else {
      cameraController.stop();
      setState(() {
        _qrData = barcode.rawValue!;
      });
      try {
        final jsonData = jsonDecode(_qrData);
        if (jsonData is Map<String, dynamic> && _twosteps) {
          setState(() {
            _acceptMessage = jsonData['info'];
            _currentContent = 'accept';
          });
        } else {
          _sendPostRequest(_actionUrl, jsonData, token: _savedToken);
        }
      } catch (e) {
        _sendPostRequest(_actionUrl, {'data': _qrData}, token: _savedToken);
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    F1Theme activeTheme = widget.themes[_selectedTheme]!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Easy Scan'),
            Spacer(),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _currentContent = 'settings';
                });
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: activeTheme.backgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    'What can we scan today?',
                    style: TextStyle(color: activeTheme.textColor),
                  ),
                  Spacer(),
                  SvgPicture.asset(
                    // Use SvgPicture.asset
                    'logos/easyscan-logo.svg', // Replace with your SVG asset path
                    height: 50.0,
                    colorFilter: ColorFilter.mode(
                      // Apply color filter
                      activeTheme.iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentContent) {
      case 'login':
        return _buildLoginScreen();
      case 'scan':
        return _buildScanScreen();
      case 'accept':
        return _buildAcceptScreen();
      case 'result':
        return _buildResultScreen();
      case 'settings':
        return _buildSettingsScreen();
      default:
        return Container();
    }
  }

  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(
                color: widget.themes[_selectedTheme]!.textColor,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themes[_selectedTheme]!.accentColor,
                ),
              ),
            ),
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: widget.themes[_selectedTheme]!.textColor,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themes[_selectedTheme]!.accentColor,
                ),
              ),
            ),
            obscureText: true,
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(
                color: widget.themes[_selectedTheme]!.textColor,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themes[_selectedTheme]!.accentColor,
                ),
              ),
            ),
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _sendPostRequest(_urlController.text, {
                'username': _usernameController.text,
                'password': _passwordController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themes[_selectedTheme]!.primarySwatch,
            ),
            child: Text(
              'Login',
              style: TextStyle(
                color:
                    widget
                        .themes[_selectedTheme]!
                        .textColor, // Force text color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanScreen() {
    return MobileScanner(controller: cameraController, onDetect: _onDetect);
  }

  Widget _buildAcceptScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _acceptMessage,
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentContent = 'scan';
                  });
                  cameraController.start();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themes[_selectedTheme]!.accentColor,
                ),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    final jsonData = jsonDecode(_qrData);
                    _sendPostRequest(_actionUrl, jsonData, token: _savedToken);
                  } catch (e) {
                    print('error decoding json from QR: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themes[_selectedTheme]!.primarySwatch,
                  foregroundColor: widget.themes[_selectedTheme]!.accentColor,
                ),
                child: Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _resultSuccess ? Icons.check_circle : Icons.cancel,
            color: _resultSuccess ? Colors.green : Colors.red,
            size: 50,
          ),
          SizedBox(height: 20),
          Text(
            _resultMessage,
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.themes[_selectedTheme]!.textColor,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            onChanged: (value) {
              _savedUrl = value;
            },
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(
                color: widget.themes[_selectedTheme]!.textColor,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themes[_selectedTheme]!.accentColor,
                ),
              ),
            ),
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
          ),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _timeout = int.tryParse(value) ?? 10;
            },
            decoration: InputDecoration(
              labelText: 'Timeout (seconds)',
              labelStyle: TextStyle(
                color: widget.themes[_selectedTheme]!.textColor,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themes[_selectedTheme]!.accentColor,
                ),
              ),
            ),
            style: TextStyle(color: widget.themes[_selectedTheme]!.textColor),
            controller: TextEditingController(text: _timeout.toString()),
          ),
          SizedBox(height: 20),
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 18,
              color: widget.themes[_selectedTheme]!.textColor,
            ),
          ),

          SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _twosteps,
                onChanged: (bool? newValue) {
                  setState(() {
                    _twosteps = newValue ?? false;
                  });
                },
              ),
              Text(
                'Enable Two Steps Scanning',
                style: TextStyle(
                  color: widget.themes[_selectedTheme]!.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedTheme,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTheme = newValue!;
              });
            },
            items:
                widget.themes.keys.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: widget.themes[_selectedTheme]!.textColor,
                      ),
                    ),
                  );
                }).toList(),
            dropdownColor:
                widget
                    .themes[_selectedTheme]!
                    .backgroundColor, // Optional: set dropdown background color
            style: TextStyle(
              color: widget.themes[_selectedTheme]!.textColor,
            ), // Optional: set dropdown text color
            iconEnabledColor:
                widget
                    .themes[_selectedTheme]!
                    .accentColor, // Optional: set icon color
            underline: Container(
              height: 1,
              color:
                  widget
                      .themes[_selectedTheme]!
                      .accentColor, // Optional: set underline color
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadSettings();
                    _currentContent = _qrData.isNotEmpty ? 'scan' : 'login';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themes[_selectedTheme]!.accentColor,
                ),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveSettings();
                  setState(() {
                    _currentContent = _qrData.isNotEmpty ? 'scan' : 'login';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themes[_selectedTheme]!.primarySwatch,
                ),
                child: Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
