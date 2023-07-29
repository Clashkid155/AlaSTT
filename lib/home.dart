import 'package:alastt/main.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'voice': HighlightedWord(
      onTap: () => print('voice'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'subscribe': HighlightedWord(
      onTap: () => print('subscribe'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
    'like': HighlightedWord(
      onTap: () => print('like'),
      textStyle: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    'comment': HighlightedWord(
      onTap: () => print('comment'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: TextHighlight(
            text: _text,
            words: _highlights,
            textStyle: const TextStyle(
              fontSize: 32.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _listen() async {
    /* _speech.locales().then((value) => value.forEach((element) {
          print(element.name);
        }));
    _speech.systemLocale().then((value) => print(value?.name));
  */

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      var locales = await _speech.locales();
      locales.forEach((element) {
        print(element.name);
      });
      print((await _speech.systemLocale())?.name);
      var selectedLocale = locales[0];
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          // localeId: selectedLocale.localeId,
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SpeechToText _speechToText = SpeechToText();
  final translator = GoogleTranslator();
  String _lastWords = "";
  String _tranlated = "";
  late bool _isNotListening;
  TranslationLanguage _translateTo = TranslationLanguage.igbo;
  final TextEditingController ttsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText.initialize(
        onError: (errorNotification) => print("Err: $errorNotification"),
        options: [SpeechToText.androidIntentLookup]);
    _speechToText.statusListener = (String val) {
      switch (val) {
        case "listening":
          setState(() => _isNotListening = false);
        case "notListening" || "done":
          setState(() => _isNotListening = true);
      }
    };
    _isNotListening = _speechToText.isNotListening;
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(
        onResult: _onSpeechResult, listenMode: ListenMode.dictation);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      ttsController.text = result.recognizedWords;
    });

    _updateTranslated();
  }

  void _updateTranslated() async {
    if (_lastWords.isNotEmpty) {
      translator
          .translate(_lastWords, to: _translateTo.shortCode)
          .then((value) => setState(() => _tranlated = value.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = darkMode.value;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "AlaSTT",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: () {
                isDarkMode = !isDarkMode;
                darkMode.value = isDarkMode;
              },
              icon: Icon(
                  isDarkMode ? Icons.brightness_4 : Icons.brightness_7_sharp))
        ],
      ),
      // backgroundColor: Color,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Quick\n translation",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: isDarkMode
                        ? Colors.grey
                        : Color.fromRGBO(254, 249, 239, 1)),
                child: Center(
                  child: Text(
                    "English",
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : null),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                height: 150,
                width: 350,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: isDarkMode
                        ? Colors.grey
                        : Color.fromRGBO(254, 249, 239, 1)),
                child: TextField(
                  controller: ttsController,
                  maxLines: 5,
                  //keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (event) {
                    print("Clicked at $event");
                    print(FocusScope.of(context).focusedChild);
                    if (FocusScope.of(context).focusedChild != null) {
                      _updateTranslated();
                      print(_lastWords);
                    }
                    //FocusScope.of(context).unfocus();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(
                          top: 10, left: 10, right: 10, bottom: 5),
                      border: InputBorder.none),
                ),
                /*SingleChildScrollView(
                  child: Text(
                    _lastWords,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : null),
                  ),
                ),*/
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Container(
                height: 40,
                width: 250,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDarkMode
                        ? Colors.grey
                        : Color.fromRGBO(254, 249, 239, 1)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Translate to ",
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : null),
                    ),
                    DropdownButtonHideUnderline(
                        child: DropdownButton2<TranslationLanguage>(
                      isExpanded: true,
                      hint: Text(_translateTo.toString()),
                      items: drop(
                          TranslationLanguage.values, _translateTo, isDarkMode),
                      value: _translateTo,
                      onChanged: (TranslationLanguage? value) {
                        setState(() {
                          _translateTo = value ?? TranslationLanguage.igbo;
                          _tranlated = "";
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          height: 40,
                          width: 110),
                      menuItemStyleData: const MenuItemStyleData(
                        //padding: EdgeInsets.symmetric(horizontal: 0),
                        height: 40,
                      ),
                      iconStyleData: IconStyleData(
                          iconEnabledColor: isDarkMode ? Colors.white : null),
                      alignment: Alignment.centerLeft,
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDarkMode
                                ? Colors.grey
                                : Color.fromRGBO(254, 249, 239, 1)),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                height: 150,
                width: 350,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isDarkMode
                        ? Colors.grey
                        : Color.fromRGBO(254, 249, 239, 1)),
                child: SingleChildScrollView(
                  child: Text(
                    _tranlated,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : null),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 140,
            width: 150,
            child: FittedBox(
              child: FloatingActionButton.large(
                backgroundColor: const Color.fromRGBO(254, 134, 94, 1),
                //focusElevation: 0,
                //elevation: 0,
                shape: const CircleBorder(),
                onPressed: _isNotListening ? _startListening : _stopListening,
                tooltip: 'Listen',
                child: Icon(_isNotListening ? Icons.mic_off : Icons.mic),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Speak",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

enum TranslationLanguage {
  igbo("ig"),
  hausa("ha"),
  yoruba("yo"),
  french("fr"),
  spanish("es");

  const TranslationLanguage(this.shortCode);
  final String shortCode;

  @override
  String toString() {
    return name[0].toUpperCase() + name.substring(1, name.length);
  }
}

List<DropdownMenuItem<TranslationLanguage>> drop(
    List<TranslationLanguage> value, TranslationLanguage selected, bool dark) {
  List<DropdownMenuItem<TranslationLanguage>> list = [];
  for (var value1 in value) {
    list.add(DropdownMenuItem<TranslationLanguage>(
        value: value1,
        child: Text(
          value1.toString(),
          style: TextStyle(
              fontWeight: FontWeight.w500, color: dark ? Colors.white : null),
        )));
  }
  return list;
}
