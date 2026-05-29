import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum AIProvider { gemini, anthropic, openai }

const _activeProvider = AIProvider.gemini;

const _geminiKey = 'AIzaSyC9qqcUt2e0Mo8LUgy_63dBSWg0cB6f-cs';
const _anthropicKey = '';
const _openaiKey = '';

class AIService {
  static Future<List<Map<String, dynamic>>> generateReadingMCQ({
    required String bookTitle,
    required int pageFrom,
    required int pageTo,
  }) async {
    debugPrint('=== generateReadingMCQ called for: $bookTitle ===');
    final prompt = '''
You are a reading verification assistant for an accountability app.

The user claims to have read "$bookTitle" from page $pageFrom to page $pageTo.

Generate exactly 3 multiple choice questions to verify they read those pages.

Rules:
- Each question has exactly 4 options
- Only one option is correct
- Make it fair but not too easy
- Options should be plausible, not obviously wrong

Respond ONLY with a JSON array. No preamble, no markdown.
Format:
[
  {
    "question": "Question text?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correct": 0
  }
]
Where "correct" is the index (0-3) of the correct answer.
''';

    try {
      switch (_activeProvider) {
        case AIProvider.gemini:
          return await _geminiMCQ(prompt, bookTitle, pageFrom, pageTo);
        case AIProvider.anthropic:
          return await _anthropicMCQ(prompt, bookTitle, pageFrom, pageTo);
        case AIProvider.openai:
          return await _openaiMCQ(prompt, bookTitle, pageFrom, pageTo);
      }
    } catch (e) {
      debugPrint('=== AI SERVICE ERROR: $e ===');
      return _fallbackMCQ(bookTitle, pageFrom, pageTo);
    }
  }

