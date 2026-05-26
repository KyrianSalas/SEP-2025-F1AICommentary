import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../theme/app_theme.dart';

class HomepageBackendStatus extends StatefulWidget {
  final Future<http.Response> Function(Uri) getRequest;
  final bool compact;

  const HomepageBackendStatus({
    super.key,
    this.getRequest = http.get,
    this.compact = false,
  });

  @override
  State<HomepageBackendStatus> createState() => _HomepageBackendStatusState();
}

class _HomepageBackendStatusState extends State<HomepageBackendStatus> {
  static final Uri _rootUri = ApiConfig.root;
  static final Uri _racesUri = ApiConfig.api('races');

  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isConnected = false;
  int? _raceCount;
  String _message = 'Checking backend status';
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!mounted) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final http.Response rootResponse = await widget
          .getRequest(_rootUri)
          .timeout(const Duration(seconds: 3));

      if (rootResponse.statusCode != 200) {
        throw Exception('Backend root returned ${rootResponse.statusCode}');
      }

      int? raceCount;
      String message = 'Backend connected';

      try {
        final http.Response racesResponse = await widget
            .getRequest(_racesUri)
            .timeout(const Duration(seconds: 4));

        if (racesResponse.statusCode == 200) {
          final dynamic decoded = jsonDecode(racesResponse.body);
          if (decoded is Map<String, dynamic>) {
            raceCount = decoded.values.fold<int>(
              0,
              (total, value) => total + (value is List ? value.length : 0),
            );
            message = raceCount > 0
                ? 'Race browser ready'
                : 'Backend online, waiting for race cache';
          }
        }
      } catch (_) {
        message = 'Backend online, race browser still loading';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isConnected = true;
        _raceCount = raceCount;
        _message = message;
        _lastChecked = DateTime.now();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isConnected = false;
        _raceCount = null;
        _message = 'Backend offline on ${ApiConfig.hostLabel}';
        _lastChecked = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _isConnected
        ? const Color(0xFF39FF97)
        : AppTheme.accentRed;
    final bool compact = widget.compact;

    return OutlinedButton(
      onPressed: () => _showStatusDialog(context, accent),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 9 : 12,
        ),
        side: BorderSide(color: accent.withValues(alpha: 0.36)),
        backgroundColor: const Color(0x5511141C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 999 : 18),
        ),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
          const SizedBox(width: 10),
          if (compact)
            Flexible(
              child: Text(
                _isConnected ? 'Backend online' : 'Backend offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.orbitron(fontSize: 10, color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isConnected ? 'Backend online' : 'Backend offline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context, Color accent) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F131B),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0x22FFFFFF)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'System status',
                        style: AppTheme.orbitron(fontSize: 14, color: accent),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isLoading ? null : _refresh,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        color: AppTheme.textMuted,
                        splashRadius: 18,
                        tooltip: 'Refresh backend status',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.55),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message,
                          style: AppTheme.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatusChip(
                        label: 'Backend',
                        value: _isConnected ? 'Online' : 'Offline',
                        accent: accent,
                      ),
                      _StatusChip(
                        label: 'Race list',
                        value: _raceCount == null
                            ? 'Pending'
                            : '$_raceCount loaded',
                        accent: _raceCount == null
                            ? const Color(0xFFFFD400)
                            : AppTheme.accentCyan,
                      ),
                      _StatusChip(
                        label: 'Last check',
                        value: _lastChecked == null
                            ? 'Just now'
                            : _formatTime(_lastChecked!),
                        accent: AppTheme.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: AppTheme.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    final String second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: AppTheme.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTheme.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
