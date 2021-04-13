import 'package:azstore/azstore.dart';
import 'package:flutter/material.dart';

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
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String _connectionString=  'DefaultEndpointsProtocol=httxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  String _resultText='';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
    );
  }



  Future<void> deleteTableRow() async {
    try {
      var storage = AzureStorage.parse(_connectionString);
      await storage.deleteTableRow(tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
    }catch(e){
      print('delete exception: $e');
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
      print('done uploading');
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
    }catch(e){
      print('tables get exception: $e');
    }
  }

  Future<void> deleteBlob() async {
    var storage = AzureStorage.parse('your connection string');
    try {
      await storage.deleteBlob('/azpics/fdblack.png');
      print('done deleting');//Do something else
    }catch(e){
      print('exception: $e');
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
    }catch(e){
      print('delete QM error: $e');
    }
  }

  Future<void> createQ() async {
    var storage = AzureStorage.parse(_connectionString);
    await storage.createQueue('newer-queue');
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
    }catch(e){
      print('get data error: $e');
    }
  }

  Future<void> deleteQ() async {
    var storage = AzureStorage.parse(_connectionString);
    await storage.deleteQueue('newer-queue');
    print('done');
  }

  Future<void> getQList() async {
    var storage = AzureStorage.parse(_connectionString);
    List<String> result=await storage.getQList();
    print('showing queue list\n');
    for(String res in result){
      print(res);
    }
  }


  Future<void> putMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.putQMessage(qName:'ttable', message: 'testing expiration');
    }catch(e){
      print('get data error: $e');
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
    }catch (e){
      print('Q get messages exception $e');
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
    }catch (e){
      print('Q peek messages exception $e');
    }
  }

  Future<void> clearQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.clearQmessages('ttable');
      print('done');
    }catch(e){
      print('delete QM error: $e');
    }
  }

  Future<void> deleteQMessage() async {
    var storage = AzureStorage.parse(_connectionString);
    print('working on results...');
    try {
      await storage.delQmessages(qName: 'ttable', messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e', popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE=');
      print('done');
    }catch(e){
      print('delete QM error: $e');
    }
  }
}

class MyButton extends StatelessWidget {
  MyButton({this.buttonColor,  required this.text, this.textColor,  this.onPressed});
  Color? buttonColor;
  String text;
  Function()? onPressed;
  Color? textColor;

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
