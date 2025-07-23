// lib/core/services/gemma_ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GemmaAIService {
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with your actual API key
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  static final GemmaAIService _instance = GemmaAIService._internal();
  factory GemmaAIService() => _instance;
  GemmaAIService._internal();

  // Language support mapping
  static const Map<String, String> _languagePrompts = {
    'en': 'As a medical AI assistant, analyze these symptoms and provide guidance:',
    'es': 'Como asistente médico de IA, analiza estos síntomas y proporciona orientación:',
    'fr': 'En tant qu\'assistant médical IA, analysez ces symptômes et fournissez des conseils:',
  };

  Future<SymptomAnalysisResult> analyzeSymptoms({
    required String symptoms,
    String language = 'en',
    Map<String, dynamic>? patientContext,
  }) async {
    try {
      final prompt = _buildMedicalPrompt(symptoms, language, patientContext);
      
      final response = await _makeApiCall(
        endpoint: 'models/gemma-2-2b-it:generateContent',
        payload: {
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.8,
            'maxOutputTokens': 1024,
          }
        }
      );

      return _parseSymptomAnalysis(response);
    } catch (e) {
      debugPrint('Error analyzing symptoms: $e');
      throw AIAnalysisException('Failed to analyze symptoms: $e');
    }
  }

  String _buildMedicalPrompt(String symptoms, String language, Map<String, dynamic>? context) {
    final languagePrompt = _languagePrompts[language] ?? _languagePrompts['en']!;
    
    return '''
$languagePrompt

Patient Symptoms: $symptoms

${context != null ? 'Patient Context: ${jsonEncode(context)}' : ''}

Please provide analysis in this JSON format:
{
  "primary_conditions": [
    {
      "condition": "condition name",
      "confidence": 0.0-1.0,
      "description": "brief description"
    }
  ],
  "urgency_level": "low|medium|high|emergency",
  "recommended_actions": ["action1", "action2"],
  "warning_signs": ["sign1", "sign2"],
  "follow_up_needed": boolean,
  "disclaimer": "medical disclaimer text"
}

Important: 
- This is for informational purposes only
- Always recommend consulting healthcare professionals
- Be conservative with urgency assessment
''';
  }

  Future<Map<String, dynamic>> _makeApiCall({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint?key=$_apiKey');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw HttpException('API call failed: ${response.statusCode} - ${response.body}');
    }
  }

  SymptomAnalysisResult _parseSymptomAnalysis(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const FormatException('No candidates in response');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List<dynamic>;
      final text = parts.first['text'] as String;

      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (jsonMatch != null) {
        final jsonData = jsonDecode(jsonMatch.group(0)!);
        return SymptomAnalysisResult.fromJson(jsonData);
      }

      return SymptomAnalysisResult.fromText(text);
    } catch (e) {
      debugPrint('Error parsing symptom analysis: $e');
      return SymptomAnalysisResult.error('Failed to parse analysis');
    }
  }
}

class SymptomAnalysisResult {
  final List<MedicalCondition> primaryConditions;
  final UrgencyLevel urgencyLevel;
  final List<String> recommendedActions;
  final List<String> warningSigns;
  final bool followUpNeeded;
  final String disclaimer;
  final bool isError;
  final String? errorMessage;

  SymptomAnalysisResult({
    required this.primaryConditions,
    required this.urgencyLevel,
    required this.recommendedActions,
    required this.warningSigns,
    required this.followUpNeeded,
    required this.disclaimer,
    this.isError = false,
    this.errorMessage,
  });

  factory SymptomAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysisResult(
      primaryConditions: (json['primary_conditions'] as List<dynamic>?)
          ?.map((e) => MedicalCondition.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      urgencyLevel: UrgencyLevel.fromString(json['urgency_level'] as String? ?? 'low'),
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
      warningSigns: List<String>.from(json['warning_signs'] ?? []),
      followUpNeeded: json['follow_up_needed'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? 'This is for informational purposes only.',
    );
  }

  factory SymptomAnalysisResult.fromText(String text) {
    return SymptomAnalysisResult(
      primaryConditions: [
        MedicalCondition(
          condition: 'General Assessment',
          confidence: 0.5,
          description: text,
        )
      ],
      urgencyLevel: UrgencyLevel.low,
      recommendedActions: ['Consult with a healthcare professional'],
      warningSigns: [],
      followUpNeeded: true,
      disclaimer: 'This is for informational purposes only.',
    );
  }

  factory SymptomAnalysisResult.error(String error) {
    return SymptomAnalysisResult(
      primaryConditions: [],
      urgencyLevel: UrgencyLevel.low,
      recommendedActions: [],
      warningSigns: [],
      followUpNeeded: false,
      disclaimer: '',
      isError: true,
      errorMessage: error,
    );
  }
}

class MedicalCondition {
  final String condition;
  final double confidence;
  final String description;

  MedicalCondition({
    required this.condition,
    required this.confidence,
    required this.description,
  });

  factory MedicalCondition.fromJson(Map<String, dynamic> json) {
    return MedicalCondition(
      condition: json['condition'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }
}

enum UrgencyLevel {
  low,
  medium,
  high,
  emergency;

  static UrgencyLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'medium': return UrgencyLevel.medium;
      case 'high': return UrgencyLevel.high;
      case 'emergency': return UrgencyLevel.emergency;
      default: return UrgencyLevel.low;
    }
  }
}

class AIAnalysisException implements Exception {
  final String message;
  AIAnalysisException(this.message);
  
  @override
  String toString() => 'AIAnalysisException: $message';
}