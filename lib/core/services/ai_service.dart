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
          msg.isUser ? "User: ${msg.content}" : "Assistant: ${msg.content}"
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
You are a skilled debate partner engaging in a structured, turn-based voice debate on: "$topic".

Your role:
- Act as an OPPOSING debater who challenges the user's arguments constructively
- Help the user improve their debate skills through rigorous but respectful argumentation
- Respond point-by-point to what the user just said
- Use evidence, logic, and rhetorical techniques
- Maintain a professional yet conversational tone

User's last statement:
"$lastUserMessage"

CRITICAL RULES:
1. Keep response UNDER 40 words (2-3 sentences max)
2. Respond DIRECTLY to their last point
3. Make ONE clear argument or counter-argument
4. This is turn-based - you speak, then STOP for user's reply
5. Be assertive but respectful, like a debate tournament opponent
6. DO NOT use any markdown formatting (no asterisks, underscores, or special characters)
7. Write in plain text ONLY - speak naturally as if in a live debate

Your response:
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
        return "${msg.isUser ? 'User' : 'Assistant'}: ${msg.content}";
      }).join("\n\n");
      
      // STRICT ANALYSIS for learning
      final userMessages = messages.where((m) => m.isUser).toList();
      final userMessageCount = userMessages.length;
      final totalWords = userMessages.fold(0, (sum, msg) => sum + msg.content.split(RegExp(r'\s+')).length);
      final avgWordsPerMessage = userMessageCount > 0 ? totalWords / userMessageCount : 0;
      final allUserText = userMessages.map((m) => m.content.toLowerCase()).join(' ');
      
      // Count unique words for vocabulary check
      final uniqueWords = <String>{};
      for (final msg in userMessages) {
        uniqueWords.addAll(msg.content.toLowerCase().split(RegExp(r'[^\w]+')).where((w) => w.isNotEmpty));
      }
      
      // CRITICAL: Detect contradictions
      bool hasContradiction = false;
      final positiveWords = ['beneficial', 'good', 'agree', 'support', 'yes', 'positive', 'helpful', 'useful', 'advantage'];
      final negativeWords = ['harmful', 'bad', 'disagree', 'oppose', 'no', 'negative', 'problem', 'lazy', 'dangerous', 'worse'];
      
      int positiveCount = positiveWords.where((w) => allUserText.contains(w)).length;
      int negativeCount = negativeWords.where((w) => allUserText.contains(w)).length;
      
      if (positiveCount > 0 && negativeCount > 0) {
        hasContradiction = true;
      }
      
      // Detect logical connectors
      final logicalConnectors = ['because', 'therefore', 'thus', 'since', 'hence', 'however'];
      int connectorCount = logicalConnectors.where((c) => allUserText.contains(c)).length;
      
      // Check for meaningless input
      bool isMeaningless = totalWords < 5 || uniqueWords.length < 3;
      
      final prompt = """
You are a VERY STRICT debate coach for a LEARNING platform. Give HARSH but HONEST scores to help users improve.

Topic: "$topic"
Transcript:
$transcript

ANALYSIS:
- Messages: $userMessageCount
- Total words: $totalWords
- Avg words/message: ${avgWordsPerMessage.toStringAsFixed(1)}
- Unique words: ${uniqueWords.length}
- Logical connectors: $connectorCount
- **CONTRADICTION: ${hasContradiction ? 'YES - argues both sides!' : 'NO'}**
- **MEANINGLESS: ${isMeaningless ? 'YES - too brief!' : 'NO'}**

STRICT LEARNING SCALE (Be HARSH):
0.0-0.2: Terrible - contradictions, nonsense, no effort
0.2-0.35: Very Poor - major flaws
0.35-0.45: Poor - weak arguments
0.45-0.52: Below Average - basic attempt
0.52-0.60: Average - single decent argument
0.60-0.70: Above Average - multiple good arguments
0.70-0.80: Strong - well-developed arguments
0.80-1.0: Exceptional - rare, near-perfect

CRITICAL PENALTIES:
- Contradiction (both pro AND con): Logic=0.10, Coherence=0.10, Persuasion=0.15
- Meaningless (<5 words): ALL skills=0.20
- Single message: MAX 0.50 overall
- No connectors: Logic MAX 0.45

BE HARSH - this is for learning! A simple argument should get ~0.42-0.48, NOT 0.75!

Return ONLY JSON:
{
  "skillRatings": {
    "clarity": <0.0-1.0>,
    "logic": <0.0-1.0>,
    "rebuttalQuality": <0.0-1.0>,
    "persuasiveness": <0.0-1.0>,
    "coherence": <0.0-1.0>,
    "articulation": <0.0-1.0>,
    "engagement": <0.0-1.0>,
    "tone": <0.0-1.0>
  },
  "strengths": ["<if any>"],
  "improvements": ["<specific issue>", "<another>"],
  "overallFeedback": "<harsh honest feedback>"
}
""";
      
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: _config,
      );
      
      final feedbackText = response.text ?? "{}";
      developer.log("Feedback response: $feedbackText", name: 'AIService');
      
      try {
        final jsonStart = feedbackText.indexOf('{');
        final jsonEnd = feedbackText.lastIndexOf('}') + 1;
        
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = feedbackText.substring(jsonStart, jsonEnd);
          final Map<String, dynamic> parsedJson = json.decode(jsonStr);
          
          // APPLY STRICT HARD CAPS
          if (parsedJson.containsKey('skillRatings')) {
            final ratings = parsedJson['skillRatings'] as Map<String, dynamic>;
            
            if (isMeaningless) {
              // Almost no content - maximum 0.20
              ratings.forEach((key, value) {
                if (value > 0.20) ratings[key] = 0.20;
              });
            } else if (hasContradiction) {
              // Catastrophic failure - maximum penalties
              if (ratings['logic'] > 0.10) ratings['logic'] = 0.10;
              if (ratings['coherence'] > 0.10) ratings['coherence'] = 0.10;
              if (ratings['persuasiveness'] > 0.15) ratings['persuasiveness'] = 0.15;
              if (ratings['clarity'] > 0.30) ratings['clarity'] = 0.30;
              if (ratings['articulation'] > 0.35) ratings['articulation'] = 0.35;
              if (ratings['engagement'] > 0.30) ratings['engagement'] = 0.30;
              if (ratings['tone'] > 0.40) ratings['tone'] = 0.40;
              if (ratings['rebuttalQuality'] > 0.30) ratings['rebuttalQuality'] = 0.30;
            } else {
              // Normal caps - STRICT
              if (userMessageCount == 1) {
                // Single message - cap at 0.50
                if (ratings['rebuttalQuality'] > 0.38) ratings['rebuttalQuality'] = 0.38;
                ratings.forEach((key, value) {
                  if (key != 'rebuttalQuality' && key != 'tone' && value > 0.50) {
                    ratings[key] = 0.50;
                  }
                });
              }
              
              if (avgWordsPerMessage < 10) {
                // Very brief - cap at 0.42
                if (ratings['clarity'] > 0.42) ratings['clarity'] = 0.42;
                if (ratings['persuasiveness'] > 0.42) ratings['persuasiveness'] = 0.42;
                if (ratings['articulation'] > 0.42) ratings['articulation'] = 0.42;
              }
              
              if (connectorCount == 0) {
                // No logical structure - cap logic
                if (ratings['logic'] > 0.45) ratings['logic'] = 0.45;
              }
            }
          }
          
          // Validate that all required fields exist
          if (parsedJson.containsKey('skillRatings') &&
              parsedJson.containsKey('strengths') &&
              parsedJson.containsKey('improvements') &&
              parsedJson.containsKey('overallFeedback')) {
            return parsedJson;
          } else {
            developer.log("Parsed JSON missing required fields: ${parsedJson.keys}", name: 'AIService');
          }
        }
      } catch (jsonError) {
        developer.log("Error parsing JSON: $jsonError", name: 'AIService');
      }
      
      // STRICT FALLBACK - much lower scores
      final baseScore = isMeaningless ? 0.18 :
                       hasContradiction ? 0.12 :
                       userMessageCount == 1 ? 0.40 :
                       avgWordsPerMessage < 10 ? 0.35 : 0.48;
      
      return {
        "skillRatings": {
          "clarity": isMeaningless ? 0.18 : (hasContradiction ? 0.30 : baseScore.clamp(0.0, 1.0)),
          "logic": isMeaningless ? 0.15 : (hasContradiction ? 0.10 : (baseScore + (connectorCount > 0 ? 0.03 : -0.05)).clamp(0.0, 1.0)),
          "rebuttalQuality": isMeaningless ? 0.15 : (userMessageCount == 1 ? 0.38 : baseScore.clamp(0.0, 1.0)),
          "persuasiveness": isMeaningless ? 0.15 : (hasContradiction ? 0.15 : baseScore.clamp(0.0, 1.0)),
          "coherence": isMeaningless ? 0.15 : (hasContradiction ? 0.10 : baseScore.clamp(0.0, 1.0)),
          "articulation": isMeaningless ? 0.18 : (baseScore + 0.02).clamp(0.0, 1.0),
          "engagement": isMeaningless ? 0.15 : (baseScore - 0.02).clamp(0.0, 1.0),
          "tone": isMeaningless ? 0.20 : (baseScore + 0.08).clamp(0.0, 1.0),
        },
        "strengths": hasContradiction ? ["Attempted to participate"] : ["Initiated debate", "Maintained appropriate tone"],
        "improvements": hasContradiction 
          ? [
              "CRITICAL: You contradicted yourself - argued both FOR and AGAINST!",
              "Choose ONE clear position before speaking",
              "Build ALL arguments to support your chosen side"
            ]
          : [
              "Develop longer arguments (15-20 words minimum)",
              "Use logical connectors (because, therefore, however)",
              "Add specific examples and evidence"
            ],
        "overallFeedback": hasContradiction
          ? "CRITICAL FAILURE: You argued both sides of the debate, which completely destroys your credibility. You must choose ONE position (for OR against) and stick to it. This is the worst possible debate error."
          : isMeaningless 
            ? "Your response is too brief to evaluate meaningfully. Provide at least 15-20 words with clear reasoning."
            : "Your debate shows initial engagement but needs significant development. Focus on: longer arguments with evidence, logical structure, and addressing opposing viewpoints. Current performance is below average - there's much room for improvement."
      };
    } catch (e) {
      developer.log("Critical error generating feedback: $e", name: 'AIService');
      
      // Even on error, return valid fallback data
      return {
        "skillRatings": {
          "clarity": 0.35,
          "logic": 0.35,
          "rebuttalQuality": 0.35,
          "persuasiveness": 0.35,
          "coherence": 0.35,
          "articulation": 0.35,
          "engagement": 0.35,
          "tone": 0.40,
        },
        "strengths": ["Participated in the debate"],
        "improvements": [
          "System error occurred - unable to provide detailed analysis",
          "Try again with clearer arguments",
          "Use logical structure and evidence"
        ],
        "overallFeedback": "We encountered a technical issue analyzing your debate. Please try again. Make sure to present clear, well-structured arguments with supporting evidence."
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

