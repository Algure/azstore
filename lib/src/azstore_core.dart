import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Blob type
enum BlobType {
  BlockBlob,
  AppendBlob,
}

/// Azure Storage Exception
class AzureStorageException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, String> headers;
  AzureStorageException(this.message, this.statusCode, this.headers);

  @override
  String toString() {
    return 'AzureStorageException: statusCode: $statusCode, message:$message';
  }
}

class AzureQMessage {
  String messageId;
  String insertionTime;
  String expirationTime;
  String popReceipt;
  String timeNextVisible;
  String dequeueCount;
  String messageText;

  AzureQMessage.fromXML(String xmlObj) {
    final xml = XmlDocument.parse(xmlObj);
    if (xml == null) return;
    messageId = xml.getElement('QueueMessage').getElement('MessageId') != null
        ? xml.getElement('QueueMessage').getElement('MessageId').text
        : '';

    insertionTime =
        xml.getElement('QueueMessage').getElement('InsertionTime') != null
            ? xml.getElement('QueueMessage').getElement('InsertionTime').text
            : '';

    expirationTime =
        xml.getElement('QueueMessage').getElement('ExpirationTime') != null
            ? xml.getElement('QueueMessage').getElement('ExpirationTime').text
            : '';

    popReceipt = xml.getElement('QueueMessage').getElement('PopReceipt') != null
        ? xml.getElement('QueueMessage').getElement('PopReceipt').text
        : '';
    timeNextVisible =
        xml.getElement('QueueMessage').getElement('TimeNextVisible') != null
            ? xml.getElement('QueueMessage').getElement('TimeNextVisible').text
            : '';
    dequeueCount =
        xml.getElement('QueueMessage').getElement('DequeueCount') != null
            ? xml.getElement('QueueMessage').getElement('DequeueCount').text
            : '';
    messageText =
        xml.getElement('QueueMessage').getElement('MessageText') != null
            ? xml.getElement('QueueMessage').getElement('MessageText').text
            : '';
  }

  @override
  String toString() {
    return '''
     messageId:$messageId,
   insertionTime:$insertionTime,
  expirationTime:$insertionTime,
  popReceipt:$popReceipt,
  timeNextVisible:$timeNextVisible,
  dequeueCount:$dequeueCount,
  messageText:$messageText,
    ''';
  }
}

/// Azure Storage Client
class AzureStorage {
  Map<String, String> config;
  Uint8List accountKey;

  static const String DefaultEndpointsProtocol = 'DefaultEndpointsProtocol';
  static const String EndpointSuffix = 'EndpointSuffix';
  static const String AccountName = 'AccountName';
  static const String AccountKey = 'AccountKey';

  /// Initialize with connection string.
  AzureStorage.parse(String connectionString) {
    try {
      final m = <String, String>{};
      final items = connectionString.split(';');
      for (final item in items) {
        final i = item.indexOf('=');
        final key = item.substring(0, i);
        final val = item.substring(i + 1);
        m[key] = val;
      }
      config = m;
      accountKey = base64Decode(config[AccountKey]);
    } catch (e) {
      throw Exception('Parse error.');
    }
  }

  @override
  String toString() {
    return config.toString();
  }

  Uri uri({String path = '/', Map<String, String> queryParameters}) {
    final scheme = config[DefaultEndpointsProtocol] ?? 'https';
    final suffix = config[EndpointSuffix] ?? 'core.windows.net';
    final name = config[AccountName];
    return Uri(
        scheme: scheme,
        host: '$name.blob.$suffix',
        path: path,
        queryParameters: queryParameters);
  }

  String _canonicalHeaders(Map<String, String> headers) {
    final keys = headers.keys
        .where((i) => i.startsWith('x-ms-'))
        .map((i) => '$i:${headers[i]}\n')
        .toList();
    keys.sort();
    return keys.join();
  }

  String _canonicalResources(Map<String, String> items) {
    if (items.isEmpty) {
      return '';
    }
    final keys = items.keys.toList();
    keys.sort();
    return keys.map((i) => '\n$i:${items[i]}').join();
  }

