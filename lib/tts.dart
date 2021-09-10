import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:io';

var appKey = 'Nk1xQzvhn9xydoWrmYKtdn6K';
var appSecretKey = 'tAz7eaiNlurKGaOhPtdj3G4pZ7sG7mfw';
var openTokenUrl =
    'https://openapi.baidu.com/oauth/2.0/token?grant_type=client_credentials&client_id=$appKey&client_secret=$appSecretKey';

var cuid = 'ffff000011119999';
var ctp = 1;
var lan = 'zh';
var spd = 5;
var per = 5;
var aue = 3;
const tempDirString = r'\temp';

var tex = '关门山国家森林公园位于本溪市东南70公里处，森林公园占地3517公顷，海拔310米—1234米，森林覆盖率85%。';
var accessToken = "";

Future<bool> convert2mp3(String content, String fileName,
    {int? role = 0}) async {
  print("fileName: $fileName");

  var postUrlString = 'https://tsn.baidu.com/text2audio';
  var bodyParam =
      'tex=$content&lan=$lan&cuid=$cuid&ctp=$ctp&aue=$aue&tok=$accessToken&per=$role';
  var postUrl = Uri.parse(postUrlString);
  var postResponse = await http.post(postUrl, body: bodyParam);
  if (postResponse.statusCode != 200) {
    print('post request failed');
    return false;
  }
  print('content-type: ${postResponse.headers['content-type']}');
  print('body len: ${postResponse.body.length}');
  File mp3File = new File(fileName);
  await mp3File.writeAsBytes(postResponse.bodyBytes);
  return true;
}

Future<bool> prepareEnvironment() async {
  var tempPath = Directory.current.path + tempDirString;
  final tempDir = Directory(tempPath);
  var isThere = await tempDir.exists();
  if (isThere) {
    await tempDir.delete(recursive: true);
  }
  await tempDir.create();
  var result = File('output.mp3');
  if (await result.exists()) {
    await result.delete();
  }
  var url = Uri.parse(openTokenUrl);
  var response = await http.get(url);
  if (response.statusCode != 200) {
    print('get token failed');
    return false;
  }
  var jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
  print(jsonResponse);
  accessToken = jsonResponse['access_token'];
  return true;
}
