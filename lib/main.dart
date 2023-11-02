import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(Website());
}

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
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
                textTheme: GoogleFonts.robotoSlabTextTheme(
                    Theme.of(context).textTheme)),
            home: MainPage()));
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        GreetingCard(),
      ],
    ));
  }
}

class WebsiteState extends ChangeNotifier {}

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
                      '"I am enough of the artist to draw freely upon my imagination. Imagination is more important than knowledge. Knowledge is limit. Imagination encircles the world."',
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
                    textAlign: TextAlign.left, style: TextStyle(fontSize: 30)),
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
                      Text("Here are some things I did:",
                          style: TextStyle(fontSize: 20))
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