  List<String> _extractQList(String message) {
    final tabList = <String>[];
    final xx = XmlDocument.parse(message);
    for (final qNode
        in xx.getElement('EnumerationResults').findAllElements('Name')) {
      final name = qNode.text;
      tabList.add(name);
    }
    return tabList;
  }

  List<AzureQMessage> _extractQMessages(String message) {
    final tabList = <AzureQMessage>[];
    final xx = XmlDocument.parse(message);
    for (final qNode in xx.getElement('QueueMessagesList').nodes) {
      final azq = AzureQMessage.fromXML(qNode.toString());
      tabList.add(azq);
    }
    return tabList;
  }

  String _resolveNodeParams(List<String> fields) {
    var selectParams = '';
    if (fields != null && fields.length > 0) {
      for (final s in fields) {
        selectParams += ',$s';
      }
    }
    return selectParams == '' ? '*' : selectParams.trim().substring(1);
  }

  String _resolveNodeBody(String body, Map<String, dynamic> bodyMap) {
    if (bodyMap != null && bodyMap.length > 0) {
      body = _getJsonFromMap(bodyMap);
    }
    return body;
  }

  void _sign(http.Request request) {
    request.headers['x-ms-date'] = HttpDate.format(DateTime.now());
    request.headers['x-ms-version'] = '2016-05-31';
    final ce = request.headers['Content-Encoding'] ?? '';
    final cl = request.headers['Content-Language'] ?? '';
    final cz = request.contentLength == 0 ? '' : '${request.contentLength}';
    final cm = request.headers['Content-MD5'] ?? '';
    final ct = request.headers['Content-Type'] ?? '';
    final dt = request.headers['Date'] ?? '';
    final ims = request.headers['If-Modified-Since'] ?? '';
    final imt = request.headers['If-Match'] ?? '';
    final inm = request.headers['If-None-Match'] ?? '';
    final ius = request.headers['If-Unmodified-Since'] ?? '';
    final ran = request.headers['Range'] ?? '';
    final chs = _canonicalHeaders(request.headers);
    final crs = _canonicalResources(request.url.queryParameters);
    final name = config[AccountName];
    final path = request.url.path;
    final sig =
        '${request.method}\n$ce\n$cl\n$cz\n$cm\n$ct\n$dt\n$ims\n$imt\n$inm\n$ius\n$ran\n$chs/$name$path$crs';
    final mac = crypto.Hmac(crypto.sha256, accountKey);
    final digest = base64Encode(mac.convert(utf8.encode(sig)).bytes);
    final auth = 'SharedKey $name:$digest';
    request.headers['Authorization'] = auth;
    //print(sig);
  }

  void _sign4Q(http.Request request) {
    request.headers['x-ms-date'] = HttpDate.format(DateTime.now());
    request.headers['x-ms-version'] = '2016-05-31';
    final ce = request.headers['Content-Encoding'] ?? '';
    final cl = request.headers['Content-Language'] ?? '';
    final cz = request.contentLength == 0 ? '' : '${request.contentLength}';
    final cm = request.headers['Content-MD5'] ?? '';
    final ct = request.headers['Content-Type'] ?? '';
    final dt = request.headers['Date'] ?? '';
    final ims = request.headers['If-Modified-Since'] ?? '';
    final imt = request.headers['If-Match'] ?? '';
    final inm = request.headers['If-None-Match'] ?? '';
    final ius = request.headers['If-Unmodified-Since'] ?? '';
    final ran = request.headers['Range'] ?? '';
    final chs = _canonicalHeaders(request.headers);
    final crs = _canonicalResources(request.url.queryParameters);
    final name = config[AccountName];
    final sig =
        '${request.method}\n$ce\n$cl\n$cz\n$cm\n$ct\n$dt\n$ims\n$imt\n$inm\n$ius\n$ran\n$chs/$name/$crs';
    final mac = crypto.Hmac(crypto.sha256, accountKey);
    final digest = base64Encode(mac.convert(utf8.encode(sig)).bytes);
    final auth = 'SharedKey $name:$digest';
    request.headers['Authorization'] = auth;
  }

