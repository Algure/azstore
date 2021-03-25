import 'package:azstore/constants.dart';
import 'package:azstore/src/azstore_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azstore/azstore.dart';
import 'package:xml/xml.dart';

Future<void> main() async {
//  await testDeleteQ();
//  await testQs();
//  await testCreateQ();
//  await testGetQData();
//  await testPutMessage();
//  await testDeleteMessage();
//  await testUpdateQMessage();
//  await testGetQMessages();
//  await testClearQMessage();
//  await testPeekQMessages();
//  await testUploadTableNode();
//   await testGetTableRow();
//   await testDeleteTableRow();
//   await testFilterTable();
}

Future<void> testDeleteTableRow() async {
  try {
    var storage = AzureStorage.parse(connectionString);
    await storage.deleteTableRow(tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
  }catch(e){
    print('delete exception: $e');
  }
}

Future<void> testFilterTable() async {

  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  List<String> result=await storage.filterTableRows(tableName: 'profiles',
    filter: 'Age%20lt%2024', fields: ['Age','CustomerSince','PartitionKey','RowKey'], top: 10);
  print('showing filter results');
  for(String res in result){
    print(res);
  }
}


Future<void> testUploadTableNode() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    var myPartitionKey="sfsdfsrg57865746";
    var myRowKey='237';
    Map<String, dynamic> rowMap={"Address":"Santa Clara",
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
Future<void> testGetTableRow() async {
  var storage = AzureStorage.parse(connectionString);
  try {
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

Future<void> testDeleteBlob() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.deleteBlob('/azpics/fdblack.png');
    print('done deleting');//Do something else
  }catch(e){
    print('exception: $e');
  }
}

Future<void> testUpdateQMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
   await storage.updateQmessages(
        qName: 'ttable',
      messageId: 'c9aaeea8-4d47-4cf8-a080-250fb218468f',
    popReceipt: 'AgAAAAMAAAAAAAAAzVPboAkg1wE=',
    message: 'testing update: This is an update');
    print('done');
  }catch(e){
    print('delete QM error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testCreateQ() async {
  var storage = AzureStorage.parse(connectionString);
  await storage.createQueue('newer-queue');
}

Future<void> testGetQData() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    String qName='myqueue';
    Map<String, String> result = await storage.getQData(qName);
    print('showing $qName data:\n');
    for (var res in result.entries) {
      print('${res.key}: ${res.value}');
    }
  }catch(e){
    print('get data error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testDeleteQ() async {
  var storage = AzureStorage.parse(connectionString);
  await storage.deleteQueue('newer-queue');
  print('done');
}

Future<void> testGetQList() async {
  var storage = AzureStorage.parse(connectionString);
  List<String> result=await storage.getQList();
  print('showing queue list\n');
  for(String res in result){
    print(res);
  }
}


Future<void> testPutMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.putQMessage(qName:'ttable', message: 'testing expiration');
  }catch(e){
    print('get data error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testGetQMessages() async {
  var storage = AzureStorage.parse(connectionString);
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
    print('Q get messages exception ${e.toString()}');
  }
}

Future<void> testPeekQMessages() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    List<AzureQMessage> result = await storage.peekQmessages(qName: 'ttable');
    print('showing peek results');
    for (var res in result) {
      print('message ${res.messageText}');
    }
  }catch (e){
    print('Q peek messages exception ${e.toString()}');
  }
}

Future<void> testClearQMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.clearQmessages('ttable');
    print('done');
  }catch(e){
    print('delete QM error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testDeleteMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.delQmessages(qName: 'ttable', messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e', popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE=');
    print('done');
  }catch(e){
    print('delete QM error: ${e.statusCode} ${e.message}');
  }
}



