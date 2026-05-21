import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class OpenRouterService {
  /// Calls OpenRouter API completions endpoint with a priority model chain.
  /// Reports the active executing model back to the state via [onModelChange].
  Future<String> getCompletionsWithFailover({
    required String userPrompt,
    required String systemPrompt,
    required String apiKey,
    required Function(String activeModel) onModelChange,
    String? imageBase64,
  }) async {
    final keyToUse = apiKey.isNotEmpty ? apiKey : AppConstants.defaultApiKey;

    for (final model in AppConstants.openRouterModels) {
      try {
        onModelChange(model);
        final rawResponse = await _callModelWithRetries(model, userPrompt, systemPrompt, keyToUse, imageBase64);
        
        final decoded = json.decode(rawResponse);
        final content = decoded['choices'][0]['message']['content'] as String;
        
        return content;
      } catch (e) {
        // Log the failure to terminal and allow loop to move to the next model
        print('OpenRouterService: Model $model failed with error: $e. Moving to failover...');
      }
    }
    
    // If all models failed in the chain, throw exception to trigger offline LLM backup
    throw Exception('OpenRouterService: All online AI models timed out or failed.');
  }

  /// Sends a post request to OpenRouter with an 8-second timeout.
  /// Performs up to 2 retries (3 total attempts) per model on exception or rate limit.
  Future<String> _callModelWithRetries(
    String model, 
    String prompt, 
    String sysPrompt, 
    String key,
    String? imageBase64,
  ) async {
    const int maxAttempts = 3;
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final dynamic userMessageContent = imageBase64 != null
            ? [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$imageBase64',
                  }
                }
              ]
            : prompt;

        final response = await http.post(
          Uri.parse(AppConstants.openRouterApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
            'HTTP-Referer': 'https://pocketswasth.com',
            'X-Title': 'Pocket Swasth',
          },
          body: json.encode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': sysPrompt},
              {'role': 'user', 'content': userMessageContent}
            ],
            'max_tokens': 1000,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          return response.body;
        } else {
          throw Exception('OpenRouter API returned HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        if (attempt == maxAttempts) {
          // All retries failed for this model, rethrow to trigger next model
          rethrow;
        }
        // Wait 800ms before retrying to prevent rapid rate limiting
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    throw Exception('Failed to communicate with model $model after $maxAttempts attempts.');
  }

}
