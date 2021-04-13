import 'dart:io';
import 'dart:typed_data';

import 'package:azstore/azstore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Azstore Demo App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key,  this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _picker= ImagePicker();
  final navTextStyle=TextStyle(
      color: Colors.white,
      fontSize: 14
  );

  String _connectionString=  'DefaultEndpointsProtocol=httxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  String _resultText='';
  bool _progress=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ModalProgressHUD (
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Push button to test function:',
              ),
              ListView(
                shrinkWrap: true,

                children: [
                  MyButton(text: 'Upload table node', buttonColor: Colors.blue, onPressed: uploadTableNode,),
                  MyButton(text: 'Delete table row', buttonColor: Colors.red, onPressed: deleteTableRow,),
                  MyButton(text: 'Filter tables',buttonColor: Colors.green, onPressed: filterTable,),
                  MyButton(text: 'Get table row', onPressed: getTableRow,),
                  MyButton(text: 'Put blob image',buttonColor: Colors.blue, onPressed: uploadBlobImage,),
                  MyButton(text: 'Delete blob', buttonColor: Colors.red,onPressed: deleteBlob,),
                  MyButton(text: 'Create Queue',buttonColor: Colors.blue, onPressed: createQ,),
                  MyButton(text: 'Get Queue Data',buttonColor: Colors.green, onPressed: getQData,),
                  MyButton(text: 'Insert queue message',buttonColor: Colors.blue, onPressed: putQMessage,),
                  MyButton(text: 'Delete Queue', buttonColor: Colors.red,onPressed: deleteQ,),
                  MyButton(text: 'Get Queue list', buttonColor: Colors.green, onPressed: getQList,),
                  MyButton(text: 'Get all queue messages',buttonColor: Colors.green, onPressed: clearQMessage,),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteTableRow() async {
    try {
      var storage = AzureStorage.parse(_connectionString);
      await storage.deleteTableRow(tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
      // showInfoDialog(context, 'Delete Success');//Optional prompt
    }catch(e){
      print('delete exception: $e');
      // showErrorDialog(context, e.toString());//ALTERNATIVE PROMPT
    }
  }

  Future<void> filterTable() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    List<String> result=await storage.filterTableRows(tableName: 'profiles',
        filter: 'Age%20lt%2024', fields: ['Age','CustomerSince','PartitionKey','RowKey'], top: 10);
    print('showing filter results');
    for(String res in result){
      print(res);
    }
    // showInfoDialog(context, 'Success');//Optional prompt
  }

  Future<void> uploadTableNode() async {
    var storage = AzureStorage.parse(_connectionString);
    try {
      var myPartitionKey="sfsdfsrg57865746";
      var myRowKey='237';
      Map<String, dynamic> rowMap={
        "Address":"Santa Clara",
        "Age":23,
        "AmountDue":200.23,
        "CustomerCode@odata.type":"Edm.Guid",
        "CustomerCode":"c9da6455-213d-42c9-9a79-3e9149a57833",
        "CustomerSince@odata.type":"Edm.DateTime",
        "CustomerSince":"2008-07-10T00:00:00",
        "IsActive":false,
        "NumberOfOrders@odata.type":"Edm.Int64",
        "NumberOfOrders":"255",
        "PartitionKey":"$myPartitionKey",
        "RowKey":"$myRowKey"
      };
      await storage.upsertTableRow(
          tableName: 'profiles',
          rowKey:myRowKey,
          partitionKey: myPartitionKey,
          bodyMap: rowMap
      );
      // showInfoDialog(context, 'Success');//Optional prompt
    }catch(e){
      print('tables upsert exception: $e');
    }
  }

  Future<void> getTableRow() async {
    try {
      var storage = AzureStorage.parse(_connectionString);
      var myPartitionKey="fgtdssdas";
      var myRowKey='232';
      String result=await storage.getTableRow(
          tableName: 'profiles',
          partitionKey:myPartitionKey,
          rowKey:myRowKey,
          fields: ['Address','CustomerSince']
      );
      print('result: $result');
      // showInfoDialog(context, 'Success');
    }catch(e){
      print('tables get exception: $e');
    }
  }

  Future<void> deleteBlob() async {
    var storage = AzureStorage.parse('your connection string');
    try {
      await storage.deleteBlob('/azpics/fdblack.png');
      // showInfoDialog(context, 'Delete Success');//Optional prompt
    }catch(e){
      print('exception: $e');
      // showErrorDialog(context, '$e');//Optional prompt

    }
  }

  Future<void> updateQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.updateQmessages(
          qName: 'ttable',
          messageId: 'c9aaeea8-4d47-4cf8-a080-250fb218468f',
          popReceipt: 'AgAAAAMAAAAAAAAAzVPboAkg1wE=',
          message: 'testing update: This is an update');
      print('done');
      // showInfoDialog(context, ' Success');//Optional prompt
    }catch(e){
      print('delete QM error: $e');
      // showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<void> createQ() async {
    var storage = AzureStorage.parse(_connectionString);
    await storage.createQueue('newer-queue');
    // showInfoDialog(context, 'Create success');//Optional prompt
  }

  Future<void> getQData() async {
    var storage = AzureStorage.parse(_connectionString);
    try {
      String qName='myqueue';
      Map<String, String> result = await storage.getQData(qName);
      print('showing $qName data:\n');
      for (var res in result.entries) {
        print('${res.key}: ${res.value}');
      }
      // showInfoDialog(context, 'Success');//Optional prompt
    }catch(e){
      print('get data error: $e');
      // showErrorDialog(context, e.toString());
    }
  }

  Future<void> deleteQ() async {
    var storage = AzureStorage.parse(_connectionString);
    await storage.deleteQueue('newer-queue');
    print('done');
    // showInfoDialog(context, 'Success');//Optional prompt
  }

  Future<void> getQList() async {
    var storage = AzureStorage.parse(_connectionString);
    List<String> result=await storage.getQList();
    print('showing queue list\n');
    for(String res in result){
      print(res);
    }
    // showInfoDialog(context, 'Success');//Optional prompt
  }

  Future<void> putQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.putQMessage(qName:'ttable', message: 'testing expiration');
      showInfoDialog(context, 'Success');//Optional prompt
    }catch(e){
      print('get data error: $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<void> getQMessages() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      List<AzureQMessage> result = await storage.getQmessages(qName: 'ttable',//Required
          numOfmessages: 10//Optional. Number of messages to retrieve. This package returns top 20 filter results when not specified.
      );
      print('showing results');
      for (var res in result) {
        print('message ${res}');
      }
      showInfoDialog(context, 'Success');//Optional prompt

    }catch (e){
      print('Q get messages exception $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<void> peekQMessages() async {
    var storage = AzureStorage.parse(_connectionString);
    try {
      List<AzureQMessage> result = await storage.peekQmessages(qName: 'ttable');
      print('showing peek results');
      for (var res in result) {
        print('message ${res.messageText}');
      }
      showInfoDialog(context, 'Success');//Optional prompt
    }catch (e){
      print('Q peek messages exception $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<void> clearQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.clearQmessages('ttable');
      print('done');
      showInfoDialog(context, 'Success');//Optional prompt
    }catch(e){
      print('delete QM error: $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<void> deleteQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.delQmessages(qName: 'ttable', messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e', popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE=');
      print('done');
      showInfoDialog(context, 'Success');//Optional prompt
    }catch(e){
      print('delete QM error: $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  uploadBlobImage() async {
    try {
      showProgress(true);
      PickedFile tempFile = await _picker.getImage(source: ImageSource.gallery);
      assert(tempFile!=null);
      String compressedPath = await compressImage(
          File(tempFile!=null?tempFile.path:'').absolute.path);
      Uint8List bytes = File(compressedPath).readAsBytesSync();
      var storage = AzureStorage.parse(_connectionString);
      var picId=getUniqueIdWPath(compressedPath);
      await storage.putBlob('/gmart-pics/$picId.jpg',
        bodyBytes: bytes,
        contentType: 'image/png',
      );
      showInfoDialog(context, 'Success');//Optional prompt
      showProgress(false);
    }catch(e){
      showProgress(false);
      print('An error occured. Error: $e');
      showErrorDialog(context, e.toString());//Optional prompt
    }
  }

  Future<String> compressImage(String imagePath) async {
    final directory= await getApplicationDocumentsDirectory();
    String path= directory.path+'/my_app_pics';
    if(!Directory(path).existsSync()) await Directory(path).create();
    String fileId=getUniqueIdWPath(imagePath);
    path+='/$fileId.jpg';
    File newFile=File(path);
    await newFile.create();
    File compressionFile= await FlutterImageCompress.compressAndGetFile(imagePath, path, quality: 25, rotate: 0);
    return compressionFile.path;
  }
  
  void showInfoDialog(BuildContext context, String text){
    showCustomDialog(context: context, icon:Icons.info, iconColor: Colors.blue, text: text );
  }
  
  void showErrorDialog(BuildContext context, String errorText){
    showCustomDialog(context: context, icon:Icons.warning, iconColor: Colors.red, text: errorText );
  }
  
  void showCustomDialog({ BuildContext context,  IconData icon,  Color iconColor,  String text, List buttonList}){
    List<Widget> butList=[];
    if(buttonList!=null && buttonList.length>0){
      for(var arr in buttonList){
        butList.add(Expanded(
          child: Container(
            margin: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
                color: arr[1],
                borderRadius: BorderRadius.circular(20)
            ),
            child: FlatButton(onPressed: arr[2],
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Text(arr[0], style: navTextStyle,),
              ),
              splashColor: Colors.white,),
          ),
        ));
      }
    }
    Dialog errorDialog= Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: Container(
        height: 350,
        child: Column(
          children: [
            Expanded(child: Icon(icon, color: iconColor, size: 200,)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
            ),
            SizedBox(height: 20,),
            Container(
              height: butList!=null?50:2,
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: buttonList!=null?butList:[],
              ),
            )
          ],
        ),
      ),
    );
    showGeneralDialog(context: context,
        barrierLabel: text,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: Duration(milliseconds: 500),
        transitionBuilder: (_, anim, __, child){
          return SlideTransition(position: Tween(begin: Offset(-1,0), end: Offset(0,0)).animate(anim), child: child,);
        },
        pageBuilder: (BuildContext context, _, __)=>(errorDialog)
    );
  }

  String getUniqueIdWPath(String path) {
    List unis=path.split('/');
    return unis[unis.length-1].split('.')[0];
  }

  void showProgress(bool bool) {
    setState(() {
      _progress=true;
    });
  }

}

class MyButton extends StatelessWidget {
  MyButton({this.buttonColor,   this.text, this.textColor,  this.onPressed});
  Color buttonColor;
  String text;
  Function() onPressed;
  Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: buttonColor??Colors.black,
          borderRadius: BorderRadius.circular(5)
      ),
      child: TextButton(onPressed:this.onPressed??(){},
        child: Text(text, style: TextStyle(color: textColor??Colors.white),),),
    );
  }
}
