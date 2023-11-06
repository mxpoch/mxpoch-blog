import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // for reading filepaths
import 'package:flutter_markdown/flutter_markdown.dart'; // markdown rendering
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(Website());
}

// extremely useful for debugging
class BlockingClass extends StatelessWidget {
  const BlockingClass({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.75;

    return Expanded(
      child: Container(height: screenHeight, color: color),
    );
  }
}

class WebsiteState extends ChangeNotifier {}

// the overall app
class Website extends StatelessWidget {
  const Website({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => WebsiteState(),
        child: MaterialApp(
            title: "mxpoch's website",
            theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
                textTheme: GoogleFonts.robotoSlabTextTheme(
                    Theme.of(context).textTheme)),
            home: MainPage()));
  }
}

// holder page
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      children: [
        GreetingCard(),
        Curation(),
      ],
    ));
  }
}

// the actual blog
class Curation extends StatefulWidget {
  const Curation({super.key});

  @override
  State<Curation> createState() => _CurationState();
}

class _CurationState extends State<Curation>
    with SingleTickerProviderStateMixin {
  // initializing the controllers
  late TabController tabController;
  late int tabIndex;
  // initializing the content
  late List<Tuple2<String, Future<String>>> personal;
  late List<Tuple2<String, Future<String>>> professional;
  late List<Tuple2<String, Future<String>>> about;

  // TODO: Fix this workaround when actually implementing the DB
  late Future<String> _pfile1;
  late Future<String> _pfile2;

  late Future<String> _profile1;
  late Future<String> _profile2;

  late Future<String> _about;

  late List<List<Tuple2<String, Future<String>>>> everything;

  late int projectSelector;

  @override
  void initState() {
    super.initState();
    // populating the controllers
    tabController = TabController(length: 3, vsync: this);
    tabIndex = tabController.index;
    tabController.addListener(() {
      setState(() {
        tabIndex = tabController.index;
        projectSelector = 0;
      });
    });
    projectSelector = 0;

    // populating the content
    // once firebase is working, turn this into a loop.
    _pfile2 = getFileData("personal/personal2.md");
    _pfile1 = getFileData("personal/personal.md");

    _profile1 = getFileData("professional/professional.md");
    _profile2 = getFileData("professional/professional2.md");

    _about = getFileData("about/about.md");

    personal = [
      Tuple2<String, Future<String>>("Personal1", _pfile1),
      Tuple2<String, Future<String>>("Personal2", _pfile2)
    ];
    professional = [
      Tuple2<String, Future<String>>("Pro1", _profile1),
      Tuple2<String, Future<String>>("Pro2", _profile2)
    ];
    about = [Tuple2<String, Future<String>>("about", _about)];

    everything = [personal, professional, about];
  }

  // loading the files via path.
  Future<String> getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Navbar(controller: tabController),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Blog(
              tabIndex: tabIndex,
              changeProject: changeProject,
              projectSelector: projectSelector,
              everything: everything),
        )
      ],
    );
  }

  // for the project selector
  changeProject(i) => setState(() {
        projectSelector = i;
      });
}

class PR {
  int selectedProject = 0;
}

// the blog itself
class Blog extends StatefulWidget {
  const Blog(
      {required this.tabIndex,
      required this.changeProject,
      required this.projectSelector,
      required this.everything});

  final int tabIndex;
  final int projectSelector;
  final Function changeProject;
  final List<List<Tuple2<String, Future<String>>>> everything;

  @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
          child: ProjectMenu(
              tabIndex: widget.tabIndex,
              changeProject: widget.changeProject,
              projectSelector: widget.projectSelector,
              everything: widget.everything),
        ),
        BlogViewer(
            tabIndex: widget.tabIndex,
            projectSelector: widget.projectSelector,
            everything: widget.everything),
      ],
    );
  }
}

// where the markdown files are displayed
class BlogViewer extends StatefulWidget {
  const BlogViewer(
      {required this.tabIndex,
      required this.projectSelector,
      required this.everything});

  final List<List<Tuple2<String, Future<String>>>> everything;
  final int projectSelector;
  final int tabIndex;

  @override
  State<BlogViewer> createState() => _BlogViewerState();
}

