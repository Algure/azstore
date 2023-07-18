import 'dart:convert';

import 'package:azstore/src/azstore_core.dart';
import 'package:azstore/azstore.dart';
import 'package:test/test.dart';

const connectionString = '<placeholder>';

void main() {
  group('Azure Tables Tests', () {
    var storage = AzureStorage.parse(connectionString);
    String testTableName = 'testtable';
    var myPartitionKey = "sfsdfsrg57865746";
    var myRowKey = '237';
    test('Create table', () async {
      await storage.createTable(testTableName);
    });

    test('upload table node', () async {
      Map<String, dynamic> rowMap = {
        "Address": "Santa Clara",
        "Age": 23,
        "AmountDue": 200.23,
        "CustomerCode@odata.type": "Edm.Guid",
        "CustomerCode": "c9da6455-213d-42c9-9a79-3e9149a57833",
        "CustomerSince@odata.type": "Edm.DateTime",
        "CustomerSince": "2008-07-10T00:00:00",
        "IsActive": false,
        "NumberOfOrders@odata.type": "Edm.Int64",
        "NumberOfOrders": "255",
        "PartitionKey": myPartitionKey,
        "RowKey": myRowKey
      };
      await storage.upsertTableRow(
          tableName: testTableName,
          rowKey: myRowKey,
          partitionKey: myPartitionKey,
          bodyMap: rowMap);
    });

    test('Get table row', () async {
      String result = await storage.getTableRow(
          tableName: testTableName,
          partitionKey: myPartitionKey,
          rowKey: myRowKey,
          fields: ['Address', 'CustomerSince']);
      var resultMap = jsonDecode(result);
      expect(resultMap['Address'], 'Santa Clara');
    });

    test('Filter table', () async {
      var storage = AzureStorage.parse(connectionString);
      List<dynamic> result = await storage.filterTableRows(
          tableName: testTableName,
          filter: 'Age%20lt%2024',
          fields: ['Age', 'CustomerSince', 'PartitionKey', 'RowKey'],
          top: 10);
      print('result: ${result[0]}');
      expect(result[0]['PartitionKey'].toString(), myPartitionKey);
      expect(result[0]['RowKey'].toString(), myRowKey);
      expect(result[0]['Age'].toString(), '23');

      result = await storage.filterTableRows(
          tableName: testTableName,
          filter: 'Age%20gt%2024',
          fields: ['Age', 'CustomerSince', 'PartitionKey', 'RowKey'],
          top: 10);
      expect(result.length, 0);
    });

    test('Delete tables row. Returns void', () async {
      await storage.deleteTableRow(
          tableName: testTableName,
          partitionKey: myPartitionKey,
          rowKey: myRowKey);
    });

    test('Delete tables. Returns void', () async {
      await storage.deleteTable(testTableName);
    });
  });

  group('Azure queue tests', () {
    var storage = AzureStorage.parse(connectionString);
    String testQName = 'testqueue';
    String? messageId;
    String? popReceipt;

    test('Create queue', () async {
      await storage.createQueue(testQName);
    });

    test('Get queue data', () async {
      Map<String, String> result = await storage.getQData(testQName);
      for (var res in result.entries) {
        print('${res.key}: ${res.value}');
      }
    });

    test('Get queue list', () async {
      List<String> result = await storage.getQList();
      bool isFine = result.isNotEmpty;
      expect(isFine, true);
    });

    test('put queue messages', () async {
      for (int i = 1; i <= 10; i++) {
        await storage.putQMessage(
            qName: testQName, message: 'testing inputs $i');
      }
    });

    test('peek queue message', () async {
      List<AzureQMessage> result =
          await storage.peekQmessages(qName: testQName, numofmessages: 10);
      for (AzureQMessage q in result) {
        print(q);
      }

      expect(result.length, 10);
      expect(result[0].messageText, 'testing inputs 1');

      result = await storage.peekQmessages(qName: testQName);
      expect(result.length, 1);
    });

    test('Get queue messages', () async {
      List<AzureQMessage> result = await storage.getQmessages(
          qName: testQName, //Required
          numOfmessages: 5,
          visibilitytimeout:
              3 //Optional. Number of messages to retrieve. This package returns top 20 filter results when not specified.
          );
      bool limitTest =
          result.any((element) => element.messageText!.contains('6'));
      expect(result.length, 5);
      expect(limitTest, false);
      expect(result[0].messageText, 'testing inputs 1');
      print('received message: ${result[0]}');
      await Future.delayed(const Duration(seconds: 120));
      result = await storage.getQmessages(
          qName: testQName, //Required
          numOfmessages: 3,
          visibilitytimeout:
              2 //Optional. Number of messages to retrieve. This package returns top 20 filter results when not specified.
          );
      expect(result[0].messageText, 'testing inputs 1');
      expect(result.length, 3);
      messageId = result[0].messageId;
      popReceipt = result[0].popReceipt;
    });

    test('Delete Queue message', () async {
      await Future.delayed(const Duration(seconds: 120));
      var storage = AzureStorage.parse(connectionString);
      await storage.delQmessage(
          qName: testQName,
          messageId: messageId ?? '',
          popReceipt: popReceipt ?? '');
    });

    test('Clear queue messages', () async {
      await storage.clearQmessages(testQName);
    });

    test('Delete queue', () async {
      var storage = AzureStorage.parse(connectionString);
      await storage.deleteQueue(testQName);
    });
  });

  group('Azure blob tests', () {
    var storage = AzureStorage.parse(connectionString);
    String blobInput = 'blob test';
    String blobpath = 'test/test_blob';
    String containerName = 'test';

    test('Create container', () async {
      await storage.createContainer(containerName, timeout: 10);
    });

    test('Put blob test', () async {
      await storage.putBlob(blobpath,
          contentType: 'application/json', body: blobInput);
    });

    test('Get blob test', () async {
      var response = await storage.getBlob(blobpath);
      String value = await response.stream.bytesToString();
      print(' blob value: $value');
      expect(value.contains(blobInput), true);
    });

    test('Delete blob', () async {
      await storage.deleteBlob(
        blobpath,
      );
    });

    test('Delete container', () async {
      await storage.deleteContainer(containerName, timeout: 20);
    });
  });
}