  void _sign4Tables(http.Request request) {
    request.headers['Date'] = HttpDate.format(DateTime.now());
    request.headers['x-ms-date'] = HttpDate.format(DateTime.now());
    request.headers['x-ms-version'] = '2016-05-31';
    final dt = request.headers['Date'] ?? '';
    final name = config[AccountName];
    final path = request.url.path;
    final sig = '$dt\n/$name$path';
    final mac = crypto.Hmac(crypto.sha256, accountKey);
    final digest = base64Encode(mac.convert(utf8.encode(sig)).bytes);
    final auth = 'SharedKeyLite $name:$digest';
    request.headers['Authorization'] = auth;
  }

  ///Extracts json entity from a Map
  String _getJsonFromMap(Map<String, dynamic> bodyMap) {
    var body = '{';
    for (final key in bodyMap.keys) {
      final mainVal = bodyMap[key].runtimeType == String
          ? '"${bodyMap[key]}"'
          : '${bodyMap[key]}';
      body += '"$key":$mainVal,';
    }
    body = body.substring(0, body.length - 1) + '}';
    return body;
  }

  /// Get Blob.
  Future<http.StreamedResponse> getBlob(String path) async {
    final request = http.Request('GET', uri(path: path));
    _sign(request);
    return request.send();
  }

