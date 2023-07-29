import 'package:alastt/main.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SpeechToText _speechToText = SpeechToText();
  final translator = GoogleTranslator();
  String _translated = "";
  late bool _isNotListening;
  TranslationLanguage _translateTo = TranslationLanguage.igbo;
  final TextEditingController ttsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText.initialize(options: [SpeechToText.androidIntentLookup]);

    /// Sets the value of _isNotListening which is used for mic
    /// status (stroke out or not)
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
      ttsController.text = result.recognizedWords;
    });

    _updateTranslated();
  }

  /// Converts input text to selected language (default = Igbo)
  void _updateTranslated() async {
    if (ttsController.value.text.isNotEmpty) {
      translator
          .translate(ttsController.value.text, to: _translateTo.shortCode)
          .then((value) => setState(() => _translated = value.text));
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
                        : const Color.fromRGBO(254, 249, 239, 1)),
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
                        : const Color.fromRGBO(254, 249, 239, 1)),
                child: TextField(
                  controller: ttsController,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : null),
                  maxLines: 5,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (_) {
                    if (FocusScope.of(context).focusedChild != null) {
                      _updateTranslated();
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onSubmitted: (_) => _updateTranslated(),
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(
                          top: 10, left: 10, right: 10, bottom: 5),
                      border: InputBorder.none),
                ),
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
                        : const Color.fromRGBO(254, 249, 239, 1)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
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
                          _translated = "";
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
                                : const Color.fromRGBO(254, 249, 239, 1)),
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
                        : const Color.fromRGBO(254, 249, 239, 1)),
                child: SingleChildScrollView(
                  child: Text(
                    _translated,
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