class _BlogViewerState extends State<BlogViewer> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.25),
                spreadRadius: 3,
                blurRadius: 5,
                offset: Offset(3, 10),
              )
            ]),
        height: MediaQuery.of(context).size.height * 0.75,
        width: MediaQuery.of(context).size.width * 0.5,
        child: FutureBuilder(
          future:
              widget.everything[widget.tabIndex][widget.projectSelector].item2,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("Loading Markdown Info...");
            }
            return Markdown(data: snapshot.data!, selectable: true);
          },
        ));
  }
}

// The interactive project menu
class ProjectMenu extends StatelessWidget {
  ProjectMenu(
      {required this.tabIndex,
      required this.changeProject,
      required this.projectSelector,
      required this.everything});

  // mutable inputs
  List<List<Tuple2<String, Future<String>>>> everything;
  int tabIndex;
  int projectSelector;
  Function changeProject;

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            ColoredSquare(Color.fromARGB(255, 224, 15, 0)),
            ColoredSquare(Color.fromARGB(255, 0, 212, 0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 225, 0),
              child: ColoredSquare(Color.fromARGB(255, 0, 89, 255)),
            ),
          ],
        ),
      ),
      Text("In chronological order: ", style: TextStyle(fontSize: 25)),
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        width: 200,
        child: ListView(
          children: everything[tabIndex]
              .mapIndexed((i, e) => ListTile(
                    title: Text(e.item1),
                    mouseCursor: MaterialStateMouseCursor.clickable,
                    hoverColor: Colors.blue,
                    focusColor: Colors.orange,
                    onTap: () {
                      changeProject(i);
                    },
                  ))
              .toList(),
        ),
      ),
    ]);
  }
}

// major navigation menu
class Navbar extends StatelessWidget {
  const Navbar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
        width: screenWidth * 0.20,
        height: 50,
        child: TabBar(
          splashBorderRadius: BorderRadius.circular(40),
          controller: controller,
          tabs: [
            Tab(text: "Personal"),
            Tab(text: "Professional"),
            Tab(text: "About")
          ],
        ));
  }
}

// The text-based greeting card
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    var desiredWidth = screenWidth * 0.4;
    if (desiredWidth > 500) {
      desiredWidth = 500;
    }
    if (desiredWidth < 400) {
      desiredWidth = 400;
    }

    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(200, 100, 200, 0),
            child: SizedBox(
                width: desiredWidth,
                child: Column(
                  children: [
                    Text(
                      '"I am enough of the artist to draw freely upon my imagination. Imagination is more important than knowledge. Knowledge is limited. Imagination encircles the world."',
                      textAlign: TextAlign.left,
                      style:
                          TextStyle(color: Color.fromARGB(255, 107, 107, 107)),
                    ),
                    Text(
                      "- Einstein explaining why he is so smart.                                            ",
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(color: Color.fromARGB(255, 107, 107, 107)),
                    ),
                  ],
                )),
          ),
        ),
        TitleCard(),
      ],
    );
  }
}

class TitleCard extends StatefulWidget {
  const TitleCard({super.key});

  @override
  State<TitleCard> createState() => _TitleCardState();
}

class _TitleCardState extends State<TitleCard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
          width: 1000,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 200.0, 50, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hey! I'm Maximilian Pochapski",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 55, fontWeight: FontWeight.bold),
                ),
                Text("Blockchain Engineer",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 30, color: Color.fromARGB(255, 99, 99, 99))),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      ColoredSquare(Color.fromARGB(255, 224, 15, 0)),
                      ColoredSquare(Color.fromARGB(255, 0, 212, 0)),
                      ColoredSquare(Color.fromARGB(255, 0, 89, 255)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("I learn to learn to learn.",
                          style: TextStyle(fontSize: 20)),
                      Text(
                          "I spend most of my days grokking things I find interesting (everything) and how to grok better.",
                          style: TextStyle(fontSize: 20)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 50, 0, 50),
                        child: Text("Here are some things I did:",
                            style: TextStyle(fontSize: 20)),
                      )
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }
}

class ColoredSquare extends StatelessWidget {
  final Color color;

  ColoredSquare(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15, // Adjust the size as needed
      height: 15, // Adjust the size as needed
      color: color,
    );
  }
}