deleteTableRow() async {
  var storage = AzureStorage.parse(connectionString);
  await storage.deleteTableRow(
      tableName: 'profiles', partitionKey: 'fgtdssdas', rowKey: '232');
}

Future<void> filterTable() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  List<dynamic> result = await storage.filterTableRows(
      tableName: 'profiles',
      filter: 'Age%20lt%2024',
      fields: ['Age', 'CustomerSince', 'PartitionKey', 'RowKey'],
      top: 10);
  print('showing filter results');
  for (String res in result) {
    print(res);
  }
}

Future<void> uploadTableNode() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    var myPartitionKey = "sfsdfsrg57865746";
    var myRowKey = '237';
    Map<String, dynamic> rowMap = {
      "Address": "Santa Clara",
      "Age": 23,
      "AmountDue": 200.23,
      "CustomerCode@odata.type": "Edm.Guid",
      "CustomerCode": "c9da6455-213d-42c9-9a79-3e9149a57833",
      "CustomerSince@odata.type": "Edm.DateTime",
      "CustomerSince": "2008-07-10T00:00:00",
      "IsActive": false,
      "NumberOfOrders@odata.type": "Edm.Int64",
      "NumberOfOrders": "255",
      "PartitionKey": myPartitionKey,
      "RowKey": myRowKey
    };
    await storage.upsertTableRow(
        tableName: 'profiles',
        rowKey: myRowKey,
        partitionKey: myPartitionKey,
        bodyMap: rowMap);
    print('done uploading');
  } catch (e) {
    print('tables upsert exception: $e');
  }
}

Future<void> getTableRow() async {
  try {
    var storage = AzureStorage.parse(connectionString);
    var myPartitionKey = "fgtdssdas";
    var myRowKey = '232';
    String result = await storage.getTableRow(
        tableName: 'profiles',
        partitionKey: myPartitionKey,
        rowKey: myRowKey,
        fields: ['Address', 'CustomerSince']);
    print('result: $result');
  } catch (e) {
    print('tables get exception: $e');
  }
}

Future<void> deleteBlob() async {
  var storage = AzureStorage.parse('your connection string');
  try {
    await storage.deleteBlob('/azpics/fdblack.png');
    print('done deleting'); //Do something else
  } catch (e) {
    print('exception: $e');
  }
}

Future<void> updateQMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.updateQmessage(
        qName: 'ttable',
        messageId: 'c9aaeea8-4d47-4cf8-a080-250fb218468f',
        popReceipt: 'AgAAAAMAAAAAAAAAzVPboAkg1wE=',
        message: 'testing update: This is an update');
    print('done');
  } catch (e) {
    print('delete QM error: $e');
  }
}

Future<void> createQ() async {
  var storage = AzureStorage.parse(connectionString);
  await storage.createQueue('newer-queue');
}

Future<void> getQData() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    String qName = 'myqueue';
    Map<String, String> result = await storage.getQData(qName);
    print('showing $qName data:\n');
    for (var res in result.entries) {
      print('${res.key}: ${res.value}');
    }
  } catch (e) {
    print('get data error: $e');
  }
}

Future<void> deleteQ() async {
  var storage = AzureStorage.parse(connectionString);
  await storage.deleteQueue('newer-queue');
  print('done');
}

Future<void> getQList() async {
  var storage = AzureStorage.parse(connectionString);
  List<String> result = await storage.getQList();
  print('showing queue list\n');
  for (String res in result) {
    print(res);
  }
}

Future<void> putMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.putQMessage(qName: 'ttable', message: 'testing expiration');
  } catch (e) {
    print('get data error: $e');
  }
}

Future<void> getQMessages() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    List<AzureQMessage> result = await storage.getQmessages(
        qName: 'ttable', //Required
        numOfmessages:
            10 //Optional. Number of messages to retrieve. This package returns top 20 filter results when not specified.
        );
    print('showing results');
    for (var res in result) {
      print('message $res');
    }
  } catch (e) {
    print('Q get messages exception $e');
  }
}

Future<void> peekQMessages() async {
  var storage = AzureStorage.parse(connectionString);
  try {
    List<AzureQMessage> result = await storage.peekQmessages(qName: 'ttable');
    print('showing peek results');
    for (var res in result) {
      print('message ${res.messageText}');
    }
  } catch (e) {
    print('Q peek messages exception $e');
  }
}

Future<void> clearQMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.clearQmessages('ttable');
    print('done');
  } catch (e) {
    print('delete QM error: $e');
  }
}

Future<void> deleteQMessage() async {
  var storage = AzureStorage.parse(connectionString);
  print('working on results...');
  try {
    await storage.delQmessage(
        qName: 'ttable',
        messageId: '27bc633b-4de0-42bf-bea6-0860bd410f4e',
        popReceipt: 'AgAAAAMAAAAAAAAAX3e0UwAg1wE=');
    print('done');
  } catch (e) {
    print('delete QM error: $e');
  }
}
