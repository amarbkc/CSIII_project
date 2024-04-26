
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_tracker/screens/home.dart';
import 'package:price_tracker/screens/login.dart';


TextField reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType,
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: Colors.white,
    style: TextStyle(color: Colors.white.withOpacity(0.9)),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.white70,
      ),
      labelText: text,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

Container firebaseUIButton(BuildContext context, String title, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black26;
            }
            return Colors.white;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
    ),
  );
}

Container item(BuildContext context, String base64, String itemTopic,double iPrice, double cPrice,double tPrice){
  return Container(
    child: Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        height: 100,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: cPrice < tPrice? Colors.greenAccent:Colors.white12,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage(base64),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    truncateStringBasedOnScreen(itemTopic,context),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,

                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        Column(
                          children: [
                            Text(
                              "Initial Price",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "\$" + iPrice.toString(),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          children: [
                            Text(
                              "Current Price",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "\$" + cPrice.toString(),
                              style: TextStyle(
                                color: iPrice >= cPrice ? Colors.green : Colors.red,
                              ),
                            )
                          ],

                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          children: [
                            Text(
                              "Your Price",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "\$" + tPrice.toString(),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            )
                          ],


                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),

      ),
    ),
  );

}


Future<void> showAddNewProductPrompt(BuildContext context) async {
  final urlController = TextEditingController();
  final priceController = TextEditingController();

  String? _errorMessage;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(
          child: Text(
            'Add New Product',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Color.fromRGBO(255, 255, 255, 0.9),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            TextField(
              controller: urlController,
              cursorColor: Colors.black,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                labelText: 'Enter Product URL',
                labelStyle: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  labelText: 'Your Desired Price',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  )),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
                  Navigator.pop(context);
                },


            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final String apiUrl = 'http://hm.oznepalservices.com.au/api/scrape/';

              final Map<String, dynamic> postData = {
                'url': urlController.text,
                'user' : FirebaseAuth.instance.currentUser!.uid.toString(),
                'price': priceController.text,
              };

              print(postData.toString());

              final response = await http.post(
                Uri.parse(apiUrl),
                body: jsonEncode(postData),
                headers: {'Content-Type': 'application/json'},
              );

              if (response.statusCode == 200) {
                // Successfully added new product
                Navigator.pop(context);
              } else {
                // Handle error
               print("response code : " + response.statusCode.toString());
               print("response body : " + response.body);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      );
    },
  );
}

String truncateStringBasedOnScreen(String text, BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width-220;

  // Calculate the width of '...'
  final TextPainter ellipsisPainter = TextPainter(
    text: TextSpan(text: '...'),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaleFactor: MediaQuery.of(context).textScaleFactor,
    locale: Localizations.localeOf(context),
  )..layout(minWidth: 0, maxWidth: double.infinity);

  final double ellipsisWidth = ellipsisPainter.width;

  // Calculate the width of the text
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaleFactor: MediaQuery.of(context).textScaleFactor,
    locale: Localizations.localeOf(context),
  )..layout(minWidth: 0, maxWidth: double.infinity);

  final double textWidth = textPainter.width;

  final int maxLength = ((screenWidth - ellipsisWidth) / textWidth * text.length).floor();

  if (text.length <= maxLength) {
    return text;
  } else {
    return text.substring(0, maxLength - 3) + '...';
  }
}


