import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hivet/models/user.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import 'package:zarinpal/zarinpal.dart';

import 'config.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'VIP Demo',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<User> users = const <User>[
    User(
      name: 'Boy 1',
      description: 'this is boy 1 and its an character',
      level: 2,
      imagePath: 'assets/boy1.png',
      isVIP: false,
    ),
    User(
      name: 'Boy 2',
      description: 'this is boy 2 and its an character',
      level: 4,
      imagePath: 'assets/boy2.png',
      isVIP: false,
    ),
    User(
      name: 'Boy 3',
      description: 'this is boy 3 and its an character',
      level: 7,
      imagePath: 'assets/boy3.png',
      isVIP: true,
    ),
    User(
      name: 'Boy 4',
      description: 'this is boy 4 and its an character',
      level: 4,
      imagePath: 'assets/boy4.png',
      isVIP: false,
    ),
  ];

  PaymentRequest paymentRequest = PaymentRequest();
  String recievedLink = '';
  Map VIPPays = {};

  @override
  void initState() {
    super.initState();
    linkStream.listen((String? link) {
      recievedLink = link!;
      print(recievedLink);
      if (recievedLink.toLowerCase().contains('status')) {
        // https://devdecode.ir/?Authority=000000000000000000000000000001042590&Status=OK
        String status = recievedLink.split('=').last;
        print(status);
        String authority =
            recievedLink.split('?')[1].split('&')[0].split('=')[1];
        print(authority);
        ZarinPal().verificationPayment(status, authority, paymentRequest,
            (isPaymentSuccess, refID, paymentRequest) async {
          if (isPaymentSuccess) {
            Box box = await Hive.openBox('vip');
            Box boxWaiting = await Hive.openBox('waiting-to-pay');

            print((authority));
            box.put(boxWaiting.get(authority.toString()).toString(), 'true');
            setState(() {});
            debugPrint('Success');
          } else {
            debugPrint('Error');
          }
        });
      }
    }, onError: (err) {
      debugPrint(err);
    });
  }

  Future<bool> isNotPayVIP(name) async {
    Box box = await Hive.openBox('vip');
    String isNotPay = box.get(name).toString();
    print(isNotPay);
    return !(isNotPay == 'null'
        ? false
        : isNotPay == 'true'
            ? true
            : false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey,
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: FutureBuilder<bool>(
                future: isNotPayVIP(users[index].name),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  print('snapshot data ${snapshot.data}');
                  return GestureDetector(
                    onTap: () {
                      if (users[index].isVIP && (snapshot.data as bool)) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('VIP'),
                              content: Text(
                                  'This character is VIP. you should pay for see that.'),
                              actions: [
                                ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();

                                      paymentRequest
                                        ..setIsSandBox(true)
                                        ..setAmount(10000)
                                        ..setDescription('payment description')
                                        ..setMerchantID(MERCHENT_ID)
                                        ..setCallbackURL(
                                            'https://payment.devdecode.ir');

                                      ZarinPal().startPayment(paymentRequest,
                                          (status, paymentGatewayUri) async {
                                        Box box = await Hive.openBox(
                                            'waiting-to-pay');
                                        box.put(
                                            paymentRequest.authority.toString(),
                                            users[index].name);
                                        if (status == 100) {
                                          launchUrl(
                                              Uri.parse(paymentGatewayUri!),
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      });
                                    },
                                    child: Text('Pay Now!')),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: width - 40,
                            height: 120,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        users[index].name,
                                        style: TextStyle(fontSize: 30),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Level : ${users[index].level.toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        users[index].description,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 55,
                                  backgroundImage:
                                      AssetImage(users[index].imagePath),
                                ),
                              ],
                            ),
                          ),
                          if (users[index].isVIP &&
                              (snapshot.data as bool)) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  width: width - 20,
                                  height: 120,
                                ),
                              ),
                            ),
                            const Center(
                              child: const Icon(
                                Icons.lock,
                                size: 25,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Box box = await Hive.openBox('vip');
          box.put('Boy 3', 'false');
          setState(() {});
        },
      ),
    );
  }
}
