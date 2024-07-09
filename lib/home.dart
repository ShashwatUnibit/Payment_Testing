import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'web_view_container.dart';
import 'atom_pay_helper.dart';
import 'package:http/http.dart' as http;

class Home extends StatelessWidget {
  // merchant configuration data
  final String login = "604902"; //mandatory
  final String password = '31e209db'; //mandatory

  final String prodid = 'UNIBIT'; //mandatory
  final String requestHashKey = 'ab5731c5286815a54a'; //mandatory
  final String responseHashKey = '1db63e13e91d059823'; //mandatory
  final String requestEncryptionKey = '743F706A1F94157119C6AD8EB6C7B74D'; //mandatory
  final String responseDecryptionKey = '0AEFCDB57EB47EEF45E0086AC9BABEDE'; //mandatory
  final String txnid = 'test${Random().nextInt(900000) + 100000}'; // mandatory // this should be unique each time
  final String clientcode = "NAVIN"; //mandatory
  final String txncurr = "INR"; //mandatory
  final String mccCode = "5816"; //mandatory
  final String merchType = "R"; //mandatory
  final String amount = "20.00"; //mandatory

  final String mode = "production"; // change live for production

  final String custFirstName = 'test'; //optional
  final String custLastName = 'user'; //optional
  final String mobile = '8076090537'; //optional
  final String email = 'test@gmail.com'; //optional
  final String address = 'mumbai'; //optional
  final String custacc = '639827'; //optional
  final String udf1 = "udf1"; //optional
  final String udf2 = "udf2"; //optional
  final String udf3 = "udf3"; //optional
  final String udf4 = "udf4"; //optional
  final String udf5 = "udf5"; //optional

  // final String authApiUrl = "https://caller.atomtech.in/ots/aipay/auth"; // uat

  final String authApiUrl = "https://payment1.atomtech.in/ots/aipay/auth"; // prod

  // final String returnUrl =
  //     "https://pgtest.atomtech.in/mobilesdk/param"; //return url uat
  final String returnUrl = "https://payment.atomtech.in/mobilesdk/param"; ////return url production

  final String payDetails = '';

  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NDPS Sample App'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _initNdpsPayment(context, responseHashKey, responseDecryptionKey),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }

  void _initNdpsPayment(BuildContext context, String responseHashKey, String responseDecryptionKey) {
    _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey);
  }

  _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey) async {
    String reqJsonData = _getJsonPayloadData();
    debugPrint(reqJsonData);
    const platform = MethodChannel('flutter.dev/NDPSAESLibrary');
    try {
      final String result = await platform.invokeMethod('NDPSAESInit', {
        'AES_Method': 'encrypt',
        'text': reqJsonData, // plain text for encryption
        'encKey': requestEncryptionKey // encryption key
      });
      String authEncryptedString = result.toString();
      // here is result.toString() parameter you will receive encrypted string
      // debugPrint("generated encrypted string: '$authEncryptedString'");
      _getAtomTokenId(context, authEncryptedString);
    } on PlatformException catch (e) {
      debugPrint("Failed to get encryption string: '${e.message}'.");
    }
  }

  _getAtomTokenId(context, authEncryptedString) async {
    var request = http.Request('POST', Uri.parse(authApiUrl));
    request.bodyFields = {'encData': authEncryptedString, 'merchId': login};

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var authApiResponse = await response.stream.bytesToString();
      final split = authApiResponse.trim().split('&');
      print(authApiResponse);
      final Map<int, String> values = {for (int i = 0; i < split.length; i++) i: split[i]};
      final splitTwo = values[1]!.split('=');
      if (splitTwo[0] == 'encData') {
        const platform = MethodChannel('flutter.dev/NDPSAESLibrary');
        try {
          final String result =
              await platform.invokeMethod('NDPSAESInit', {'AES_Method': 'decrypt', 'text': splitTwo[1].toString(), 'encKey': responseDecryptionKey});
          debugPrint(result.toString()); // to read full response
          var respJsonStr = result.toString();
          Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
          if (jsonInput["responseDetails"]["txnStatusCode"] == 'OTS0000') {
            final atomTokenId = jsonInput["atomTokenId"].toString();
            debugPrint("atomTokenId: $atomTokenId");
            final String payDetails =
                '{"atomTokenId" : "$atomTokenId","merchId": "$login","emailId": "$email","mobileNumber":"$mobile", "returnUrl":"$returnUrl"}';
            _openNdpsPG(payDetails, context, responseHashKey, responseDecryptionKey);
          } else {
            debugPrint("Problem in auth API response");
          }
        } on PlatformException catch (e) {
          debugPrint("Failed to decrypt: '${e.message}'.");
        }
      }
    }
  }

  _openNdpsPG(payDetails, context, responseHashKey, responseDecryptionKey) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewContainer(mode, payDetails, responseHashKey, responseDecryptionKey)));
  }

  _getJsonPayloadData() {
    var payDetails = {};
    payDetails['login'] = login;
    payDetails['password'] = password;
    payDetails['prodid'] = prodid;
    payDetails['custFirstName'] = custFirstName;
    payDetails['custLastName'] = custLastName;
    payDetails['amount'] = amount;
    payDetails['mobile'] = mobile;
    payDetails['address'] = address;
    payDetails['email'] = email;
    payDetails['txnid'] = txnid;
    payDetails['custacc'] = custacc;
    payDetails['requestHashKey'] = requestHashKey;
    payDetails['responseHashKey'] = responseHashKey;
    payDetails['requestencryptionKey'] = requestEncryptionKey;
    payDetails['responseencypritonKey'] = responseDecryptionKey;
    payDetails['clientcode'] = clientcode;
    payDetails['txncurr'] = txncurr;
    payDetails['mccCode'] = mccCode;
    payDetails['merchType'] = merchType;
    payDetails['returnUrl'] = returnUrl;
    payDetails['mode'] = mode;
    payDetails['udf1'] = udf1;
    payDetails['udf2'] = udf2;
    payDetails['udf3'] = udf3;
    payDetails['udf4'] = udf4;
    payDetails['udf5'] = udf5;
    String jsonPayLoadData = getRequestJsonData(payDetails);
    return jsonPayLoadData;
  }
}
