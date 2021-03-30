# azstore

[![license](https://img.shields.io/badge/license-MIT-success.svg?style=flat-square)](https://github.com/Algure/azstore/blob/master/LICENSE)
[![pub package](https://img.shields.io/pub/v/azstore.svg?color=success&style=flat-square)](https://pub.dartlang.org/packages/azstore)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-success.svg?style=flat-square)](https://github.com/Algure/azstore/pulls)

Access azure storage options via REST APIs.

## Getting Started

This package handles all the encryption and formatting required to provide easy access to azure storage options via REST APIs in flutter project.
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

#### Upload
Upload file to blob with         `putBlob`         function.         `body`          and         `bodyBytes`         are exclusive and mandatory.

Example:

```dart
Future<void> testUploadImage() async {
  File testFile =File('C:/Users/HP/Pictures/fdblack.png');
  Uint8List bytes = testFile.readAsBytesSync();
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.putBlob('/azpics/fdblack.png',
      bodyBytes: bytes,
      contentType: 'image/png',
    );
  }catch(e){
    print('exception: $e');
  }
}
```

Text can also be uploaded to blob in which case         `body`         parameter is specified instead of         `bodyBytes`         .

#### Delete
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

Also explore the         `appendBlock`          function.

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
  List<String> result=await storage.filterTableRows(tableName: 'profiles',
   filter: 'Age%20lt%2024', 
   fields: ['Age','CustomerSince'], 
   top:30 
   );
  print('\nFilter results');
  for(String res in result){
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

To insert and access messages in a queue, the functions `putQMessage`, `getQmessages`,`peekQmessages`,`clearQmessages` and `delQmessages` can be used as shown below.

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
    await storage.delQmessages(qName: 'ttable',
     messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e',
      popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE='
      );
  }catch(e){
    print('delete QM error: $e');
  }
}
```

The package provides internal documentation and required function parameters to ease working with functions. Also refer to the [Azure official documentation](https://docs.microsoft.com/en-us/rest/api/storageservices/queue-service-rest-api) for details on queue operations and messages lifecycle.

## Creating Azure Storage Account

You would need an azure storage account to complete this walk through.

### STEP 1.
Navigate to your azure portal and create a resource by clicking the `create a resourse button` then select `storage accounts` or simply click the `storage accounts` button if it appears on your home page.


![createRes](https://user-images.githubusercontent.com/37802577/112473274-6d9f2f80-8d6e-11eb-92e7-1025c96023d5.png)


![selectstore](https://user-images.githubusercontent.com/37802577/112473279-6f68f300-8d6e-11eb-943d-4d8e912c75ca.png)

### STEP 2.
Enter details for your new storage account and then `Review + create` . Also feel free to explore options in the other tabs (`Networking`, `Data Protection`, `Advanced` and `Tags`) for more control over your storage account. (Review process may take a few seconds).


![storewalkthrough](https://user-images.githubusercontent.com/37802577/112473217-5d875000-8d6e-11eb-9a1b-c21735b6e8fc.png)

### STEP 3:
Complete account creation by clicking the `Create` button after review is complete.


![create](https://user-images.githubusercontent.com/37802577/112473256-6841e500-8d6e-11eb-8d68-4cf6bbb1842a.png)


### STEP 4:
Go to resource after deployment is complete.


![deploymentcompleted](https://user-images.githubusercontent.com/37802577/112473277-6ed05c80-8d6e-11eb-83fa-a01d5908adae.png).


### STEP 5:
In the resource page, navigate to the `Access keys` tab and `show keys`. The `show keys` button exposes your access keys and **connection string** which is all you need to use this flutter package.


![copy_keys](https://user-images.githubusercontent.com/37802577/112519675-e2885e80-8d9a-11eb-9c8b-1ac493fe9f05.png)


## 🤓 Maintainer(s)
<table>
  <tr>
    <td align="center">
      <a href = "https://github.com/Algure"><img src="https://avatars.githubusercontent.com/u/37802577?v=4" width="72" alt="Ajiri Gunn" /></a>
      <p><b>Ajiri Gunn</b></p>
      <p align="center">
        <a href = "https://github.com/Algure"><img src = "http://www.iconninja.com/files/241/825/211/round-collaboration-social-github-code-circle-network-icon.svg" width="18" height = "18"/></a>
        <a href = "."><img src = "https://github.com/aritraroy/social-icons/blob/master/twitter-icon.png?raw=true" width="18" height="18"/></a>
        <a href = "."><img src = "https://github.com/aritraroy/social-icons/blob/master/linkedin-icon.png?raw=true" width="18" height="18"/></a>
      </p>
    </td>
    <td align="center">
      <a href = "https://github.com/mastersam07"><img src="https://avatars3.githubusercontent.com/u/31275429?s=460&u=b935d608a06c1604bae1d971e69a731480a27d46&v=4" width="72" alt="Samuel Abada" /></a>
      <p><b>Samuel Abada</b></p>
      <p align="center">
        <a href = "https://github.com/mastersam07"><img src = "http://www.iconninja.com/files/241/825/211/round-collaboration-social-github-code-circle-network-icon.svg" width="18" height = "18"/></a>
        <a href = "https://twitter.com/mastersam_"><img src = "https://github.com/aritraroy/social-icons/blob/master/twitter-icon.png?raw=true" width="18" height="18"/></a>
        <a href = "https://linkedin.com/in/abada-samuel/"><img src = "https://github.com/aritraroy/social-icons/blob/master/linkedin-icon.png?raw=true" width="18" height="18"/></a>
      </p>
    </td>
  </tr> 
</table>

</p>

## ⭐️ License

#### <a href="https://github.com/Algure/azstore/blob/master/LICENSE">MIT LICENSE</a>
