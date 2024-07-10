import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'web_view_container.dart';
import 'atom_pay_helper.dart';
import 'package:http/http.dart' as http;

class Home extends StatelessWidget {
  // merchant configuration data
  final String login = "604902"; //mandatory
  final String login2 = "317159"; //mandatory
  final String password = '31e209db'; //mandatory
  final String password2 = 'Test@123'; //mandatory

  final String prodid = 'UNIBIT'; //mandatory
  final String prodid2 = 'AIPAY'; //mandatory
  final String requestHashKey = 'ab5731c5286815a54a'; //mandatory
  final String requestHashKey2 = 'KEY123657234'; //mandatory
  final String responseHashKey = '1db63e13e91d059823'; //mandatory
  final String responseHashKey2 = 'KEYRESP123657234'; //mandatory
  final String requestEncryptionKey = '743F706A1F94157119C6AD8EB6C7B74D'; //mandatory
  final String requestEncryptionKey2 = 'A4476C2062FFA58980DC8F79EB6A799E'; //mandatory
  final String responseDecryptionKey = '0AEFCDB57EB47EEF45E0086AC9BABEDE'; //mandatory
  final String responseDecryptionKey2 = '75AEF0FA1B94B3C10D4F5B268F757F11'; //mandatory
  final String txnid = 'test${Random().nextInt(900000) + 100000}'; // mandatory // this should be unique each time
  final String txnid2 = 'test${Random().nextInt(900000) + 100000}'; // mandatory // this should be unique each time
  final String clientcode = "NAVIN"; //mandatory
  final String clientcode2 = "NAVIN"; //mandatory
  final String txncurr = "INR"; //mandatory
  final String txncurr2 = "INR"; //mandatory
  final String mccCode = "5816"; //mandatory
  final String mccCode2 = "5816"; //mandatory
  final String merchType = "R"; //mandatory
  final String merchType2 = "R"; //mandatory
  final String amount = "20.00"; //mandatory
  final String amount2 = "20.00"; //mandatory

  final String mode = "production"; // change live for production
  final String mode2 = "production"; // change live for production

  final String custFirstName = 'test'; //optional
  final String custFirstName2 = 'test'; //optional
  final String custLastName = 'user'; //optional
  final String custLastName2 = 'user'; //optional
  final String mobile = '8076090537'; //optional
  final String mobile2 = '8076090537'; //optional
  final String email = 'test@gmail.com'; //optional
  final String email2 = 'test@gmail.com'; //optional
  final String address = 'mumbai'; //optional
  final String address2 = 'mumbai'; //optional
  final String custacc = '639827'; //optional
  final String custacc2 = '639827'; //optional
  final String udf1 = "udf1"; //optional
  final String udf2 = "udf2"; //optional
  final String udf3 = "udf3"; //optional
  final String udf4 = "udf4"; //optional
  final String udf5 = "udf5"; //optional

  // final String authApiUrl = "https://caller.atomtech.in/ots/aipay/auth"; // uat

  final String authApiUrl = "https://payment1.atomtech.in/ots/aipay/auth"; // prod
  final String authApiUrl2 = "https://caller.atomtech.in/ots/aipay/auth"; // prod

  // final String returnUrl =
  //     "https://pgtest.atomtech.in/mobilesdk/param"; //return url uat
  final String returnUrl = "https://payment.atomtech.in/mobilesdk/param"; ////return url production
  final String returnUrl2 = "https://payment.atomtech.in/mobilesdk/param"; ////return url production

