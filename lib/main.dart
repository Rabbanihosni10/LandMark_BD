import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/landmark.dart';
import 'providers/landmark_provider.dart';
import 'screens/overview_map.dart';
import 'screens/records_list.dart';
import 'screens/new_entry.dart';
import 'screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LandmarkProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bangladesh Landmark Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/home': (ctx) => const MainShell(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    OverviewMapScreen(),
    RecordsListScreen(),
    NewEntryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangladesh Landmark Manager'),
        actions: [
          // Offline indicator placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Consumer<LandmarkProvider>(
              builder: (context, p, _) {
                return Icon(
                  p.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: p.isOnline ? Colors.greenAccent : Colors.orangeAccent,
                );
              },
            ),
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Records'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'New Entry',
          ),
        ],
      ),
    );
  }
}