  /// Put Blob.
  ///
  /// `body` and `bodyBytes` are exclusive and mandatory.
  Future<void> putBlob(String path,
      {String body,
      Uint8List bodyBytes,
      String contentType,
      BlobType type = BlobType.BlockBlob}) async {
    final request = http.Request('PUT', uri(path: path));
    request.headers['x-ms-blob-type'] =
        type.toString() == 'BlobType.AppendBlob' ? 'AppendBlob' : 'BlockBlob';
    request.headers['content-type'] = contentType;
    if (type == BlobType.BlockBlob) {
      if (bodyBytes != null) {
        request.bodyBytes = bodyBytes;
      } else if (body != null) {
        request.body = body;
      }
    } else {
      request.body = '';
    }
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 201) {
      await res.stream.drain();
      if (type == BlobType.AppendBlob && (body != null || bodyBytes != null)) {
        await appendBlock(path, body: body, bodyBytes: bodyBytes);
      }
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  Future<void> deleteBlob(String path,
      {BlobType type = BlobType.BlockBlob}) async {
    final request = http.Request('DELETE', uri(path: path));
    request.headers['x-ms-blob-type'] =
        type.toString() == 'BlobType.AppendBlob' ? 'AppendBlob' : 'BlockBlob';
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 202) {
      return;
    }

    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Append block to blob.
  Future<void> appendBlock(String path,
      {String body, Uint8List bodyBytes}) async {
    final request = http.Request(
        'PUT', uri(path: path, queryParameters: {'comp': 'appendblock'}));
    if (bodyBytes != null) {
      request.bodyBytes = bodyBytes;
    } else if (body != null) {
      request.body = body;
    }
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 201) {
      await res.stream.drain();
      return;
    }

    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Create a new table
  ///
  /// 'tableName' is  mandatory.
  Future<void> createTable(String tableName) async {
    final body = '{"TableName":"$tableName"}';
    final path = 'https://${config[AccountName]}.table.core.windows.net/Tables';
    final request = http.Request('POST', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Content-Length'] = '${body.length}';
    request.body = body;
    _sign4Tables(request);

    final res = await request.send();
    final message = await res.stream.bytesToString(); //DEBUG
    if (res.statusCode == 201 || res.statusCode == 204) {
      return;
    } else if (res.statusCode == 204) {
      return false;
    }

    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Delete a new table from azure storage account
  ///
  /// 'tableName' is  mandatory.
  Future<void> deleteTable(String tableName) async {
    final path =
        'https://${config[AccountName]}.table.core.windows.net/Tables(\'$tableName\')';
    final request = http.Request('DELETE', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    _sign4Tables(request);
    final res = await request.send();
    if (res.statusCode == 204) {
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Get a list of all tables in storage accout
  ///
  Future<List<String>> getTables() async {
    final path = 'https://${config[AccountName]}.table.core.windows.net/Tables';
    final request = http.Request('GET', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    _sign4Tables(request);

    final res = await request.send();
    final message = await res.stream.bytesToString();

    if (res.statusCode == 200) {
      final tabList = <String>[];
      final jsonResponse = await jsonDecode(message);
      for (final tData in jsonResponse['value']) {
        tabList.add(tData['TableName']);
      }
      return tabList;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Update table entity/entry.
  ///
  /// 'tableName', `partitionKey` and `rowKey` are all mandatory.
  /// `body` and `bodyMap` are exclusive and mandatory.
  Future<void> upsertTableRow(
      {@required String tableName,
      @required String partitionKey,
      @required String rowKey,
      String body,
      Map<String, dynamic> bodyMap}) async {
    body = _resolveNodeBody(body, bodyMap);
    final path =
        'https://${config[AccountName]}.table.core.windows.net/$tableName(PartitionKey=\'$partitionKey\', RowKey=\'$rowKey\')';
    final request = http.Request('MERGE', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Content-Length'] = '${body.length}';
    request.body = body;
    _sign4Tables(request);
    final res = await request.send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Upload or replace table entity/entry.
  ///
  /// 'tableName',`partitionKey` and `rowKey` are all mandatory.
  /// `body` and `bodyMap` are exclusive and mandatory.
  Future<void> putTableRow(
      {String tableName,
      String partitionKey,
      String rowKey,
      String body,
      Map<String, dynamic> bodyMap}) async {
    body = _resolveNodeBody(body, bodyMap);
    final path =
        'https://${config[AccountName]}.table.core.windows.net/$tableName(PartitionKey=\'$partitionKey\', RowKey=\'$rowKey\')';
    final request = http.Request('PUT', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Content-Length'] = '${body.length}';
    request.body = body;
    _sign4Tables(request);
    final res = await request.send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// get data from azure tables
  ///
  /// 'tableName','partitionKey' and 'rowKey' are all mandatory.
  /// If no fields are specified, all fields attached to the entry are returned
  Future<String> getTableRow(
      {String tableName,
      String partitionKey,
      String rowKey,
      List<String> fields}) async {
    final selectParams = _resolveNodeParams(fields);
    final path =
        'https://${config[AccountName]}.table.core.windows.net/$tableName(PartitionKey=\'$partitionKey\',RowKey=\'$rowKey\')?\$select=$selectParams';
//    print('get path: $path'); //DEBUG LOG
    final request = http.Request('GET', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept-Charset'] = 'UTF-8';
    request.headers['DataServiceVersion'] = '3.0;NetFx';
    request.headers['MaxDataServiceVersion'] = '3.0;NetFx';
    _sign4Tables(request);
    final res = await request.send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final message = await res.stream.bytesToString();
      return message;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Get a list of all tables in storage account
  /// top: Optional.	Returns only the top n tables or entities from the set.
  /// The package defaults this value to 20.
  /// filter: Required.
  /// Logic for filter condition can be gotten from official documentation
  /// e.g `RowKey%20eq%"237"` or  `AmountDue%20gt%2010`.
  ///fields: Optional. Specify columns/fields to be returned. By default, all fields are returned by the package
  Future<List<String>> filterTableRows(
      {@required String tableName,
      @required String filter,
      int top = 20,
      List<String> fields}) async {
    final selectParams = _resolveNodeParams(fields);
    final path =
        'https://${config[AccountName]}.table.core.windows.net/$tableName()?\$filter=$filter&\$select=$selectParams&\$top=$top';
//    print('path to upload: $path'); //DEBUG LOG
    final request = http.Request('GET', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept-Charset'] = 'UTF-8';
    request.headers['DataServiceVersion'] = '3.0;NetFx';
    request.headers['MaxDataServiceVersion'] = '3.0;NetFx';
    _sign4Tables(request);
    final res = await request.send();
    final message = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      final tabList = <String>[];
      final jsonResponse = await jsonDecode(message);
      for (final tData in jsonResponse['value']) {
        tabList.add(tData.toString());
      }
      return tabList;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Delete table entity.
  ///
  ///  'tableName', `partitionKey` and `rowKey` are all mandatory.
  Future<void> deleteTableRow(
      {@required String tableName,
      @required String partitionKey,
      @required String rowKey}) async {
    final path =
        'https://${config[AccountName]}.table.core.windows.net/$tableName(PartitionKey=\'$partitionKey\', RowKey=\'$rowKey\')';
//    print('delete path: $path');
    final request = http.Request('DELETE', Uri.parse(path));
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-Type'] = 'application/json';
    request.headers['If-Match'] = '*';
    _sign4Tables(request);
    final res = await request.send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Create a new queue
  ///
  /// 'qName' is  mandatory.
  Future<void> createQueue(String qName) async {
    final path = 'https://${config[AccountName]}.queue.core.windows.net/$qName';
    final request = http.Request('PUT', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 201) {
      return;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Get queue data
  ///
  /// 'qName' is  mandatory.
  Future<Map<String, String>> getQData(String qName) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName?comp=metadata';
    final request = http.Request('PUT', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 200 || res.statusCode == 204) {
      return res.headers;
    }
    final message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Delete a new queue
  ///
  /// 'qName' is  mandatory.
  Future<void> deleteQueue(String qName) async {
    final path = 'https://${config[AccountName]}.queue.core.windows.net/$qName';
    final request = http.Request('DELETE', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 204) {
      return;
    }
    final message = await res.stream.bytesToString(); //DEBUG
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Get a list of all queues attached to the storage account
  Future<List<String>> getQList() async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net?comp=list';
    final request = http.Request('GET', Uri.parse(path));
    _sign4Q(request);
    final res = await request.send();
    final message = await res.stream.bytesToString(); //DEBUG
    if (res.statusCode == 200) {
      final tabList = _extractQList(message);
      return tabList;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Put queue message
  ///
  /// 'qName': Name of the queue is  mandatory.
  ///
  ///  'message': The message data is required
  ///
  /// 'vtimeout': Optional. If specified, the request must be made using an x-ms-version of 2011-08-18 or later.
  /// If not specified, the default value is 0. Specifies the new visibility timeout value, in seconds, relative to server time.
  /// The new value must be larger than or equal to 0, and cannot be larger than 7 days.
  /// The visibility timeout of a message cannot be set to a value later than the expiry time.
  /// visibilitytimeout should be set to a value smaller than the time-to-live value.
  ///
  /// 'messagettl': Optional. Specifies the time-to-live interval for the message, in seconds.
  /// Prior to version 2017-07-29, the maximum time-to-live allowed is 7 days.
  /// For version 2017-07-29 or later, the maximum time-to-live can be any positive number, as well as -1 indicating that the message does not expire.
  /// If this parameter is omitted, the default time-to-live is 7 days.
  Future<void> putQMessage(
      {@required String qName,
      int messagettl = 604800,
      int vtimeout = 0,
      @required String message}) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages?visibilitytimeout=$vtimeout&messagettl=$messagettl';
    final request = http.Request('POST', Uri.parse(path));
    request.body = '''<QueueMessage>  
    <MessageText>$message</MessageText>  
  </QueueMessage> ''';
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 201 || res.statusCode == 204) {
      return;
    }
    final rMessage = await res.stream.bytesToString(); //DEBUG
    throw AzureStorageException(rMessage, res.statusCode, res.headers);
  }

  /// Get a list of all queue messaged in a queue
  ///
  /// 'qName': Name of the queue is  mandatory.
  ///
  /// vtimeout: Optional. Specifies the new visibility timeout value, in seconds, relative to server time. The default value is 30 seconds.
  ///
  ///A specified value must be larger than or equal to 1 second, and cannot be larger than 7 days, or larger than 2 hours on REST protocol versions prior to version 2011-08-18.
  ///The visibility timeout of a message can be set to a value later than the expiry time.
  ///
  ///numofmessages:	Optional. A nonzero integer value that specifies the number of messages to retrieve from the queue, up to a maximum of 32.
  ///If fewer are visible, the visible messages are returned.
  ///By default, this API retrieves 20 messages from the queue with this operation.
  Future<List<AzureQMessage>> getQmessages(
      {@required String qName, int numOfmessages = 20}) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages?numofmessages=$numOfmessages';
    final request = http.Request('GET', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    final message = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      final tabList = _extractQMessages(message);
      return tabList;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// The Peek Messages operation retrieves one or more messages from the front of the queue, but does not alter the visibility of the message.
  ///
  /// 'qName': Name of the queue is  mandatory.
  ///
  ///numofmessages:	Optional. A nonzero integer value that specifies the number of messages to retrieve from the queue, up to a maximum of 32.
  ///If fewer are visible, the visible messages are returned.
  ///By default, a single message is retrieved from the queue with this operation.
  ///This API also retrieves a single message with this mtod by default
  Future<List<AzureQMessage>> peekQmessages(
      {@required String qName, int numofmessages = 1}) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages?numofmessages=$numofmessages&peekonly=true';
    final request = http.Request('GET', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    final message = await res.stream.bytesToString(); //DEBUG
    if (res.statusCode == 200) {
      final tabList = _extractQMessages(message);
      return tabList;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// The Delete Message operation deletes the specified message from the queue.
  ///
  /// 'qName': Name of the queue is  mandatory.
  ///
  /// 'messageId':	Required.  A valid messageId value returned from an earlier call to the Get Messages or Update Message operation.
  ///
  /// 'popReceipt':	Required. A valid pop receipt value returned from an earlier call to the Get Messages or Update Message operation.
  Future<void> delQmessages(
      {@required String qName,
      @required String messageId,
      @required String popReceipt}) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages/$messageId?popreceipt=$popReceipt';
    final request = http.Request('DELETE', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    final message = await res.stream.bytesToString(); //DEBUG
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  ///The Update Message operation updates the visibility timeout of a message.
  ///You can also use this operation to update the contents of a message.
  ///
  /// popreceipt	Required. Specifies the valid pop receipt value returned from an earlier call to the Get Messages or Update Message operation.
  ///
  ///  message:  Required. The message can be up to 64KB in size.
  ///
  /// messageId	Required. Specifies the valid messageId value returned from an earlier call to the Get Messages or Update Message operation.
  ///
  ///visibilitytimeout	Required. Specifies the new visibility timeout value, in seconds, relative to server time.
  ///The new value must be larger than or equal to 0, and cannot be larger than 7 days.
  ///This API defaults this value to 0. The visibility timeout of a message cannot be set to a value later than the expiry time.
  ///A message can be updated until it has been deleted or has expired.
  Future<void> updateQmessages(
      {@required String qName,
      @required String messageId,
      Duration vTimeout,
      @required String message,
      @required String popReceipt}) async {
    final time = vTimeout != null ? vTimeout.inSeconds : 0;
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages/$messageId?popreceipt=$popReceipt&visibilitytimeout=$time';
    final request = http.Request('PUT', Uri.parse(path));
    request.body = '''<QueueMessage>  
          <MessageText>$message</MessageText>  
        </QueueMessage> ''';
    _sign(request);
    final res = await request.send();
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  ///The Clear Messages operation deletes all messages from the specified queue.
  ///
  /// 'qName': Name of the queue is  mandatory.
  ///
  Future<void> clearQmessages(String qName) async {
    final path =
        'https://${config[AccountName]}.queue.core.windows.net/$qName/messages';
    final request = http.Request('DELETE', Uri.parse(path));
    _sign(request);
    final res = await request.send();
    final message = await res.stream.bytesToString();
    if (res.statusCode == 204) {
      return;
    }
    throw AzureStorageException(message, res.statusCode, res.headers);
  }
}
