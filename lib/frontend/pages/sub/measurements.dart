
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ovulize/globals.dart';
import 'package:package_info/package_info.dart';

class Measurements extends StatefulWidget {
  const Measurements({super.key});



  @override
  State<Measurements> createState() => MeasurementsState();
}

class MeasurementsState extends State<Measurements> {

  @override
  void initState() {
    super.initState();

  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(LineIcons.alternateLongArrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Informationen"
          
        ),
        foregroundColor: Colors.black,
        backgroundColor: barColor,
      ),
      body: SingleChildScrollView(
        child: SizedBox(
            child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                  child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.asset(
                      "assets/images/logo_font_primary.png",
                      width: 100,
                      height: 100,
                    ),
                  ),
                  FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              Text(
                                "Version " +
                                    snapshot.data!.version +
                                    " (" +
                                    snapshot.data!.buildNumber +
                                    ")",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),),
                                    Text("5. PK von Henri Stimm",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey))
                              
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Text("ovulize",
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text(
                                "Version N/A",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              ),
                            ],
                          );
                        }
                      })
                ],
              )),
              SizedBox(
                height: 10,
              ),
              settingTile(
                  "Vergangene Messungen",
                  () {
                    
                  }),

              settingTile(
                  "Impressum",
                  () {

                  }),
            ],
          ),
        )),
      ),
    );
  }

  Widget settingTile(String title, Function() onClick, {bool isNew = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: backgroundOverlayColor,
        title: Row(
          children: [
            Text(
              title,
              style:
                  TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 13),
            ),
            SizedBox(
              width: 5,
            ),
            Visibility(
              visible: isNew,
              child: Container(
                height: 14,
                width: 30,
                alignment: Alignment.center,
                margin: EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  "NEU",
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.8), fontSize: 8),
                ),
              ),
            )
          ],
        ),
        trailing: Icon(
          LineIcons.alternateLongArrowRight,
          size: 15,
          color: Colors.black.withOpacity(0.8),
        ),
        onTap: onClick,
      ),
    );
  }
}
