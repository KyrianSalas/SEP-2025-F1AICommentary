import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/fastf1_browser_backdrop.dart';
import '../widgets/section_nav_bar.dart';

class CsvLibraryPage extends StatefulWidget {
  const CsvLibraryPage({
    super.key,
    this.getRequest,
    this.showNavigation = true,
  });

  final Future<http.Response> Function(Uri uri)? getRequest;
  final bool showNavigation;

  @override
  State<CsvLibraryPage> createState() => _CsvLibraryPageState();
}

class _CsvLibraryPageState extends State<CsvLibraryPage> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  List<String> _files = <String>[];
  _CsvRace? _selectedRace;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getRequest = widget.getRequest ?? http.get;
      final response = await getRequest(ApiConfig.api('csv/files'));
      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load CSV files (${response.statusCode}).';
        });
        return;
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawFiles =
          payload['files'] as List<dynamic>? ?? <dynamic>[];
      final List<String> files = rawFiles
          .map((dynamic entry) => entry.toString())
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _files = files;
        _selectedRace = _resolveSelectedRace(files);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Could not load CSV files. Check API availability.';
      });
    }
  }

  Future<void> _uploadCsv({
    required String filename,
    Uint8List? bytes,
    String? path,
  }) async {
    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final uri = ApiConfig.api('csv/upload');
      final request = http.MultipartRequest('POST', uri);

      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      } else if (path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', path, filename: filename),
        );
      } else {
        throw Exception('Cannot read selected file.');
      }

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(
          'Upload failed (${streamedResponse.statusCode}): $body',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      await _loadFiles();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uploaded $filename')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickAndUploadCsv() async {
    setState(() {
      _error = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }

      final PlatformFile selected = picked.files.first;
      await _uploadCsv(
        filename: selected.name,
        bytes: selected.bytes,
        path: selected.path,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _error = e.toString();
      });
    }
  }

  void _openPlayback(String filename) {
    context.go('/csv/playback?csv=${Uri.encodeQueryComponent(filename)}');
  }

  List<_CsvRace> get _csvRaces {
    return _files.map(_CsvRace.fromFilename).toList();
  }

  _CsvRace? get _activeRace {
    final selectedRace = _selectedRace;
    if (selectedRace != null && _files.contains(selectedRace.filename)) {
      return selectedRace;
    }
    return _files.isEmpty ? null : _CsvRace.fromFilename(_files.first);
  }

  _CsvRace? _resolveSelectedRace(List<String> files) {
    final selectedRace = _selectedRace;
    if (selectedRace != null && files.contains(selectedRace.filename)) {
      return selectedRace;
    }
    return files.isEmpty ? null : _CsvRace.fromFilename(files.first);
  }

  Widget _buildUploadCard() {
    final accent = _isUploading ? const Color(0xFFFFB347) : AppTheme.accentCyan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xE6171925),
            accent.withValues(alpha: 0.12),
            const Color(0xD10B0D13),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: _isUploading ? 0.20 : 0.10),
            blurRadius: _isUploading ? 30 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 620;
          final icon = Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.34)),
            ),
            child: Icon(Icons.upload_file_rounded, color: accent, size: 30),
          );
          final content = Column(
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                _isUploading ? 'Uploading CSV...' : 'Click to choose CSV',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: AppTheme.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only .csv files are accepted.',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: AppTheme.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: accent,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ],
          );
          final status = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Text(
              _isUploading ? 'Importing' : 'CSV import',
              style: AppTheme.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(child: content),
                const SizedBox(width: 16),
                status,
              ],
            );
          }

          return Column(
            children: [
              icon,
              const SizedBox(height: 14),
              content,
              const SizedBox(height: 14),
              status,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget backdrop = widget.showNavigation
        ? const FastF1BrowserBackdrop()
        : const ColoredBox(color: Color(0xFF0F131B));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: backdrop),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;
                final selectedRace = _activeRace;
                final showMobileLaunch =
                    !isWide && selectedRace != null && !_isLoading;
                final bottomPadding = showMobileLaunch ? 104.0 : 32.0;

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadFiles,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPadding),
                        children: <Widget>[
                          _CsvCommandBar(
                            showNavigation: widget.showNavigation,
                            fileCount: _files.length,
                            isLoading: _isLoading,
                            isUploading: _isUploading,
                            onRefresh: _isLoading ? null : _loadFiles,
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadCsv,
                            child: _buildUploadCard(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Available CSVs',
                                style: AppTheme.orbitron(fontSize: 14),
                              ),
                              TextButton.icon(
                                onPressed: _isLoading ? null : _loadFiles,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_error != null && _files.isNotEmpty) ...[
                            _CsvErrorPanel(
                              message: _error!,
                              onRetry: _loadFiles,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isLoading && _files.isEmpty)
                            const _CsvLoadingPanel()
                          else if (_error != null && _files.isEmpty)
                            _CsvErrorPanel(
                              message: _error!,
                              onRetry: _loadFiles,
                            )
                          else if (_files.isEmpty)
                            const _CsvEmptyPanel()
                          else if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _CsvRaceGrid(
                                    races: _csvRaces,
                                    selectedRace: selectedRace,
                                    onSelected: (race) {
                                      setState(() {
                                        _selectedRace = race;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(
                                  width: 360,
                                  child: _CsvPreviewPanel(
                                    race: selectedRace,
                                    onLaunch: selectedRace == null
                                        ? null
                                        : () => _openPlayback(
                                            selectedRace.filename,
                                          ),
                                  ),
                                ),
                              ],
                            )
                          else
                            _CsvRaceGrid(
                              races: _csvRaces,
                              selectedRace: selectedRace,
                              onSelected: (race) {
                                setState(() {
                                  _selectedRace = race;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    if (showMobileLaunch)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: _MobileCsvLaunchBar(
                          race: selectedRace,
                          onLaunch: () => _openPlayback(selectedRace.filename),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvSkeletonGrid extends StatelessWidget {
  const _CsvSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scanning uploaded telemetry library',
          style: AppTheme.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int columns = width >= 1060 ? 3 : (width >= 680 ? 2 : 1);
            const double gap = 16;
            final double cardWidth = (width - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(3, (index) {
                return SizedBox(
                  width: cardWidth,
                  child: const _CsvSkeletonCard(),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _CsvLoadingPanel extends StatelessWidget {
  const _CsvLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          ),
        ),
        _CsvSkeletonGrid(),
      ],
    );
  }
}

class _CsvSkeletonCard extends StatelessWidget {
  const _CsvSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 218,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xAA151823),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CsvSkeletonBlock(width: 44, height: 14),
              const Spacer(),
              _CsvSkeletonBlock(width: 82, height: 26, radius: 999),
            ],
          ),
          const SizedBox(height: 24),
          const _CsvSkeletonBlock(width: 210, height: 22),
          const SizedBox(height: 12),
          const _CsvSkeletonBlock(width: 142, height: 14),
          const Spacer(),
          const _CsvSkeletonBlock(width: double.infinity, height: 42),
        ],
      ),
    );
  }
}

class _CsvSkeletonBlock extends StatelessWidget {
  const _CsvSkeletonBlock({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _CsvErrorPanel extends StatelessWidget {
  const _CsvErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSV library unavailable',
            style: AppTheme.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTheme.inter(fontSize: 14, color: const Color(0xFFD4D8E4)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Retry',
              style: AppTheme.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvEmptyPanel extends StatelessWidget {
  const _CsvEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No CSV files found on the server yet.',
            style: AppTheme.orbitron(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload a telemetry CSV to add it to this browser.',
            style: AppTheme.inter(fontSize: 14, color: const Color(0xFFD4D8E4)),
          ),
        ],
      ),
    );
  }
}

class _CsvRaceGrid extends StatelessWidget {
  const _CsvRaceGrid({
    required this.races,
    required this.selectedRace,
    required this.onSelected,
  });

  final List<_CsvRace> races;
  final _CsvRace? selectedRace;
  final ValueChanged<_CsvRace> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1060 ? 3 : (width >= 680 ? 2 : 1);
        const double gap = 16;
        final double cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: races.map((race) {
            return SizedBox(
              width: cardWidth,
              child: _CsvRaceCard(
                race: race,
                isSelected: selectedRace?.filename == race.filename,
                onSelected: () => onSelected(race),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CsvRaceCard extends StatefulWidget {
  const _CsvRaceCard({
    required this.race,
    required this.isSelected,
    required this.onSelected,
  });

  final _CsvRace race;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  State<_CsvRaceCard> createState() => _CsvRaceCardState();
}

class _CsvRaceCardState extends State<_CsvRaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.race.statusAccent;
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onSelected,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 218,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isHighlighted
                    ? accent.withValues(alpha: 0.82)
                    : AppTheme.cardBorder,
                width: isHighlighted ? 1.4 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xE6171925),
                  accent.withValues(alpha: isHighlighted ? 0.18 : 0.08),
                  const Color(0xD10B0D13),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isHighlighted ? 0.28 : 0.08),
                  blurRadius: isHighlighted ? 30 : 12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.race.sourceLabel,
                      style: AppTheme.orbitron(
                        fontSize: 13,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    const Spacer(),
                    _CsvRaceStatusBadge(race: widget.race),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.race.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.race.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4D8E4),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CsvTelemetryPulsePainter(accent: accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CsvRaceStatusBadge extends StatelessWidget {
  const _CsvRaceStatusBadge({required this.race});

  final _CsvRace race;

  @override
  Widget build(BuildContext context) {
    final accent = race.statusAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Text(
        race.statusLabel,
        style: AppTheme.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _CsvPreviewPanel extends StatelessWidget {
  const _CsvPreviewPanel({required this.race, required this.onLaunch});

  final _CsvRace? race;
  final VoidCallback? onLaunch;

  @override
  Widget build(BuildContext context) {
    final race = this.race;
    if (race == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: AppTheme.glassCard(borderRadius: 24),
        child: Text('Select a CSV', style: AppTheme.orbitron(fontSize: 20)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                race.sourceLabel,
                style: AppTheme.orbitron(
                  fontSize: 13,
                  color: race.statusAccent,
                ),
              ),
              const Spacer(),
              _CsvRaceStatusBadge(race: race),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            race.title,
            style: AppTheme.orbitron(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _CsvPreviewFact(label: 'File', value: race.filename),
          _CsvPreviewFact(label: 'Location', value: race.location),
          _CsvPreviewFact(label: 'Source', value: 'Uploaded CSV'),
          _CsvPreviewFact(label: 'Session', value: 'CSV Playback'),
          _CsvPreviewFact(label: 'Status', value: race.statusLabel),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLaunch,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Play',
                style: AppTheme.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: race.statusAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvPreviewFact extends StatelessWidget {
  const _CsvPreviewFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCsvLaunchBar extends StatelessWidget {
  const _MobileCsvLaunchBar({required this.race, required this.onLaunch});

  final _CsvRace race;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF00D1017),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: race.statusAccent.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  race.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  race.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onLaunch,
            style: FilledButton.styleFrom(
              backgroundColor: race.statusAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Play',
              style: AppTheme.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvTelemetryPulsePainter extends CustomPainter {
  const _CsvTelemetryPulsePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.78)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (double x = 0; x <= size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), basePaint);
    }

    final path = Path();
    for (int i = 0; i <= 8; i++) {
      final x = size.width * (i / 8);
      final wave = i.isEven ? 0.36 : 0.68;
      final y = size.height * wave;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CsvTelemetryPulsePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _CsvRace {
  const _CsvRace({
    required this.filename,
    required this.title,
    required this.location,
  });

  factory _CsvRace.fromFilename(String filename) {
    final withoutExtension = filename.replaceAll(
      RegExp(r'\.csv$', caseSensitive: false),
      '',
    );
    final cleanName = withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final title = cleanName.isEmpty ? filename : _titleCase(cleanName);
    return _CsvRace(
      filename: filename,
      title: title,
      location: _locationFromName(cleanName),
    );
  }

  final String filename;
  final String title;
  final String location;

  String get sourceLabel => 'CSV';
  String get statusLabel => 'Ready';
  Color get statusAccent => const Color(0xFF39FF97);

  static String _locationFromName(String cleanName) {
    if (cleanName.isEmpty) {
      return 'Uploaded telemetry';
    }
    final parts = cleanName.split(' ');
    if (parts.length <= 2) {
      return 'Uploaded telemetry';
    }
    return _titleCase(parts.take(2).join(' '));
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _CsvCommandBar extends StatelessWidget {
  const _CsvCommandBar({
    required this.showNavigation,
    required this.fileCount,
    required this.isLoading,
    required this.isUploading,
    required this.onRefresh,
  });

  final bool showNavigation;
  final int fileCount;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isUploading
        ? 'Uploading CSV'
        : (isLoading ? 'Loading library' : 'Library ready');
    final pills = [
      const _CsvStatusPill(label: 'CSV telemetry', accent: AppTheme.accentCyan),
      _CsvStatusPill(
        label: '$fileCount races loaded',
        accent: AppTheme.accentRed,
      ),
      _CsvStatusPill(label: statusLabel, accent: const Color(0xFFFFB347)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 760;
          final title = Text(
            'CSV Race Browser',
            style: AppTheme.orbitron(
              fontSize: isWide ? 22 : 18,
              fontWeight: FontWeight.w800,
            ),
          );

          if (isWide) {
            return Row(
              children: [
                if (showNavigation) ...[
                  const SectionNavBar(currentRoute: '/csv'),
                  const SizedBox(width: 20),
                ],
                title,
                const Spacer(),
                Wrap(spacing: 10, runSpacing: 10, children: pills),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppTheme.textPrimary,
                  tooltip: 'Refresh CSV library',
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showNavigation) ...[
                    const SectionNavBar(currentRoute: '/csv'),
                    const SizedBox(width: 14),
                  ],
                  Expanded(child: title),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppTheme.textPrimary,
                    tooltip: 'Refresh CSV library',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: pills),
            ],
          );
        },
      ),
    );
  }
}

class _CsvStatusPill extends StatelessWidget {
  const _CsvStatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
