import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:astro/models/apodModel.dart';
import 'package:astro/providers/apod_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart';

class ApodPage extends StatelessWidget {
  final PageController _pageController = PageController();

  Future<void> datePicker(BuildContext context) async {
    final currentDate = DateTime.now();
    DateTime? dateTime = await showDatePicker(
        context: context,
        initialDate: Provider.of<ApodProvider>(context, listen: false).date,
        firstDate: DateTime(1995, 6, 16, 0, 0),
        lastDate: currentDate,
        cancelText: "Cancel",
        confirmText: "OK");
    if (dateTime != null) {
      _pageController.jumpToPage(currentDate.day - dateTime.day);
    }
  }

  Future<SimpleDialog> _buildApodInfoTranslate(
      Apod apodData, BuildContext context) async {
    final translator = GoogleTranslator();
    var imageInfo = apodData.imageInfo;
    var imageinfo = await translator.translate(imageInfo, from: 'en', to: 'es');
    String imageInfoText = imageinfo.toString();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(title: Text("traducción"), children: [
            SimpleDialogOption(
              child: Text(imageInfoText),
            ),
          ]);
        });
    return const SimpleDialog(title: Text("hola"), children: [
      SimpleDialogOption(
        child: Text("Take Photo"),
      ),
    ]);
  }

  Future<void> _downloadImage(Apod apodData) async {
    /* GallerySaver.saveImage(apodData.imageUrl);*/
  }

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<Box<dynamic>>(context);
    bool isDarkTheme = settings.get('isDarkTheme');
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: PageView.builder(
          controller: _pageController,
          itemBuilder: (BuildContext context, int index) {
            return ChangeNotifierProvider<ApodProvider>(
              create: (context) => ApodProvider(
                date: DateTime.now().subtract(Duration(days: index)),
                responseData: '',
              )..getApodData(),
              builder: (BuildContext context, Widget? widget) {
                final apodProvider = Provider.of<ApodProvider>(context);
                final responseData = apodProvider.responseData;
                if (responseData == null) {
                  return Center(child: CircularProgressIndicator());
                }
                var apodData = Apod.fromMap(json.decode(responseData));

                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildApodTitle(apodData),
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 20.0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Text(apodProvider.getDateString()),
                                ),
                                decoration: BoxDecoration(
                                    border: Border.all(width: 1.5)),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                              ),
                              Text(
                                'Select Date',
                              ),
                              Icon(
                                Icons.calendar_today,
                              ),
                              IconButton(
                                  icon: Icon(isDarkTheme
                                      ? Icons.brightness_7
                                      : Icons.brightness_2),
                                  onPressed: () {
                                    settings.put('isDarkTheme', !isDarkTheme);
                                  })
                            ],
                          ),
                        ),
                        onTap: () async => await datePicker(context),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      _buildApodImage(apodData, context),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                      ),
                      _buildApodInfo(apodData, context),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xff121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      //toolbarHeight: 100.0,
      centerTitle: true,
      title: Text(
        'Astronomy Picture of the Day',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Colors.white, fontSize: 20.0),
        ),
      ),
    );
  }

  Padding _buildApodTitle(Apod apodData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
      child: Text(
        apodData.imageTitle,
        style: GoogleFonts.montserrat(
          textStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 30.0,
          ),
        ),
      ),
    );
  }

  Container _buildApodImage(Apod apodData, BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: apodData.imageUrl != null
            ? Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: apodData.imageUrl,
                  ),
                  TextButton(
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all(Colors.blue)),
                    onPressed: () async => await _downloadImage(apodData),
                    child: Text("descargar"),
                  )
                ],
              )
            : apodData.mediaType == "video"
                ? Text("image is not available")
                : Container(
                    width: MediaQuery.of(context).size.width,
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 300.0,
                          child: Shimmer.fromColors(
                            baseColor: Color.fromARGB(255, 183, 179, 179),
                            highlightColor: Color.fromARGB(255, 245, 245, 245),
                            child: Container(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Padding _buildApodInfo(Apod apodData, BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            Text(
              apodData.imageInfo,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 20.0,
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.blue)),
              onPressed: () async =>
                  await _buildApodInfoTranslate(apodData, context),
              child: Text("Traducir"),
            )
          ],
        ));
  }
}
