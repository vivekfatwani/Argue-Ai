import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/debate_model.dart';
import '../constants.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class AIService {
  late final GenerativeModel _model;
  late final GenerationConfig _config;
  static const String _defaultApiKey = 'AIzaSyC2BIc0pU7zxUCplaA1q6LYwJwtrV2AlYE';
  
  // Initialize with API key
  AIService([String? apiKey]) {
    final key = apiKey ?? _defaultApiKey;
    developer.log('Initializing AIService with Gemini model', name: 'AIService');
    
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key, // ✅ FIXED: using the non-nullable String
      );
      
      _config = GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048, // Increased from AppConstants.maxResponseTokens to handle larger feedback
      );
      developer.log('AIService initialized successfully', name: 'AIService');
    } catch (e) {
      developer.log('Error initializing AIService: $e', name: 'AIService');
      rethrow;
    }
  }
  
  // Generate a debate response
  Future<String> generateDebateResponse(String topic, List<DebateMessage> history) async {
    try {
      developer.log('Generating debate response for topic: $topic', name: 'AIService');
      
      final formattedHistory = history.map((msg) {
        return Content.text(
          msg.isUser ? "User: ${msg.content}" : "AI: ${msg.content}"
        );
      }).toList();
      
  // Find the most recent user message (if any) so the model can respond directly to it
  String lastUserMessage = '';
  try {
    final lastUser = history.lastWhere((m) => m.isUser, orElse: () => history.isNotEmpty ? history.last : DebateMessage(content: '', isUser: true, timestamp: DateTime.now()));
    lastUserMessage = lastUser.content;
  } catch (_) {
    lastUserMessage = '';
  }

  developer.log('Last user message for prompt: $lastUserMessage', name: 'AIService');

  final prompt = """
You are ArguMentor, an AI debate partner. You are engaging in a debate on the topic: "$topic".
Below is the most recent thing the user said (transcribed from their audio):
"""
  + lastUserMessage +
  """

Instruction: Respond directly to the user's last message above. If the user made a claim, challenge it with clear arguments; if they asked to take the first turn or perform an action, respond to that request accordingly. Use logical reasoning and relevant evidence. Keep your response concise (3-5 sentences) and focused on the last user message.
""";

  formattedHistory.insert(0, Content.text(prompt));
      
      final response = await _model.generateContent(
        formattedHistory,
        generationConfig: _config,
      );
      
      if (response.text != null) {
        developer.log('Successfully generated debate response', name: 'AIService');
        return response.text!;
      } else {
        developer.log('Generated response was empty', name: 'AIService');
        return "I'm sorry, I couldn't generate a response. Let's continue the debate.";
      }
    } catch (e) {
      developer.log('Error generating debate response: $e', name: 'AIService');
      return "I apologize, but I encountered an error while generating a response. Let's try again.";
    }
  }
  
  // Generate feedback on a completed debate
  Future<Map<String, dynamic>> generateDebateFeedback(String topic, List<DebateMessage> messages) async {
    try {
      final transcript = messages.map((msg) {
        return "${msg.isUser ? 'User' : 'AI'}: ${msg.content}";
      }).join("\n\n");
      
      final prompt = """
Analyze the following debate on the topic: "$topic".

Debate Transcript:
$transcript

Provide feedback on the user's debating skills in the following JSON format:
{
  "skillRatings": {
    "clarity": 0.0 to 1.0,
    "logic": 0.0 to 1.0,
    "rebuttalQuality": 0.0 to 1.0,
    "persuasiveness": 0.0 to 1.0
  },
  "strengths": ["strength1", "strength2", "strength3"],
  "improvements": ["improvement1", "improvement2", "improvement3"],
  "overallFeedback": "A paragraph of overall feedback"
}
""";
      
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: _config,
      );
      
      final feedbackText = response.text ?? "{}";
      developer.log("Feedback response: $feedbackText", name: 'AIService');
      
      try {
        // First try to parse the entire response as JSON
        try {
          final Map<String, dynamic> parsedJson = json.decode(feedbackText);
          developer.log("Successfully parsed complete JSON response", name: 'AIService');
          return parsedJson;
        } catch (_) {
          // If that fails, try to extract JSON from the text
          final jsonStart = feedbackText.indexOf('{');
          final jsonEnd = feedbackText.lastIndexOf('}') + 1;
          
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = feedbackText.substring(jsonStart, jsonEnd);
            developer.log("Extracted JSON string: $jsonStr", name: 'AIService');
            final Map<String, dynamic> parsedJson = json.decode(jsonStr);
            return parsedJson;
          } else {
            throw Exception("Could not find valid JSON in response");
          }
        }
      } catch (jsonError) {
        developer.log("Error parsing JSON feedback: $jsonError", name: 'AIService');
        developer.log("Raw response: $feedbackText", name: 'AIService');
      }
      
      return {
        "skillRatings": {
          "clarity": 0.7,
          "logic": 0.8,
          "rebuttalQuality": 0.6,
          "persuasiveness": 0.75
        },
        "strengths": [
          "Good use of evidence",
          "Clear structure in arguments",
          "Effective counter-arguments"
        ],
        "improvements": [
          "Could improve emotional appeal",
          "Some arguments lack specific examples",
          "Consider addressing opposing viewpoints more directly"
        ],
        "overallFeedback": "Overall, you demonstrated strong debating skills with logical arguments and clear structure. Your rebuttals were effective, though they could be more direct. To improve, focus on incorporating more specific examples and emotional appeals to make your arguments more persuasive."
      };
    } catch (e) {
      print("Error generating feedback: $e");
      return {
        "error": "Error generating feedback: $e"
      };
    }
  }
  
  // Generate personalized learning recommendations
  Future<List<Map<String, dynamic>>> generateLearningRecommendations(
    Map<String, double> skillRatings
  ) async {
    try {
      final skillsJson = skillRatings.entries.map((e) => 
        '"${e.key}": ${e.value}'
      ).join(', ');
      
      final prompt = """
Based on the following skill ratings, recommend 3 learning resources to help improve the user's debating skills:
{ $skillsJson }

Provide recommendations in the following JSON format:
[
  {
    "id": "unique_id_1",
    "title": "Resource Title",
    "description": "Brief description of the resource",
    "type": "video|article|exercise",
    "url": "URL or description of where to find it",
    "targetSkills": ["skill1", "skill2"]
  },
  ...
]
""";
      
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: _config,
      );
      
      final recommendationsText = response.text ?? "[]";
      print("Recommendations response: $recommendationsText");
      
      try {
        final jsonStart = recommendationsText.indexOf('[');
        final jsonEnd = recommendationsText.lastIndexOf(']') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = recommendationsText.substring(jsonStart, jsonEnd);
          final List<dynamic> parsedJson = json.decode(jsonStr);
          return parsedJson.cast<Map<String, dynamic>>();
        }
      } catch (jsonError) {
        print("Error parsing JSON recommendations: $jsonError");
      }
      
      return [
        {
          "id": "rec_1",
          "title": "Mastering Logical Fallacies",
          "description": "Learn to identify and avoid common logical fallacies in debates",
          "type": "video",
          "url": "https://example.com/logical-fallacies",
          "targetSkills": ["logic", "rebuttalQuality"]
        },
        {
          "id": "rec_2",
          "title": "Persuasive Speaking Techniques",
          "description": "Effective methods to make your arguments more persuasive",
          "type": "article",
          "url": "https://example.com/persuasive-speaking",
          "targetSkills": ["persuasiveness", "clarity"]
        },
        {
          "id": "rec_3",
          "title": "Rebuttal Practice Exercise",
          "description": "Interactive exercise to practice responding to opposing arguments",
          "type": "exercise",
          "url": "In-app exercise",
          "targetSkills": ["rebuttalQuality", "logic"]
        }
      ];
    } catch (e) {
      print("Error generating recommendations: $e");
      return [
        {
          "error": "Error generating recommendations: $e"
        }
      ];
    }
  }
}

