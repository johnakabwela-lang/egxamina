enum QuizStatus {
  waiting, // Quiz session created but not started
  active, // Quiz is in progress
  paused, // Quiz temporarily paused
  completed, // Quiz finished normally
  cancelled, // Quiz cancelled before completion
}
