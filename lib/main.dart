import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:random_photo/check_exception.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// This list of photo name 'prompt' and url for photo
  List<Map<String, dynamic>> _listOfPhoto = [];

  /// This boolean for check if image is in loading status
  bool _isLoading = true;

  /// Counter for limit of loaded photo
  int _counter = 5;

  /// Index for check which photo in [_listOfPhoto] loaded
  int _currentIndexPhoto = 0;

  /// Function for getting body for [_getRandomPhoto]
  Map<String, dynamic> _getRandomBody() {

    /// There we get random Pair words
    Iterable<WordPair> wordsPair = generateWordPairs(random: Random()).take(1);


    /// Next step is split pair words
    final words = wordsPair.first.asSnakeCase.split("_").join(" ").toString();

    Map<String, dynamic> mapOfBody = {
      "prompt": words,
      "n": 1,
      "size": "256x256"
    };

    return mapOfBody;
  }

  /// Function for getting photo from API
  Future<void> _getRandomPhoto() async {
    final randomBody = _getRandomBody();
    String randomBodyJson = jsonEncode(randomBody);
    try {
      final response = await http.post(
          Uri.parse("https://api.openai.com/v1/images/generations"),
          headers: {
            "Content-Type": "application/json",
            "Authorization":
                "Bearer {your api key}" // <= there you need insert your api key
          },
          body: randomBodyJson);

      if (response.statusCode == 200) {
        /// If status was 200 then we add prompt and url to _listOfPhoto
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _listOfPhoto.add({
            "prompt": randomBody["prompt"],
            "url": responseData['data'][0]['url']
          });
        });
      } else {
        throw NoConnectionException('Bad response: ${response.statusCode}');
      }
    } catch (e) {
      throw NoConnectionException('Bad connect');
    }
  }

  /// Function for getting random photo
  Future<void> _loadRandomPhoto() async {
    setState(() {
      _isLoading = true;
    });
    await _getRandomPhoto();
    setState(() {
      _isLoading = false;
      _counter--;
    });
  }

  /// Function for loading next photo. If in list we have next photo it's takes
  /// from list. In another way if next photo doesn't exist we take it from
  /// [_loadRandomPhoto]
  void _nextPhoto() {
    if (_counter != 0 && _currentIndexPhoto == _listOfPhoto.length - 1) {
      _loadRandomPhoto();
      setState(() {
        _currentIndexPhoto++;
      });
    } else if (_currentIndexPhoto != _listOfPhoto.length - 1) {
      setState(() {
        _currentIndexPhoto++;
      });
    }
  }

  /// Function for loaded prev photo
  void _prevPhoto() {
    if (_currentIndexPhoto > 0) {
      setState(() {
        _currentIndexPhoto--;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    /// There is we loaded first photo once our app is opened
    _loadRandomPhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Photo and prompt
            AspectRatio(
              aspectRatio: 16 / 16,
              child: !_isLoading && _listOfPhoto.isNotEmpty
                  ? Column(
                      children: [
                        Image.network(_listOfPhoto[_currentIndexPhoto]["url"]),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(_listOfPhoto[_currentIndexPhoto]['prompt']),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            /// Row for button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Button for loading next photo
                InkResponse(
                  /// There we check if status is in loading and if it's true we
                  /// do button doesn't active
                  onTap: () => !_isLoading ? _prevPhoto() : null,
                  child: const SizedBox(
                    height: 50,
                    width: 100,
                    child: Card(
                      child: Center(child: Text('Prev')),
                    ),
                  ),
                ),
                /// Button for loading prev photo
                InkResponse(
                  /// There we check if status is in loading and if it's true we
                  /// do button doesn't active
                  onTap: () => !_isLoading ? _nextPhoto() : null,
                  child: const SizedBox(
                    height: 50,
                    width: 100,
                    child: Card(
                      child: Center(child: Text('Next')),
                    ),
                  ),
                ),
              ],
            ),
            /// Counter for left photo
            Text('Left: $_counter'),
          ],
        ),
      ),
    );
  }
}
