import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/output_parsers.dart';
import 'package:langchain_core/prompts.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

List<WordPair> favorites = <WordPair>[];


//业务逻辑
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  
  void getNext(){
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite(){
      if(favorites.contains(current)){
        favorites.remove(current);
      }else{
        favorites.add(current);
      }
      notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = LikedPage();
        break;
      case 2:
        page = ChatPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, Constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: Constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble), 
                      label: Text('chat'))
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ...
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //让主题能够看得更清楚
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          pair.asLowerCase, 
          style: style
          //这个无障碍功能不知道为什么运行不了
          //semanticsLabel: "${pair.first} ${pair.second}",
          ),
      ),
    );
  }
}



class LikedPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: const Text(
           "Collection",
            style: TextStyle(fontWeight: FontWeight.bold),
            ),
        ),
        body: ListView(
          children: [
            for(var msg in favorites)
              Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text(msg.first),
                  subtitle: Text('Subtitle'),
                  trailing: Icon(Icons.arrow_forward),
                ),
              ),
          ],
        ),
    );
  }
}


class ChatPage extends StatefulWidget {
  static const routeName = '/chat';
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];


void getAnswer() async {
  // 初始化 ChatOllama 实例
  final model = ChatOllama(
    baseUrl: 'https://api.deepseek.com', // Base URL of Ollama API
    headers: {
      'Authorization': 'sk-d1267fe399324e28a47f5c41e0d2b88d', // Custom headers
      'Custom-Header': 'Custom-Value',
    },
    queryParams: {
      'param1': 'value1', // Custom query parameters
      'param2': 'value2',
    },
    client: null, // Use the default HTTP client
    defaultOptions: ChatOllamaOptions(
      model: 'DeepSeek', // Default model to use
    ),
    encoding: 'cl100k_base', // Encoding to use
  );

  // Now you can use the chatOllama instance to interact with the Ollama API
  // For example, you can send a request to generate text
  final messages = [
    ChatMessage.humanText('say hi!'),
  ];

  try {
    // 发送请求并获取响应
    final response = await model.call(messages);


    // 将响应结果添加到 _chatHistory
    _chatHistory.add({
      "time": DateTime.now(),
      "message": response,
      "isSender": false,
    });
    } catch (e) {
    // 处理错误
    print('Error: $e');
    _chatHistory.add({
      "time": DateTime.now(),
      "message": 'Error: $e',
      "isSender": false,
    });
    }
  }


  void _sendMessage(String message) {
    setState(() {
      _chatHistory.add({
        "message": message,
        "isSender": true,
      });
      _chatController.clear();
      _scrollToBottom();
    });

    // Simulate AI response
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _chatHistory.add({
          "message": "Hello! How can I help you?",
          "isSender": false,
        });
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text(
          "Chat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height - 160,
            child: ListView.builder(
              itemCount: _chatHistory.length,
              shrinkWrap: false,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                  child: Align(
                    alignment: (_chatHistory[index]["isSender"] ? Alignment.topRight : Alignment.topLeft),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: (_chatHistory[index]["isSender"] ? Color.fromARGB(255, 112, 168, 246) : Colors.white),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _chatHistory[index]["message"],
                        style: TextStyle(
                          fontSize: 15,
                          color: _chatHistory[index]["isSender"] ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              height: 60,
              width: double.infinity,
              color: Theme.of(context).colorScheme.inversePrimary,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                          controller: _chatController,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: (){
                      setState(() {
                      if(_chatController.text.isNotEmpty){
                      _chatHistory.add({
                        "time": DateTime.now(),
                        "message": _chatController.text,
                        "isSender": true,
                      });
                        _chatController.clear();
                      }
                      });
                      _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                      );

                      getAnswer();
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
                    padding: const EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF7D96E6),
                            Color(0xFF7D96E6),
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
                        alignment: Alignment.center,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}