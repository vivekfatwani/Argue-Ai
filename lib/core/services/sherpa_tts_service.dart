import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:audioplayers/audioplayers.dart';

/// Sherpa-ONNX Text-to-Speech Service
/// 100% FREE, OFFLINE, High Quality Neural Voice
/// 
/// Features:
/// - No API keys required
/// - Works offline
/// - Fast generation (~100ms)
/// - Natural human-like voice
/// - Small model size (~30MB)
class SherpaTTSService {
  sherpa_onnx.OfflineTts? _tts;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool _isInitialized = false;
  
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the TTS engine with voice model
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      print('[SherpaTTS] Initializing...');
      
      // Get the directory to store models
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/sherpa_models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }
      
      // Copy models from assets to app directory
      await _copyAssetToFile(
        'assets/sherpa_models/vits-piper-en_US-lessac-medium.onnx',
        '${modelDir.path}/model.onnx',
      );
      await _copyAssetToFile(
        'assets/sherpa_models/tokens.txt',
        '${modelDir.path}/tokens.txt',
      );
      await _copyAssetToFile(
        'assets/sherpa_models/espeak-ng-data',
        '${modelDir.path}/espeak-ng-data',
      );
      
      // Configure TTS
      final vitsModelConfig = sherpa_onnx.OfflineTtsVitsModelConfig(
        model: '${modelDir.path}/model.onnx',
        lexicon: '',
        tokens: '${modelDir.path}/tokens.txt',
        dataDir: '${modelDir.path}/espeak-ng-data',
        noiseScale: 0.667,
        noiseScaleW: 0.8,
        lengthScale: 1.0,
      );
      
      final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
        vits: vitsModelConfig,
        numThreads: 2,
        debug: true,
        provider: 'cpu',
      );
      
      final config = sherpa_onnx.OfflineTtsConfig(
        model: modelConfig,
        ruleFsts: '',
        maxNumSentences: 2,
      );
      
      _tts = sherpa_onnx.OfflineTts(config);
      _isInitialized = true;
      
      print('[SherpaTTS] Initialized successfully');
      
    } catch (e) {
      print('[SherpaTTS] Initialization error: $e');
      _isInitialized = false;
    }
  }
  
  /// Copy asset file to app directory
  Future<void> _copyAssetToFile(String assetPath, String targetPath) async {
    try {
      final file = File(targetPath);
      if (await file.exists()) {
        print('[SherpaTTS] Model already exists: $targetPath');
        return;
      }
      
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('[SherpaTTS] Copied: $assetPath');
    } catch (e) {
      print('[SherpaTTS] Error copying asset $assetPath: $e');
      throw Exception('Failed to copy model file');
    }
  }
  
  /// Speak text using neural voice
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    if (!_isInitialized || _tts == null) {
      print('[SherpaTTS] Not initialized, initializing now...');
      await init();
    }
    
    if (_tts == null) {
      print('[SherpaTTS] ERROR: Failed to initialize');
      return;
    }
    
    // Clean text: Remove markdown formatting and prefixes
    String cleanText = text
        .replaceAll('*', '')
        .replaceAll('_', '')
        .replaceAll('#', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(RegExp(r'^AI:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^User:\s*', caseSensitive: false), '')
        .trim();
    
    if (cleanText.isEmpty) return;
    
    try {
      _isSpeaking = true;
      print('[SherpaTTS] Generating speech for: ${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}...');
      
      // Generate audio from text (fast, ~100ms)
      final audio = _tts!.generate(
        text: cleanText,
        sid: 0,  // Speaker ID
        speed: 1.0,  // Normal speed
      );
      
      if (audio == null || audio.samples.isEmpty) {
        print('[SherpaTTS] ERROR: No audio generated');
        _isSpeaking = false;
        return;
      }
      
      print('[SherpaTTS] Audio generated: ${audio.samples.length} samples, ${audio.sampleRate}Hz');
      
      // Convert Float32List to WAV file
      final tempDir = await getTemporaryDirectory();
      final wavFile = File('${tempDir.path}/sherpa_audio.wav');
      await _saveAsWav(wavFile, audio.samples, audio.sampleRate);
      
      print('[SherpaTTS] Playing audio...');
      
      // Play audio
      await _audioPlayer.play(DeviceFileSource(wavFile.path));
      
      // Wait for completion
      await _audioPlayer.onPlayerComplete.first;
      
      print('[SherpaTTS] Speech completed');
      
    } catch (e) {
      print('[SherpaTTS] Error: $e');
    } finally {
      _isSpeaking = false;
    }
  }
  
  /// Save audio samples as WAV file
  Future<void> _saveAsWav(File file, Float32List samples, int sampleRate) async {
    // Convert Float32 samples to Int16 PCM
    final int16Samples = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      int16Samples[i] = (samples[i] * 32767).round().clamp(-32768, 32767);
    }
    
    // Create WAV header
    final byteData = ByteData(44 + int16Samples.lengthInBytes);
    
    // RIFF chunk
    byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    byteData.setUint32(4, 36 + int16Samples.lengthInBytes, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    
    // fmt chunk
    byteData.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    byteData.setUint32(16, 16, Endian.little); // Chunk size
    byteData.setUint16(20, 1, Endian.little); // Audio format (PCM)
    byteData.setUint16(22, 1, Endian.little); // Number of channels
    byteData.setUint32(24, sampleRate, Endian.little); // Sample rate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    byteData.setUint16(32, 2, Endian.little); // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample
    
    // data chunk
    byteData.setUint32(36, 0x64617461, Endian.big); // "data"
    byteData.setUint32(40, int16Samples.lengthInBytes, Endian.little);
    
    // Copy PCM data
    final buffer = byteData.buffer.asUint8List();
    final pcmBytes = int16Samples.buffer.asUint8List();
    buffer.setRange(44, 44 + pcmBytes.length, pcmBytes);
    
    await file.writeAsBytes(buffer);
  }
  
  /// Stop speaking
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      print('[SherpaTTS] Speech stopped');
    } catch (e) {
      print('[SherpaTTS] Error stopping: $e');
      _isSpeaking = false;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      _isSpeaking = false;
      print('[SherpaTTS] Disposed');
    } catch (e) {
      print('[SherpaTTS] Error during disposal: $e');
    }
  }
}
