// lib/providers/update_data.dart

import 'dart:convert';
import 'package:careerfair/widgets/EntryModel/entryModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateData with ChangeNotifier {
  // Map: date key -> list of entries
  Map<String, List<EntryModel>> days = {};

  UpdateData() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('savedDays'); 
    if (jsonString != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      days = decoded.map((key, value) {
        final entries = (value as List)
            .map((e) => EntryModel.fromMap(e as Map<String, dynamic>))
            .toList();
        return MapEntry(key, entries);
      });
    } else {
      days = {};
    }
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = days.map((key, value) =>
        MapEntry(key, value.map((e) => e.toMap()).toList()));
    final jsonString = jsonEncode(jsonMap);
    await prefs.setString('savedDays', jsonString);
  }

  Future<String> addDate(DateTime date) async {
    final formattedDate = formatDate(date);
    if (!days.containsKey(formattedDate)) {
      days[formattedDate] = [];
      await saveData();
      notifyListeners();
      return "Added";
    } else {
      return "Present";
    }
  }

  List<EntryModel> getEntriesForDate(String dateKey) {
    return days[dateKey] ?? [];
  }

  Future<void> addEntryToDate(String dateKey, EntryModel entry) async {
    if (!days.containsKey(dateKey)) {
      days[dateKey] = [];
    }
    days[dateKey]!.add(entry);
    await saveData();
    notifyListeners();
  }

  Future<void> deleteDate(String dateKey) async {
    days.remove(dateKey);
    await saveData();
    notifyListeners();
  }

  Future<void> deleteEntry(String dateKey, EntryModel entry) async {
    if (days.containsKey(dateKey)) {
      days[dateKey]!.remove(entry);
      if (days[dateKey]!.isEmpty) {
        days.remove(dateKey);
      }
      await saveData();
      notifyListeners();
    }
  }

  String formatDate(DateTime date) {
    // you can format nicely
    return "${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  }
}
