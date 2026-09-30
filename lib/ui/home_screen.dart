import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../logic/dice_controller.dart';
import 'die_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final DiceController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  StreamSubscription? _shakeSub;
  DateTime _lastShake = DateTime(0);
  RollState _prev = RollState.idle;
  DiceController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: c.rollDuration, value: 1);
    c.addListener(_onChange);
    _syncShake();
  }

  void _onChange() {
    if (c.state == RollState.rolling && _prev != RollState.rolling) {
      _anim.forward(from: 0);
    }
    _prev = c.state;
    _syncShake();
  }

  void _syncShake() {
    if (c.shakeEnabled && _shakeSub == null) {
      _shakeSub = userAccelerometerEventStream().listen((e) {
        final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        final now = DateTime.now();
        if (g > 18 && now.difference(_lastShake).inMilliseconds > 1200) {
          _lastShake = now;
          c.roll();
        }
      }, onError: (_) {});
    } else if (!c.shakeEnabled) {
      _shakeSub?.cancel();
      _shakeSub = null;
    }
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    _shakeSub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Dice',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          actions: [
            IconButton(
              tooltip: c.muted ? 'Unmute sound' : 'Mute sound',
              icon: Icon(c.muted ? Icons.volume_off : Icons.volume_up),
              onPressed: c.toggleMute),
            IconButton(
              tooltip: 'Roll history',
              icon: const Icon(Icons.history),
              onPressed: () => _showHistory(context)),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth > box.maxHeight && box.maxWidth > 600;
            final stage = _stage(context, box);
            final panel = _panel(context);
            return wide
                ? Row(children: [
                    Expanded(flex: 3, child: stage),
                    Expanded(flex: 2, child: SingleChildScrollView(child: panel)),
                  ])
                : Column(children: [Expanded(child: stage), panel]);
          }),
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, BoxConstraints box) {
    final cs = Theme.of(context).colorScheme;
    final shown = c.values.isEmpty ? List.filled(c.count, 1) : c.values;
    final cols = c.count <= 3 ? c.count : (c.count == 4 ? 2 : 3);
    final size = min(120.0, (min(box.maxWidth, 700) - 48) / cols - 20);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(
            alignment: WrapAlignment.center, spacing: 20, runSpacing: 26,
            children: [
              for (var i = 0; i < shown.length; i++)
                DieView(value: shown[i], size: size, t: _anim, index: i,
                    dimmed: c.state == RollState.idle),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0, color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: Semantics(
                liveRegion: true,
                child: c.state == RollState.done
                    ? Column(children: [
                        Text('TOTAL', style: TextStyle(
                            color: cs.onSurfaceVariant, letterSpacing: 2, fontSize: 13)),
                        Text('${c.total}', key: const Key('total'),
                            style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800,
                                color: cs.primary)),
                        if (c.values.length > 1)
                          Text(c.values.join(' + '),
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                      ])
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          c.isRolling ? 'Rolling…' : 'Tap Roll to throw the dice',
                          key: const Key('status'),
                          style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant)),
                      ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<int>(
          key: const Key('countSelector'),
          showSelectedIcon: false,
          segments: [
            for (var n = 1; n <= 6; n++)
              ButtonSegment(value: n, label: Text('$n'), tooltip: '$n dice'),
          ],
          selected: {c.count},
          onSelectionChanged: c.isRolling ? null : (s) => c.setCount(s.first),
          style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 48))),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity, height: 68,
          child: FilledButton(
            key: const Key('rollButton'),
            onPressed: c.isRolling ? null : c.roll,
            style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: Text(c.state == RollState.done ? 'ROLL AGAIN' : 'ROLL',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextButton.icon(
              key: const Key('resetButton'),
              onPressed: c.isRolling ? null : c.reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Shake'),
              Switch(value: c.shakeEnabled, onChanged: c.setShake),
            ]),
          ),
        ]),
      ]),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => DraggableScrollableSheet(
          expand: false, initialChildSize: .6, maxChildSize: .9,
          builder: (context, sc) => Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Roll history', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                    onPressed: c.history.isEmpty ? null : c.clearHistory,
                    child: const Text('Clear')),
              ]),
            ),
            Expanded(
              child: c.history.isEmpty
                  ? const Center(child: Text('No rolls yet'))
                  : ListView.builder(
                      controller: sc, itemCount: c.history.length,
                      itemBuilder: (_, i) {
                        final r = c.history[i];
                        return ListTile(
                          title: Text(r.dice.join('  ·  '),
                              style: const TextStyle(fontSize: 18)),
                          subtitle: Text(
                              '${r.at.hour.toString().padLeft(2, '0')}:${r.at.minute.toString().padLeft(2, '0')}'),
                          trailing: Text('${r.total}', style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary)),
                        );
                      }),
            ),
          ]),
        ),
      ),
    );
  }
}
