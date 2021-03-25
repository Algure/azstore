# azstore

Access azure storage options via REST APIs.

## Getting Started

This package handles all the encryption and formatting required to provide easy access to azure storage options via REST APIs in flutter project. The package currently provides functions to query and upload data to Azure blobs, tables and queues. Add the latest dependency to your pubspec.yaml to get started. azstore: ^latest_version and import. In the following examples, 'your connection string' can be gotten from the azure portal after simply creating a storage account ( or follow the walkthrough in the section [Creating Azure Storage Account](#creating-azure-storage-account) ).

## Azure Blob Functions.

Upload file to blob with         `putBlob`         function.         `body`          and         `bodyBytes`         are exclusive and mandatory.

Example:

```
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

Delete blob operations can also be performed as shown.

```
Future<void> testDeleteBlob() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.deleteBlob('/azpics/fdblack.png');
    print('done deleting');//Do something else
  }catch(e){
    print('exception: $e');
  }
}
```

Also explore the         `appendBlock`          function.

## Table Storage Functions

The Azure Table service offers structured NoSQL storage in the form of tables.
Tables can be managed using the         `createTable`,`deleteTable`         and         `getTables`          functions.
Table nodes/rows can be controlled using other functions  such as         `upsertTableRow`,`putTableRow`,`getTableRow` and `deleteTableRow`.

The following snippets show the use of some table access functions. Also refer to the [Azure Tables docs](https://docs.microsoft.com/en-us/rest/api/storageservices/payload-format-for-table-service-operations/) for allowed data types to insert in a table row.
The code documentation provides further help.

Use `upsertTableRow` when updating or adding new table row and `putTableRow` to replace or add a new row.

```
Future<void> testUpload2Table() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    var myPartitionKey='partition_key';
    var myRowKey='237';//Must be unique
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
        tableName: 'profiles',//Required.
        rowKey:myRowKey,//Required.
        bodyMap: rowMap//Required.
     );
  }catch(e){
    print('tables upsert exception: $e');
  }
}

```

Specific Table rows can be retrieved using `getTableRow` function as shown below. Filters can also be used to retrieve a list of table rows by using the `filterTableRows` function specifying the [filter logic](https://docs.microsoft.com/en-us/rest/api/storageservices/querying-tables-and-entities) in the `filter` parameter.

```
Future<void> testGetTableRow() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    var myPartitionKey='partition_key';
    var myRowKey='unique_row_id';
    String result=await storage.getTableRow(
        tableName: 'profiles',//Required.
        partitionKey:myPartitionKey,// Required. partitionKey parameter specified in upsert operation.
        rowKey:myRowKey,// Required. rowKey parameter specified in upsert operation.
        fields: ['Address','CustomerSince']//Optional. Retrieves all fields when not specified.
    );
    print('result: $result');
  }catch(e){
    print('tables get exception: $e');
  }
}

Future<void> testFilterTable() async {
  var storage = AzureStorage.parse('your connection string');
  List<String> result=await storage.filterTableRows(tableName: 'profiles',//Required
   filter: 'Age%20lt%2024', //Required.
   fields: ['Age','CustomerSince'], //Optional. Retrieves all fields when not specified.
   top:30 //Optional. Number of entities to retrieve. This package returns top 20 filter results when not specified.
   );
  print('\nFilter results');
  for(String res in result){
    print(res);
  }
}
```

Table rows can also be deleted.
```
Future<void> testDeleteTableRow() async {
  try {
    var storage = AzureStorage.parse('your connection string');
    //All parameters are required
    await storage.deleteTableRow(tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
  }catch(e){
    print('delete exception: $e');
  }
}
```

## Azure Queue Functions

Azure Queue Storage allows you store large numbers of messages. Queues in your storage account can easily be managed using `createQueue`, `deleteQueue`, `getQList` and `getQData` functions.

```
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

```

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
    List<AzureQMessage> result = await storage.getQmessages(qName: 'ttable',//Required
      numOfmessages: 10//Optional. Number of messages to retrieve. This package returns top 20 filter results when not specified.
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
  //All fields are required.
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
Navigate to your azure portal and create a resource by clicking the create a resourse button then select storage accounts or simply click the storage accounts button if it appears on your home page.

![createRes](https://user-images.githubusercontent.com/37802577/112519190-6aba3400-8d9a-11eb-9c9e-0efe6c93b09a.png)

![selectstore](https://user-images.githubusercontent.com/37802577/112519216-6f7ee800-8d9a-11eb-926d-bcd68d58a9e4.png)


### STEP 2.
Enter details for your new storage account and then Review + create . Also feel free to explore options in the other tabs (Networking, Data Protection, Advanced and Tags) for more control over your storage account. (Review process may take a few seconds).

![storewalkthrough](https://user-images.githubusercontent.com/37802577/112519140-5f670880-8d9a-11eb-942f-bbcdde186163.png)

### STEP 3:
Complete account creation by clicking the Create button after review is complete.

![create](https://user-images.githubusercontent.com/37802577/112519176-6726ad00-8d9a-11eb-8514-722d8e321585.png)


### STEP 4:
Go to resource after deployment is complete.

![deploymentcompleted](https://user-images.githubusercontent.com/37802577/112519206-6e4dbb00-8d9a-11eb-8b5e-5660ed6099e5.png)


### STEP 5:
In the resource page, navigate to the Access keys tab and show keys. The show keys button exposes your access keys and connection string which is all you need to use this flutter package.

![copy_keys](https://user-images.githubusercontent.com/37802577/112519155-63932600-8d9a-11eb-98ee-f11672006e48.png)



**ENJOY !!!**

