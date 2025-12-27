import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  AIService();

  String get _apiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();

  String get _modelName =>
      (dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash').trim();

  GenerativeModel? _buildModel() {
    final key = _apiKey;
    if (key.isEmpty) return null;

    return GenerativeModel(
      model: _modelName,
      apiKey: key,
    );
  }

  Future<String> getAIResponse(String prompt) async {
    final p = prompt.trim();
    if (p.isEmpty) return "Mesaj boş.";

    final model = _buildModel();
    if (model == null) {
      return "AI servisi yapılandırılmadı. .env içine GEMINI_API_KEY ekleyin.";
    }

    try {
      final resp = await model.generateContent([Content.text(p)]);
      final t = (resp.text ?? '').trim();
      return t.isEmpty ? "Yanıt alınamadı." : t;
    } catch (e) {
      return "AI hata: $e\n\n"
          "Çözüm: .env içine GEMINI_MODEL=gemini-2.0-flash (veya gemini-2.5-flash) yazıp tekrar deneyin.";
    }
  }
}