  // ── Gemini ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _geminiMCQ(
    String prompt,
    String bookTitle,
    int pageFrom,
    int pageTo,
  ) async {
    debugPrint('=== GEMINI REQUEST STARTING for: $bookTitle ===');
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$_geminiKey';

    for (int attempt = 0; attempt < 3; attempt++) {
      debugPrint('=== GEMINI attempt $attempt ===');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
          },
        }),
      );

      debugPrint('=== GEMINI response status: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        debugPrint('=== GEMINI SUCCESS ===');
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final clean =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final list = jsonDecode(clean) as List;
        return list.map((q) => Map<String, dynamic>.from(q)).toList();
      } else if (response.statusCode == 429) {
        debugPrint('=== GEMINI RATE LIMITED — waiting... ===');
        await Future.delayed(Duration(seconds: (attempt + 1) * 3));
      } else {
        debugPrint('=== GEMINI FAILED: ${response.statusCode} ${response.body} ===');
        throw Exception('Gemini error: ${response.body}');
      }
    }

    debugPrint('=== GEMINI ALL ATTEMPTS FAILED — using fallback ===');
    return _fallbackMCQ(bookTitle, pageFrom, pageTo);
  }

  // ── Anthropic (ready to activate) ──────────────────────────

  static Future<List<Map<String, dynamic>>> _anthropicMCQ(
    String prompt,
    String bookTitle,
    int pageFrom,
    int pageTo,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 800,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      final clean =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.map((q) => Map<String, dynamic>.from(q)).toList();
    }
    return _fallbackMCQ(bookTitle, pageFrom, pageTo);
  }

  // ── OpenAI (ready to activate) ──────────────────────────────

  static Future<List<Map<String, dynamic>>> _openaiMCQ(
    String prompt,
    String bookTitle,
    int pageFrom,
    int pageTo,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'max_tokens': 800,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final clean =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.map((q) => Map<String, dynamic>.from(q)).toList();
    }
    return _fallbackMCQ(bookTitle, pageFrom, pageTo);
  }

  // ── Fallback — book-specific questions ──────────────────────

  static List<Map<String, dynamic>> _fallbackMCQ(
    String bookTitle,
    int pageFrom,
    int pageTo,
  ) {
    debugPrint('=== USING FALLBACK for: $bookTitle ===');
    final title = bookTitle.toLowerCase();

    if (title.contains('atomic habits')) {
      return [
        {
          'question': 'What percentage of daily improvement does James Clear use to illustrate compound growth?',
          'options': ['0.5%', '1%', '5%', '10%'],
          'correct': 1,
        },
        {
          'question': 'What does Clear call habits built around identity rather than outcomes?',
          'options': ['Keystone habits', 'Identity-based habits', 'Atomic habits', 'Core habits'],
          'correct': 1,
        },
        {
          'question': 'How many Laws of Behavior Change does Clear introduce?',
          'options': ['3', '4', '5', '7'],
          'correct': 1,
        },
      ];
    }

    if (title.contains('48 laws')) {
      return [
        {
          'question': 'What is the central theme of Robert Greene\'s 48 Laws of Power?',
          'options': ['Kindness wins', 'Power requires strategy and awareness', 'Wealth comes from hard work', 'Relationships are everything'],
          'correct': 1,
        },
        {
          'question': 'Which approach does Greene consistently recommend when dealing with enemies?',
          'options': ['Confront them directly', 'Ignore them', 'Never outshine your master', 'Use indirect strategy'],
          'correct': 3,
        },
        {
          'question': 'What historical sources does Greene draw from most heavily?',
          'options': ['Modern business', 'Ancient philosophy only', 'Historical figures and royal courts', 'Military strategy only'],
          'correct': 2,
        },
      ];
    }

    if (title.contains('rich dad poor dad')) {
      return [
        {
          'question': 'How does Kiyosaki define an "asset"?',
          'options': ['Something you own', 'Something that puts money in your pocket', 'Your salary', 'A college degree'],
          'correct': 1,
        },
        {
          'question': 'What does the "rat race" refer to in the book?',
          'options': ['Stock market trading', 'Working for money to pay bills repeatedly', 'Competition between businesses', 'School education system'],
          'correct': 1,
        },
        {
          'question': 'What is the key financial lesson the "rich dad" teaches?',
          'options': ['Save more money', 'Get a better job', 'Make money work for you', 'Invest in bonds'],
          'correct': 2,
        },
      ];
    }

    if (title.contains('sapiens')) {
      return [
        {
          'question': 'What does Harari call the revolution that allowed Homo sapiens to dominate?',
          'options': ['Agricultural Revolution', 'Cognitive Revolution', 'Industrial Revolution', 'Social Revolution'],
          'correct': 1,
        },
        {
          'question': 'According to Harari, what enabled large groups of humans to cooperate?',
          'options': ['Shared DNA', 'Physical strength', 'Shared myths and collective beliefs', 'Geographic location'],
          'correct': 2,
        },
        {
          'question': 'How does Harari view the Agricultural Revolution?',
          'options': ['Humanity\'s greatest achievement', 'History\'s biggest fraud', 'A natural progression', 'A purely positive development'],
          'correct': 1,
        },
      ];
    }

    if (title.contains('alchemist')) {
      return [
        {
          'question': 'What does Coelho call the unique path each person is meant to follow?',
          'options': ['Soul\'s Journey', 'Personal Legend', 'Divine Path', 'True Calling'],
          'correct': 1,
        },
        {
          'question': 'What is the name of the main character in The Alchemist?',
          'options': ['Paulo', 'Santiago', 'Carlos', 'Miguel'],
          'correct': 1,
        },
        {
          'question': 'What does the Soul of the World represent in the novel?',
          'options': ['A physical treasure', 'A universal spiritual force', 'The desert', 'The Alchemist himself'],
          'correct': 1,
        },
      ];
    }

    if (title.contains('think and grow rich')) {
      return [
        {
          'question': 'What does Napoleon Hill identify as the starting point of all achievement?',
          'options': ['Education', 'Desire', 'Hard work', 'Connections'],
          'correct': 1,
        },
        {
          'question': 'What does Hill call the "master mind"?',
          'options': ['A single genius', 'A group of people working in harmony', 'Your subconscious', 'A meditation technique'],
          'correct': 1,
        },
        {
          'question': 'What role does faith play in Hill\'s philosophy?',
          'options': ['Religious belief only', 'A state of mind that can be self-induced', 'Blind trust', 'Social support'],
          'correct': 1,
        },
      ];
    }

    if (title.contains('7 habits') || title.contains('seven habits')) {
      return [
        {
          'question': 'What does Covey mean by "being proactive"?',
          'options': ['Working faster', 'Taking responsibility for your responses', 'Planning ahead', 'Being aggressive'],
          'correct': 1,
        },
        {
          'question': 'What is the second habit in Covey\'s framework?',
          'options': ['Put first things first', 'Begin with the end in mind', 'Think win-win', 'Seek first to understand'],
          'correct': 1,
        },
        {
          'question': 'What does Covey\'s "emotional bank account" metaphor describe?',
          'options': ['Financial savings', 'Trust in relationships', 'Time management', 'Personal goals'],
          'correct': 1,
        },
      ];
    }

    // Smart generic fallback
    return [
      {
        'question': 'What best describes the main theme of pages $pageFrom-$pageTo in "$bookTitle"?',
        'options': [
          'Introducing a new concept or character',
          'Building on a previous argument or plot point',
          'Providing a conclusion or resolution',
          'Offering historical or background context',
        ],
        'correct': 0,
      },
      {
        'question': 'Which word best describes the author\'s tone in this section?',
        'options': ['Analytical', 'Narrative', 'Philosophical', 'Instructional'],
        'correct': 0,
      },
      {
        'question': 'What is the reader most likely to take away from pages $pageFrom-$pageTo?',
        'options': [
          'A new idea or insight introduced for the first time',
          'A turning point in the story or argument',
          'Evidence for the book\'s central thesis',
          'A summary of earlier chapters',
        ],
        'correct': 0,
      },
    ];
  }
}