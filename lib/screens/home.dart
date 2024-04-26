import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase_api.dart';
import '../item.dart';
import '../reusableWidgets/reusableWidgets.dart';
import 'login.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({Key? key}) : super(key: key);

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();

      // 1. This method call when app in terminated state and you get a notification

      FirebaseMessaging.instance.getInitialMessage().then(
            (message) {
          print("FirebaseMessaging.instance.getInitialMessage");
          if (message != null) {
            LocalNotificationService.createanddisplaynotification(message);
          }
        },
      );

      // 2. This method only call when App in forground it mean app must be opened
      FirebaseMessaging.onMessage.listen(
            (message) {
          print("FirebaseMessaging.onMessage.listen");
          if (message.notification != null) {
            print(message.notification!.title);
            print(message.notification!.body);
            print("message.data11 ${message.data}");
            LocalNotificationService.createanddisplaynotification(message);

          }
        },
      );

      // 3. This method only call when App in background and not terminated(not closed)
      FirebaseMessaging.onMessageOpenedApp.listen(
            (message) {
          print("FirebaseMessaging.onMessageOpenedApp.listen");
          if (message.notification != null) {
            print(message.notification!.title);
            print(message.notification!.body);
            print("message.data22 ${message.data['_id']}");
          }
        },
      );
    }


  Future<void> _refreshProducts() async {
    setState(() {
      futureProducts = fetchProducts();
    });
  }



  Future<List<Product>> fetchProducts() async {
    String api = 'http://hm.oznepalservices.com.au/api/products/?user=' + FirebaseAuth.instance.currentUser!.uid.toString();
    print("Fetching form api : "+api);
    final response = await http.get(Uri.parse(api));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Product.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your list of Items',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color.fromRGBO(8, 16, 39, 1),
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton(
              child: Icon(
                Icons.account_circle_rounded,
                size: 45,
                color: Colors.white,
              ),
              color: Color.fromRGBO(39, 47, 75, 1),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "Change Password",
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.settings, color: Colors.white),
                      ),
                      const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "Log Out",
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.logout, color: Colors.white),
                      ),
                      const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == "Log Out") {
                  String userid = FirebaseAuth.instance.currentUser!.uid.toString();
                  FirebaseAuth.instance.signOut().then((value) async {
                    final String apiUrl = 'http://hm.oznepalservices.com.au/api/register/';
                    final fcmTkn = await FirebaseApi().getFCMToken();
                    final Map<String, dynamic> postData = {
                      'user' : userid,
                      'token':fcmTkn.toString(),
                      'status' : "logout"
                    };

                    final response =  http.post(
                      Uri.parse(apiUrl),
                      body: jsonEncode(postData),
                      headers: {'Content-Type': 'application/json'},
                    );

                    final storage = FlutterSecureStorage();
                    await storage.write(key: 'is_logged_in', value: 'false');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => loginScreen()));
                  });
                }
              },
            ),
          ],
        ),

        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Color.fromRGBO(18, 26, 59, 1)),
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 0),
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: FutureBuilder<List<Product>>(
                future: futureProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print('Error : ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.data!.isEmpty) {
                    return Center(child: Text('No items available'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final Product = snapshot.data![index];
                        return InkWell( // Use InkWell to make the item clickable
                          onTap: () => _launchURL(Product.url), // Launch URL when item is clicked
                          child: Dismissible(
                             key: Key(Product.name), // Unique key for each product
                             background: Container(
                               color: Colors.red,
                               child: Icon(Icons.delete, color: Colors.white),
                               alignment: Alignment.centerRight,
                               padding: EdgeInsets.only(right: 20.0),
                             ),
                             onDismissed: (direction) async {
                               final String Durl = 'http://hm.oznepalservices.com.au/api/products/delete/';
                               final Map<String, dynamic> pID = {
                                'id': Product.id.toString(),
                               };

                               try {
                                 final response = await http.post(
                                   Uri.parse(Durl),
                                   body: jsonEncode(pID),
                                   headers: {'Content-Type': 'application/json'},
                                 );

                                 if (response.statusCode == 200) {
                                   print('Product with ID deleted successfully');
                                 } else {
                                   print("error code : " + response.statusCode.toString());
                                   print('Failed to delete product: ${response.reasonPhrase}');
                                 }
                               } catch (error) {
                                 print('Error: $error');
                               }
                               },
                            child: item(
                              context,
                              Product.image,
                              Product.name,
                              double.parse(Product.price.substring(1)),
                              double.parse(Product.currentPrice.substring(1)),
                              double.parse(Product.targetPrice),
                            ),
                          ),
                        );
                        },
                    );
                  }
                },
              ),
            ),
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(39, 47, 75, 1),
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          child: const Icon(Icons.add),
          onPressed: () async {
             await showAddNewProductPrompt(context);
             _refreshProducts();
          },
        ),
      ),

    );


  }

  _launchURL(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }


}
