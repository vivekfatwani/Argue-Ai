import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class Utils {
  // Show a snackbar with a message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Format a date to a readable string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format a timestamp to a readable string
  static String formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // Save data to SharedPreferences
  static Future<bool> saveToPrefs(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else if (value is int) {
      return await prefs.setInt(key, value);
    } else if (value is double) {
      return await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      return await prefs.setStringList(key, value);
    } else {
      // For complex objects, convert to JSON
      return await prefs.setString(key, jsonEncode(value));
    }
  }

  // Get data from SharedPreferences
  static Future<dynamic> getFromPrefs(String key, Type type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == String) {
      return prefs.getString(key);
    } else if (type == bool) {
      return prefs.getBool(key);
    } else if (type == int) {
      return prefs.getInt(key);
    } else if (type == double) {
      return prefs.getDouble(key);
    } else if (type == List<String>) {
      return prefs.getStringList(key);
    } else {
      // For complex objects, parse from JSON
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
      return null;
    }
  }

  // Calculate debate score based on skill ratings
  static Map<String, double> calculateDebateScore(Map<String, double> skillRatings) {
    double overallScore = 0;
    
    // Calculate the average of all skill ratings
    for (final rating in skillRatings.values) {
      overallScore += rating;
    }
    overallScore = overallScore / skillRatings.length;
    
    // Return both individual ratings and overall score
    return {
      ...skillRatings,
      'overall': overallScore,
    };
  }

  // Get a random debate topic
  static String getRandomDebateTopic() {
    final topics = AppConstants.debateTopics;
    return topics[DateTime.now().millisecondsSinceEpoch % topics.length];
  }

  // Determine badge level based on points
  static String getBadgeLevel(int points) {
    if (points >= AppConstants.platinumBadgeThreshold) {
      return 'Platinum';
    } else if (points >= AppConstants.goldBadgeThreshold) {
      return 'Gold';
    } else if (points >= AppConstants.silverBadgeThreshold) {
      return 'Silver';
    } else if (points >= AppConstants.bronzeBadgeThreshold) {
      return 'Bronze';
    } else {
      return 'Novice';
    }
  }

  // Format a skill rating to a percentage string
  static String formatSkillRating(double rating) {
    return '${(rating * 100).toStringAsFixed(0)}%';
  }
}
