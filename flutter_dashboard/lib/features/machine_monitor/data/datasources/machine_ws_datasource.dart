import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/data/models/machine_pulse_model.dart';

abstract class MachineWsDatasource {
  Stream<MachinePulseModel> watchPulses();
  void dispose();
}

class MachineWsDatasourceImpl implements MachineWsDatasource {
  MachineWsDatasourceImpl({required String wsUrl}) : _wsUrl = wsUrl;

  final String _wsUrl;
  WebSocketChannel? _channel;
  final _controller = StreamController<MachinePulseModel>.broadcast();

  @override
  Stream<MachinePulseModel> watchPulses() {
    _connect();
    return _controller.stream;
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _controller.addError(Exception('WS connect failed: $e'));
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      _controller.add(MachinePulseModel.fromJson(json));
    } catch (e) {
      _controller.addError(Exception('Parse error: $e'));
    }
  }

  void _onError(Object error) {
    _controller.addError(Exception('WS error: $error'));
    // Back-off reconnect — keeps the stream alive on transient failures
    Future.delayed(const Duration(seconds: 3), _connect);
  }

  void _onDone() {
    // Server closed — reconnect automatically
    Future.delayed(const Duration(seconds: 2), _connect);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