  final String payDetails = '';

  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NDPS Sample App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _initNdpsPayment(context, responseHashKey, responseDecryptionKey),
              child: const Text('Open Production'),
            ),
            ElevatedButton(
              onPressed: () => _initNdpsPayment(context, responseHashKey2, responseDecryptionKey2, production: false),
              child: const Text('Open Development'),
            ),
          ],
        ),
      ),
    );
  }

  void _initNdpsPayment(BuildContext context, String responseHashKey, String responseDecryptionKey, {bool production = true}) {
    _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey, production: production);
  }

  _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey, {bool production = true}) async {
    String reqJsonData = "";
    if (production) {
      reqJsonData = _getJsonPayloadData();
    } else {
      reqJsonData = _getJsonPayloadData2();
    }
    Logger().e(reqJsonData);
    debugPrint(reqJsonData);
    const platform = MethodChannel('flutter.dev/NDPSAESLibrary');
    try {
      final String result;
      if (production) {
        result = await platform.invokeMethod('NDPSAESInit', {
          'AES_Method': 'encrypt',
          'text': reqJsonData, // plain text for encryption
          'encKey': requestEncryptionKey // encryption key
        });
      } else {
        result = await platform.invokeMethod('NDPSAESInit', {
          'AES_Method': 'encrypt',
          'text': reqJsonData, // plain text for encryption
          'encKey': requestEncryptionKey2 // encryption key
        });
      }

      String authEncryptedString = result.toString();
      // here is result.toString() parameter you will receive encrypted string
      // debugPrint("generated encrypted string: '$authEncryptedString'");
      _getAtomTokenId(context, authEncryptedString, production: production);
    } on PlatformException catch (e) {
      Logger().e(e);
      debugPrint("Failed to get encryption string: '${e.message}'.");
    }
  }

  _getAtomTokenId(context, authEncryptedString, {bool production = true}) async {
    http.Request request;
    if (production) {
      request = http.Request('POST', Uri.parse(authApiUrl));
    } else {
      request = http.Request('POST', Uri.parse(authApiUrl2));
    }
    request.bodyFields = {'encData': authEncryptedString, 'merchId': login};

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var authApiResponse = await response.stream.bytesToString();
      final split = authApiResponse.trim().split('&');
      Logger().e(authApiResponse);
      final Map<int, String> values = {for (int i = 0; i < split.length; i++) i: split[i]};
      final splitTwo = values[1]!.split('=');
      if (splitTwo[0] == 'encData') {
        const platform = MethodChannel('flutter.dev/NDPSAESLibrary');
        try {
          final String result;

          if (production) {
            result = await platform
                .invokeMethod('NDPSAESInit', {'AES_Method': 'decrypt', 'text': splitTwo[1].toString(), 'encKey': responseDecryptionKey});
          } else {
            result = await platform
                .invokeMethod('NDPSAESInit', {'AES_Method': 'decrypt', 'text': splitTwo[1].toString(), 'encKey': responseDecryptionKey2});
          }
          debugPrint(result.toString()); // to read full response
          var respJsonStr = result.toString();
          Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
          if (jsonInput["responseDetails"]["txnStatusCode"] == 'OTS0000') {
            final atomTokenId = jsonInput["atomTokenId"].toString();
            debugPrint("atomTokenId: $atomTokenId");
            final String payDetails;
            if (production) {
              payDetails =
                  '{"atomTokenId" : "$atomTokenId","merchId": "$login","emailId": "$email","mobileNumber":"$mobile", "returnUrl":"$returnUrl"}';
              _openNdpsPG(payDetails, context, responseHashKey, responseDecryptionKey);
            } else {
              payDetails =
                  '{"atomTokenId" : "$atomTokenId","merchId": "$login2","emailId": "$email2","mobileNumber":"$mobile2", "returnUrl":"$returnUrl2"}';
              _openNdpsPG(payDetails, context, responseHashKey2, responseDecryptionKey2);
            }
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

  _getJsonPayloadData2() {
    var payDetails = {};
    payDetails['login2'] = login2;
    payDetails['password2'] = password2;
    payDetails['prodid2'] = prodid;
    payDetails['custFirstName2'] = custFirstName2;
    payDetails['custLastName2'] = custLastName2;
    payDetails['amount2'] = amount2;
    payDetails['mobile2'] = mobile2;
    payDetails['address2'] = address2;
    payDetails['email2'] = email2;
    payDetails['txnid2'] = txnid2;
    payDetails['custacc2'] = custacc2;
    payDetails['requestHashKey2'] = requestHashKey2;
    payDetails['responseHashKey2'] = responseHashKey2;
    payDetails['requestencryptionKey2'] = requestEncryptionKey2;
    payDetails['responseencypritonKey2'] = responseDecryptionKey2;
    payDetails['clientcode2'] = clientcode2;
    payDetails['txncurr2'] = txncurr2;
    payDetails['mccCode2'] = mccCode2;
    payDetails['merchType2'] = merchType2;
    payDetails['returnUrl2'] = returnUrl2;
    payDetails['mode2'] = mode2;
    payDetails['udf1'] = udf1;
    payDetails['udf2'] = udf2;
    payDetails['udf3'] = udf3;
    payDetails['udf4'] = udf4;
    payDetails['udf5'] = udf5;
    String jsonPayLoadData = getRequestJsonData(payDetails);
    return jsonPayLoadData;
  }
}
