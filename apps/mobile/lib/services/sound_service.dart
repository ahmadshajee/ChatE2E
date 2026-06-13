import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Pool of players for keyboard clicks to support rapid concurrent keyboard clicks
  final List<AudioPlayer> _clickPlayers = [];
  int _nextClickPlayerIndex = 0;
  static const int _clickPoolSize = 5;

  late final AudioPlayer _sendPlayer;
  late final AudioPlayer _receivePlayer;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize click player pool
      for (int i = 0; i < _clickPoolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource('sounds/click.wav'));
        _clickPlayers.add(player);
      }

      _sendPlayer = AudioPlayer();
      await _sendPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _sendPlayer.setSource(AssetSource('sounds/send.wav'));

      _receivePlayer = AudioPlayer();
      await _receivePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _receivePlayer.setSource(AssetSource('sounds/receive.wav'));

      _initialized = true;
    } catch (e) {
      print('SoundService initialization failed: $e');
    }
  }

  Future<void> playClick() async {
    if (!_initialized) return;
    try {
      final player = _clickPlayers[_nextClickPlayerIndex];
      _nextClickPlayerIndex = (_nextClickPlayerIndex + 1) % _clickPoolSize;
      
      // Stop and resume immediately restarts it from beginning
      await player.stop();
      await player.resume();
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }

  Future<void> playSend() async {
    if (!_initialized) return;
    try {
      await _sendPlayer.stop();
      await _sendPlayer.resume();
    } catch (e) {
      print('Error playing send sound: $e');
    }
  }

  Future<void> playReceive() async {
    if (!_initialized) return;
    try {
      await _receivePlayer.stop();
      await _receivePlayer.resume();
    } catch (e) {
      print('Error playing receive sound: $e');
    }
  }
}
