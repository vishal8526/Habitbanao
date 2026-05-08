import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerStatus { idle, running, paused, finished }

class TimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final TimerStatus status;
  final String? linkedHabitId;
  final int sessionsToday;

  TimerState({
    this.totalSeconds = 1500,
    this.remainingSeconds = 1500,
    this.status = TimerStatus.idle,
    this.linkedHabitId,
    this.sessionsToday = 0,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    TimerStatus? status,
    String? linkedHabitId,
    int? sessionsToday,
    bool clearLinkedHabit = false,
  }) => TimerState(
    totalSeconds: totalSeconds ?? this.totalSeconds,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    status: status ?? this.status,
    linkedHabitId:
        clearLinkedHabit
            ? linkedHabitId
            : (linkedHabitId ?? this.linkedHabitId),
    sessionsToday: sessionsToday ?? this.sessionsToday,
  );

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(TimerState());
  Timer? _timer;

  void setDuration(int minutes) {
    _timer?.cancel();
    state = state.copyWith(
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
      status: TimerStatus.idle,
    );
  }

  void setLinkedHabit(String? habitId) {
    state = state.copyWith(linkedHabitId: habitId, clearLinkedHabit: true);
  }

  void start() {
    if (state.remainingSeconds <= 0) return;
    state = state.copyWith(status: TimerStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          status: TimerStatus.finished,
          sessionsToday: state.sessionsToday + 1,
        );
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() => start();

  void stop() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      status: TimerStatus.idle,
    );
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      status: TimerStatus.idle,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(),
);
