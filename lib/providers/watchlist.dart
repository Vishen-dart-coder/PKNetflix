import 'dart:async';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:flutter/material.dart';
import 'package:pknetflix/data/entry.dart';

import '../api/client.dart';

class WatchListProvider extends ChangeNotifier {
  final String _collectionId = "watchlists";

  List<Entry> _entries = [];
  List<Entry> get entries => _entries;

  Future<User> get user async {
    return await ApiClient.account.get();
  }

  Future<List<Entry>> list() async {
    final user = await this.user;

    final watchlist = await ApiClient.database.listDocuments(
      databaseId: ApiClient.databaseId,
      collectionId: _collectionId,
    );

    final movieIds = watchlist.documents
        .map((document) => document.data["movieId"])
        .toList();
    final entries = (await ApiClient.database.listDocuments(
      databaseId: ApiClient.databaseId,
      collectionId: 'movies',
    ))
        .documents
        .map((document) => Entry.fromJson(document.data))
        .toList();
    final filtered =
        entries.where((entry) => movieIds.contains(entry.id)).toList();

    _entries = filtered;

    notifyListeners();

    return _entries;
  }

  Future<void> add(Entry entry) async {
    final user = await this.user;

    var result = await ApiClient.database.createDocument(
        databaseId: ApiClient.databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: {
          "userId": user.$id,
          "movieId": entry.id,
          "createdAt": (DateTime.now().second / 1000).round()
        });

    _entries.add(Entry.fromJson(result.data));

    list();
  }

  Future<void> remove(Entry entry) async {
    final user = await this.user;

    final result = await ApiClient.database.listDocuments(
        databaseId: ApiClient.databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal("userId", [user.$id]),
          Query.equal("movieId", [entry.id])
        ]);

    final id = result.documents.first.$id;

    await ApiClient.database.deleteDocument(
      databaseId: ApiClient.databaseId,
      collectionId: _collectionId,
      documentId: id,
    );

    list();
  }

  Future<Uint8List> imageFor(Entry entry) async {
    return await ApiClient.storage.getFileView(
      bucketId: 'default',
      fileId: entry.thumbnailImageId,
    );
  }

  bool isOnList(Entry entry) => _entries.any((e) => e.id == entry.id);
}
