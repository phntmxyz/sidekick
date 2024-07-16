/// All information about a process that has completed.
abstract interface class ProcessCompletion {
  int? get exitCode;

  factory ProcessCompletion({
    required int exitCode,
  }) = _ProcessResult;
}

class _ProcessResult implements ProcessCompletion {
  @override
  final int? exitCode;

  _ProcessResult({
    required this.exitCode,
  });
}
