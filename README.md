# azstore

[![license](https://img.shields.io/badge/license-MIT-success.svg?style=flat-square)](https://github.com/Algure/azstore/blob/master/LICENSE)
[![pub package](https://img.shields.io/pub/v/azstore.svg?color=success&style=flat-square)](https://pub.dartlang.org/packages/azstore)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-success.svg?style=flat-square)](https://github.com/Algure/azstore/pulls)

Access azure storage options via REST APIs.

## Getting Started

This package handles all the encryption and formatting required to provide easy access to azure storage options via REST APIs in a flutter project.
The package currently provides functions to query and upload data to Azure blobs, tables and queues.

## 🎖 Installing

```yaml
dependencies:
  azstore: ^latest_version
```

### ⚡️ Import

```dart
import 'package:azstore/azstore.dart';
```

## 🎮 How To Use
> Get your connection string from the azure portal after simply creating a storage account (you can follow the walkthrough in the section [Creating Azure Storage Account](#creating-azure-storage-account))

### Azure Blob Functions.

Azure blob allows storage of unstructured data in containers.

Typical use cases are shown below.

```dart
Future<void> testUploadImage() async {
  File testFile =File('C:/Users/HP/Pictures/fdblack.png');
  Uint8List bytes = testFile.readAsBytesSync();
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.putBlob('/azpics/fdblack.png',
      bodyBytes: bytes,//Text can be uploaded to 'blob' in which case body parameter is specified instead of 'bodyBytes'
      contentType: 'image/png',
    );
  }catch(e){
    print('exception: $e');
  }
}
```

Delete blob operations can also be performed as shown.

```dart
Future<void> testDeleteBlob() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.deleteBlob('/azpics/fdblack.png');
    print('done deleting');
  }catch(e){
    print('exception: $e');
  }
}
```

Also explore the         `appendBlock`, `createContainer` and `deleteContainer`  functions.

### Table Storage Functions

The Azure Table service offers structured NoSQL storage in the form of tables.
Tables can be managed using the         `createTable`,`deleteTable`         and         `getTables`          functions.
Table nodes/rows can be controlled using other functions  such as         `upsertTableRow`,`putTableRow`,`getTableRow` and `deleteTableRow`.

The following snippets show the use of some table access functions. Also refer to the [Azure Tables docs](https://docs.microsoft.com/en-us/rest/api/storageservices/payload-format-for-table-service-operations/) for allowed data types to insert in a table row.
The code documentation provides further help.


Use `upsertTableRow` when updating or adding new table row and `putTableRow` to replace or add a new row.

```dart
Future<void> testUpload2Table() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    var myPartitionKey='partition_key';
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
        bodyMap: rowMap
     );
  }catch(e){
    print('tables upsert exception: $e');
  }
}

```

Specific Table rows can be retrieved using `getTableRow` function as shown below. Filters can also be used to retrieve a list of table rows by using the `filterTableRows` function specifying the [filter logic](https://docs.microsoft.com/en-us/rest/api/storageservices/querying-tables-and-entities) in the `filter` parameter.

```dart
Future<void> testGetTableRow() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    var myPartitionKey='partition_key';
    var myRowKey='unique_row_id';
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

Future<void> testFilterTable() async {
  var storage = AzureStorage.parse('your connection string');
  List<dynamic> result=await storage.filterTableRows(tableName: 'profiles',
   filter: 'Age%20lt%2024', 
   fields: ['Age','CustomerSince'], 
   top:30 
   );
  print('\nFilter results');
  for(var res in result){
    print(res);
  }
}
```

Table rows can also be deleted.

```dart
Future<void> testDeleteTableRow() async {
  try {
    var storage = AzureStorage.parse('your connection string');
    await storage.deleteTableRow(tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
  }catch(e){
    print('delete exception: $e');
  }
}
```

### Azure Queue Functions

Azure Queue Storage allows you store large numbers of messages. Queues in your storage account can easily be managed using `createQueue`, `deleteQueue`, `getQList` and `getQData` functions.

```dart
Future<void> testCreateQ() async {
  try{
      var storage = AzureStorage.parse('your connection string');
      await storage.createQueue('myqueue');
  }catch(e){
     print('create queue error: $e');
  }
}

Future<void> testGetQData() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    String qName='myqueue';
    Map<String, String> result = await storage.getQData(qName);
    print('showing $qName data:\n');
    for (var res in result.entries) {
      print('${res.key}: ${res.value}');
    }
  }catch(e){
    print('get queue data error: $e');
  }
}

Future<void> testGetQList() async {
  try{
  var storage = AzureStorage.parse('your connection string');
  List<String> result=await storage.getQList();

  print('showing queue list\n');
  for(String res in result){
    print(res);
  }
  }catch(e){
     print('get queue list error: $e');
  }
}

Future<void> testDeleteQ() async {
  try{
      var storage = AzureStorage.parse('your connection string');
      await storage.deleteQueue('myqueue');
  }catch(e){
    print('delete queue error: $e');
  }
}

```

To insert and access messages in a queue, the functions `putQMessage`, `getQmessages`,`peekQmessage`,`clearQmessages` and `delQmessages` can be used as shown below.

```dart
Future<void> testPutMessage() async {
  var storage = AzureStorage.parse('your connection string');
  try {
     await storage.putQMessage(qName:'ttable', message: 'testing queue updates');
  }catch(e){
    print('get data error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testGetQMessages() async {
  var storage = AzureStorage.parse('your connection string');
  print('working on results...');
  try {
    List<AzureQMessage> result = await storage.getQmessages(qName: 'ttable',
      numOfmessages: 10
    );
    print('showing get results');
    for (var res in result) {
      print('message ${res}');
    }
  }catch (e){
    print('Q get messages exception $e');
  }
}

Future<void> testPeekQMessages() async {
  var storage = AzureStorage.parse('your connection string');
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

Future<void> testClearQMessage() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.clearQmessages('ttable');
  }catch(e){
    print('clear QM error: ${e.statusCode} ${e.message}');
  }
}

Future<void> testDeleteMessage() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.delQmessage(qName: 'ttable',
     messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e',
      popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE='
      );
  }catch(e){
    print('delete QM error: $e');
  }
}
```
The package provides internal documentation and required function parameters to ease working with functions. Also refer to the [Azure official documentation](https://docs.microsoft.com/en-us/rest/api/storageservices/queue-service-rest-api) for details on queue operations and message lifecycle.


## Azstore Functions.

### Blob Functions.

- `createContainer`: Create new blob container.
- `deleteContainer`: Delete blob container.
- `putBlob`: Put/update blob value.
- `appendBlock`: Add block to blob.
- `deleteBlob`: Delete blob.

### Table Functions.

- `createTable`: Create azure table.
- `deleteTable`: Delete azure table.
- `getTables`: Get tables in storage account.
- `upsertTableRow`: Update/insert new table row/node.
- `putTableRow`: Insert/replace new table row/node.
- `getTableRow`: Get table row/node values.
- `filterTableRows`: Search through rows with specified filter.
- `deleteTableRow`: Delete table node/row.

### Queue Functions.

- `createQueue`: Create new queue.
- `getQData`: Get properties of a queue.
- `deleteQueue`: Delete queue from storage account.
- `getQList`: Get list of all queues.
- `putQMessage`: Insert message to queue.
- `getQmessages`: Get a list of queue message objects while changing visibilty.
- `peekQmessages`: Get a list of queue message objects without changing visibility.
- `delQmessage`: Delete queue message.
- `updateQmessage`: Update queue message.
- `clearQmessages`: Delete all queue messages.

