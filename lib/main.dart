import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // markdown rendering
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'dart:convert';

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
            title: "website @mxpoch",
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
        body: ListView(children: [
      GreetingCard(),
      ArrowBox(),
      Curation(),
    ]));
  }
}

class ArrowBox extends StatelessWidget {
  const ArrowBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(3, 10),
                )
              ]),
          height: 40,
          width: MediaQuery.of(context).size.width,
          child:
              SizedBox(height: 20, child: Icon(Icons.arrow_downward_rounded))),
    );
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
  late int projectSelector;
  late Future<http.Response> blogData;

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
        blogData = fetchCurrentTab(tabIndex);
      });
    });
    projectSelector = 0;
    blogData = fetchCurrentTab(tabIndex);
  }

  // fetching the data from the API
  Future<http.Response> fetchCurrentTab(tabIndex) async {
    // setting the right URL
    late String uri;
    switch (tabIndex) {
      case 0:
        uri = "https://mxpoch.com/get_personal.php";
      case 1:
        uri = "https://mxpoch.com/get_professional.php";
      case 2:
        uri = "https://mxpoch.com/get_about.php";
    }

    // fetching the blog data from the API
    http.Response result;
    int numReq = 0;

    // try requesting the blog information multiple times, unless the server is truly unreachable.
    do {
      result = await http.get(Uri.parse(uri), headers: {}).timeout(
          const Duration(seconds: 1),
          onTimeout: () => http.Response('Error', 400));
      numReq += 1;
    } while (result.statusCode != 200 || numReq > 20);
    return result;
  }

  // for the project selector
  changeProject(i) => setState(() {
        projectSelector = i;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Navbar(controller: tabController),
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Blog(
              tabIndex: tabIndex,
              changeProject: changeProject,
              projectSelector: projectSelector,
              blogData: blogData),
        )
      ],
    );
  }
}

// the blog itself
class Blog extends StatefulWidget {
  const Blog(
      {required this.tabIndex,
      required this.changeProject,
      required this.projectSelector,
      required this.blogData});

  final int tabIndex;
  final int projectSelector;
  final Function changeProject;
  final Future<http.Response> blogData;

  @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(160, 0, 0, 0),
          child: ProjectMenu(
              tabIndex: widget.tabIndex,
              changeProject: widget.changeProject,
              projectSelector: widget.projectSelector,
              blogData: widget.blogData),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
          width: MediaQuery.of(context).size.width * 0.07,
        ),
        BlogViewer(
            projectSelector: widget.projectSelector, blogData: widget.blogData),
      ],
    );
  }
}

// where the markdown files are displayed
class BlogViewer extends StatefulWidget {
  const BlogViewer({required this.projectSelector, required this.blogData});

  final Future<http.Response> blogData;
  final int projectSelector;

  @override
  State<BlogViewer> createState() => _BlogViewerState();
}

class _BlogViewerState extends State<BlogViewer> {
  // loading the blogpost
  String getContent(blogData, projectSelect) {
    List<dynamic> allPosts = jsonDecode(blogData.body);
    return allPosts[projectSelect]['content'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            border: Border(
          left: BorderSide(width: 0.5, color: Colors.grey),
          right: BorderSide(width: 0.5, color: Colors.grey),
        )),
        height: MediaQuery.of(context).size.height * 0.75,
        width: MediaQuery.of(context).size.width * 0.45,
        child: FutureBuilder(
            future: widget.blogData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text("Loading blog post...");
              }
              return Markdown(
                data: getContent(snapshot.data!, widget.projectSelector),
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(
                    textTheme: GoogleFonts.poppinsTextTheme(
                            Theme.of(context).textTheme)
                        .copyWith(
                            bodyMedium: GoogleFonts.poppins(fontSize: 14)))),
                extensionSet: md.ExtensionSet(
                  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  <md.InlineSyntax>[
                    md.EmojiSyntax(),
                    ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                  ],
                ),
              );
            }));
  }
}

// The interactive project menu
class ProjectMenu extends StatelessWidget {
  ProjectMenu(
      {required this.tabIndex,
      required this.changeProject,
      required this.projectSelector,
      required this.blogData});

  // mutable inputs
  Future<http.Response> blogData;
  int tabIndex;
  int projectSelector;
  Function changeProject;

  var selectedIndex = 0;

  // loading the blogpost titles
  List<String> getPosts(blogData) {
    List<dynamic> allPosts = jsonDecode(blogData.body);
    // sorting by date
    allPosts.sort((a, b) => a['date'].compareTo(b['date']));
    // extracting the post titles
    List<String> postTitles = [];
    for (var post in allPosts) {
      postTitles.add(post['filename']);
    }
    return postTitles;
  }

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
              padding: const EdgeInsets.fromLTRB(0, 0, 160, 0),
              child: ColoredSquare(Color.fromARGB(255, 0, 89, 255)),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 105),
        child: Text(
          "In order: ",
          style: TextStyle(fontSize: 25),
          textAlign: TextAlign.left,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 70, 0),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            width: 160,
            child: FutureBuilder(
                future: blogData,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text("Waiting for posts to load...");
                  }
                  return ListView(
                    children: getPosts(snapshot.data!)
                        .mapIndexed((i, e) => ListTile(
                              visualDensity:
                                  VisualDensity(horizontal: 0, vertical: -4),
                              title: Text(e,
                                  style: TextStyle(fontFamily: 'RobotoMono')),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              mouseCursor: MaterialStateMouseCursor.clickable,
                              hoverColor: Colors.grey[100],
                              onTap: () {
                                changeProject(i);
                              },
                            ))
                        .toList(),
                  );
                })),
      )
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
                    SelectableText(
                      '"I am enough of the artist to draw freely upon my imagination. Imagination is more important than knowledge. Knowledge is limited. Imagination encircles the world."',
                      textAlign: TextAlign.left,
                      style:
                          TextStyle(color: Color.fromARGB(255, 107, 107, 107)),
                    ),
                    SelectableText(
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
                      SelectableText("I learn to learn to learn.",
                          style: TextStyle(fontSize: 20)),
                      SelectableText(
                          "I spend most of my days grokking things I find interesting (everything) and how to grok better.",
                          style: TextStyle(fontSize: 20)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 50, 0, 60),
                        child: SelectableText("Here are some things I did:",
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
