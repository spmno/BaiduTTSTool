import 'dart:io';

import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: new ThemeData(primaryColor: Colors.white),
      home: TTSWorker(),
    );
  }
}

class _TTSWorkerState extends State<TTSWorker> {
  final Map<String, int> _dropdownMap = const <String, int>{
    "度小美": 0,
    "度小宇": 1,
    "度逍遥": 5003,
    "度小鹿": 5118,
    "度米朵": 103,
    "度小萌": 111,
  };
  var _dropdownValue = "度小美";
  var _textFieldController;
  var stateContext;
  static const convertOnceLength = 60;
  var _convertButton;
  var _isPressed = false;
  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController();
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  void combineMp3(int count) async {
    var command = "ffmpeg ";
    var currentDir = Directory.current.path + r'\temp\';
    for (var i = 1; i <= count; i++) {
      command += ' -i ' + currentDir + i.toString() + r'.mp3';
    }
    command += ' -filter_complex \"';
    for (var i = 0; i < count; i++) {
      command += '[${i.toString()}:0] ';
    }
    command += 'concat=n=$count:v=0:a=1 [a]\" -map [a] output.mp3';
    print(command);
    await Shell().run(command);
  }

  void convertData() async {
    var wholeText = _textFieldController.text;
    //_convertButton.onPressed = null;
    setState(() {
      _isPressed = true;
    });

    print("length: ${wholeText.length}, content: $wholeText");
    if (wholeText.length < 5) {
      return;
    }
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(max: 100, msg: "转换中");
    var step = 100 / (wholeText.length / 60 + 1);
    print("step :$step");
    await prepareEnvironment();
    pd.update(value: 5);
    var convertLength = 0;
    var lastComma = 0;
    var lastFullstop = 0;
    var convertCounter = 1;
    while (convertLength + convertOnceLength < wholeText.length) {
      var lastPosition = convertLength + convertOnceLength;
      var tempString = wholeText.substring(convertLength, lastPosition);
      lastComma = tempString.lastIndexOf('，', convertOnceLength);
      lastFullstop = tempString.lastIndexOf('。', convertOnceLength);
      if ((lastComma == -1) && (lastFullstop == -1)) {
        print("tempString: $tempString");
        print("lastComma: $lastComma, lastFullstop: $lastFullstop");
        showDialogFunction();
        pd.close();
        return;
      }
      var convertPosition = 0;
      (lastComma > lastFullstop)
          ? convertPosition = lastComma
          : convertPosition = lastFullstop;
      var convertContent = tempString.substring(0, convertPosition + 1);
      convertLength += convertPosition + 1;
      print("len: ${convertContent.length}, content: $convertContent");
      var fileName = Directory.current.path +
          r'\temp\' +
          convertCounter.toString() +
          r'.mp3';
      convertCounter++;
      int? role = _dropdownMap[_dropdownValue];
      await convert2mp3(convertContent, fileName, role: role);
      pd.update(value: (step * convertCounter).toInt());
    }
    var convertContent = wholeText.substring(convertLength);
    print("len: ${convertContent.length}, last: $convertContent");
    var fileName = Directory.current.path +
        r'\temp\' +
        convertCounter.toString() +
        r'.mp3';
    int? role = _dropdownMap[_dropdownValue];
    await convert2mp3(convertContent, fileName, role: role);
    combineMp3(convertCounter);
    pd.update(value: 100);
    pd.close();
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    stateContext = context;
    var roles = <DropdownMenuItem<String>>[];
    print('roles length: ${_dropdownMap.keys.length}');
    _dropdownMap.keys.forEach((element) {
      roles.add(DropdownMenuItem(
        child: Text(element),
        value: element,
      ));
    });
    _convertButton = ElevatedButton(
      onPressed: _isPressed ? null : convertData,
      child: Text("开始转换"),
      style: ButtonStyle(),
    );
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: TextField(
                controller: _textFieldController,
                maxLines: 20,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入要转换的文字',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100,
                ),
                Expanded(
                  child: DropdownButton<String>(
                    itemHeight: 80,
                    value: _dropdownValue,
                    hint: Text('请选择人物'),
                    items: roles,
                    onChanged: (value) {
                      print(
                          "change value: ${value.toString()}, v:${_dropdownMap[value]}");
                      setState(() {
                        _dropdownValue = value.toString();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                ),
                SizedBox(
                  width: 400,
                  height: 80,
                  child: _convertButton,
                ),
                SizedBox(
                  width: 100,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void showDialogFunction() async {
    bool? isSelect = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("温馨提示"),
          titlePadding: EdgeInsets.all(10),
          //标题文本样式
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
          //中间显示的内容
          content: Text("这么长的句子没个标点，无法转换?"),
          //中间显示的内容边距
          //默认 EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0)
          contentPadding: EdgeInsets.all(10),
          //中间显示内容的文本样式
          contentTextStyle: TextStyle(color: Colors.black54, fontSize: 14),
          //底部按钮区域
          actions: <Widget>[
            TextButton(
              child: Text("知道了"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );

    print("弹框关闭 $isSelect");
  }
}

class TTSWorker extends StatefulWidget {
  @override
  _TTSWorkerState createState() => _TTSWorkerState();
}
