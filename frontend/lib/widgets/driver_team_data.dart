import 'package:flutter/material.dart';

const Map<String, String> driverTeamAssets = {
  // Alfa Romeo / Sauber
  'BOT': 'assets/ALFAROMEO1.png',
  'ZHO': 'assets/ALFAROMEO2.png',
  'BOR': 'assets/ALFAROMEO1.png',
  'RAI': 'assets/ALFAROMEO1.png',
  'GIO': 'assets/ALFAROMEO2.png',
  'KUB': 'assets/ALFAROMEO1.png',
  'ERI': 'assets/ALFAROMEO2.png',

  // AlphaTauri / Toro Rosso
  'TSU': 'assets/ALPHATAURI1.png',
  'KVY': 'assets/ALPHATAURI2.png',
  'HAR': 'assets/ALPHATAURI1.png',
  'HAD': 'assets/ALPHATAURI2.png',
  'LAW': 'assets/ALPHATAURI2.png',
  'VRI': 'assets/ALPHATAURI1.png',
  'GAS': 'assets/ALPHATAURI2.png',
  'DEV': 'assets/ALPHATAURI1.png',
  'ALG': 'assets/ALPHATAURI2.png',

  // Alpine / Renault
  'OCO': 'assets/ALPINE1.png',
  'PAL': 'assets/ALPINE2.png',
  'HUL': 'assets/ALPINE1.png',
  'DOO': 'assets/ALPINE2.png',

  // Aston Martin / Racing Point
  'ALO': 'assets/ASTONMARTIN1.png',
  'DRU': 'assets/ASTONMARTIN1.png',
  'STR': 'assets/ASTONMARTIN2.png',

  // Ferrari
  'LEC': 'assets/FERRARI1.png',
  'SAI': 'assets/WILLIAMS1.png',
  'MAS': 'assets/FERRARI2.png',
  'VET': 'assets/FERRARI1.png',

  // Haas
  'MAG': 'assets/HAAS1.png',
  'MSC': 'assets/HAAS2.png',
  'GRO': 'assets/HAAS1.png',
  'MAZ': 'assets/HAAS2.png',
  'FIT': 'assets/HAAS1.png',
  'BEA': 'assets/HAAS2.png',
  'GUT': 'assets/HAAS1.png',

  // McLaren
  'NOR': 'assets/MCLAREN1.png',
  'BUT': 'assets/MCLAREN2.png',
  'VAN': 'assets/MCLAREN1.png',
  'PIA': 'assets/MCLAREN2.png',

  // Mercedes
  'HAM': 'assets/MERCEDES1.png',
  'ROS': 'assets/MERCEDES2.png',
  'ANT': 'assets/MERCEDES1.png',
  'RUS': 'assets/MERCEDES2.png',

  // Red Bull
  'VER': 'assets/REDBULL1.png',
  'WEB': 'assets/REDBULL2.png',
  'PER': 'assets/REDBULL1.png',
  'ALB': 'assets/REDBULL2.png',

  // Williams
  'SAR': 'assets/WILLIAMS1.png',
  'LAT': 'assets/WILLIAMS2.png',
};
const Map<String, String> driverTeams = {
  // Alfa Romeo / Sauber
  'BOT': 'Alfa Romeo',
  'ZHO': 'Alfa Romeo',
  'BOR': 'Kick Sauber',
  'RAI': 'Alfa Romeo',
  'GIO': 'Alfa Romeo',
  'KUB': 'Alfa Romeo',
  'ERI': 'Alfa Romeo',

  // AlphaTauri / Toro Rosso
  'TSU': 'Alpha Tauri',
  'KVY': 'Alpha Tauri',
  'HAR': 'Alpha Tauri',
  'HAD': 'RB',
  'LAW': 'Alpha Tauri',
  'VRI': 'Alpha Tauri',
  'GAS': 'Alpha Tauri',
  'DEV': 'Alpha Tauri',
  'ALG': 'Alpha Tauri',

  // Alpine / Renault
  'OCO': 'Alpine',
  'PAL': 'Alpine',
  'HUL': 'Alpine',
  'DOO': 'Alpine',

  // Aston Martin / Racing Point
  'ALO': 'Aston Martin',
  'DRU': 'Aston Martin',
  'STR': 'Aston Martin',

  // Ferrari
  'LEC': 'Ferrari',
  'SAI': 'Williams',
  'MAS': 'Ferari',
  'VET': 'Ferrari',

  // Haas
  'MAG': 'Haas',
  'MSC': 'Haas',
  'GRO': 'Haas',
  'MAZ': 'Haas',
  'FIT': 'Haas',
  'BEA': 'Haas',
  'GUT': 'Haas',

  // McLaren
  'NOR': 'Mclaren',
  'BUT': 'Mclaren',
  'VAN': 'Mclaren',
  'PIA': 'Mclaren',

  // Mercedes
  'HAM': 'Mercedes',
  'ROS': 'Mercedes',
  'ANT': 'Mercedes',
  'RUS': 'Mercedes',

  // Red Bull
  'VER': 'Red Bull',
  'WEB': 'Red Bull',
  'PER': 'Red Bull',
  'ALB': 'Red Bull  ',

  // Williams
  'SAR': 'Williams',
  'LAT': 'Williams',
};

const String defaultCarAsset = 'assets/FERRARI1.png';
const Color defaultTeamColor = Color(0xFF2F3640);

const Map<String, String> teamAssetsByName = {
  'alfa romeo': 'assets/ALFAROMEO1.png',
  'kick sauber': 'assets/ALFAROMEO1.png',
  'alphatauri': 'assets/ALPHATAURI1.png',
  'rb': 'assets/ALPHATAURI1.png',
  'alpine': 'assets/ALPINE1.png',
  'aston martin': 'assets/ASTONMARTIN1.png',
  'ferrari': 'assets/FERRARI1.png',
  'haas f1 team': 'assets/HAAS1.png',
  'haas': 'assets/HAAS1.png',
  'mclaren': 'assets/MCLAREN1.png',
  'mercedes': 'assets/MERCEDES1.png',
  'red bull': 'assets/REDBULL1.png',
  'williams': 'assets/WILLIAMS1.png',
};

const Map<String, String> teamNameAliases = {
  'alfa romeo racing': 'alfa romeo',
  'kick sauber ferrari': 'kick sauber',
  'kick sauber': 'kick sauber',
  'stake f1 team kick sauber': 'kick sauber',
  'stake f1 team kick sauber ferrari': 'kick sauber',
  'stake kick sauber': 'kick sauber',
  'sauber': 'kick sauber',
  'alphatauri': 'alphatauri',
  'alpha tauri': 'alphatauri',
  'scuderia alphatauri': 'alphatauri',
  'rb': 'rb',
  'rb f1 team': 'rb',
  'visa cash app rb': 'rb',
  'visa cash app rb f1 team': 'rb',
  'red bull racing': 'red bull',
  'oracle red bull racing': 'red bull',
  'mercedes-amg petronas': 'mercedes',
  'mercedes-amg petronas f1 team': 'mercedes',
  'scuderia ferrari': 'ferrari',
  'scuderia ferrari hp': 'ferrari',
  'mclaren formula 1 team': 'mclaren',
  'mclaren-mercedes': 'mclaren',
  'aston martin aramco': 'aston martin',
  'aston martin aramco f1 team': 'aston martin',
  'bwt alpine f1 team': 'alpine',
  'moneygram haas f1 team': 'haas f1 team',
  'haas': 'haas f1 team',
  'williams racing': 'williams',
};

const Map<String, Color> teamColorsByName = {
  'alfa romeo': Color(0xFF900000),
  'kick sauber': Color(0xFF52E252),
  'alphatauri': Color(0xFF2B4562),
  'rb': Color(0xFF6692FF),
  'alpine': Color(0xFF0090FF),
  'aston martin': Color(0xFF006F62),
  'ferrari': Color(0xFFDC0000),
  'ferari': Color(0xFFDC0000),
  'haas': Color(0xFFB6BABD),
  'haas f1 team': Color(0xFFB6BABD),
  'mclaren': Color(0xFFFF8700),
  'mercedes': Color(0xFF00D2BE),
  'red bull': Color(0xFF1E41FF),
  'williams': Color(0xFF005AFF),
};

String _normalizeTeamName(String teamName) {
  return teamName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _resolveTeamName(String? reportedTeam, String driverCode) {
  final preferred = reportedTeam?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    return preferred;
  }

  return driverTeams[driverCode];
}

String? getTeam(String driverCode, {String? reportedTeam}) {
  return _resolveTeamName(reportedTeam, driverCode);
}

String _canonicalizeTeamName(String teamName) {
  final normalized = _normalizeTeamName(teamName);
  return teamNameAliases[normalized] ?? normalized;
}

Color getTeamColor(String driverCode, {String? reportedTeam}) {
  final teamName = _resolveTeamName(reportedTeam, driverCode);
  if (teamName == null || teamName.isEmpty) {
    return defaultTeamColor;
  }

  return teamColorsByName[_canonicalizeTeamName(teamName)] ?? defaultTeamColor;
}

String getCarAsset(String driverCode, {String? reportedTeam}) {
  final teamName = reportedTeam?.trim();
  if (teamName != null && teamName.isNotEmpty) {
    final teamAsset = teamAssetsByName[_canonicalizeTeamName(teamName)];
    if (teamAsset != null && teamAsset.isNotEmpty) {
      return teamAsset;
    }
  }

  final driverAsset = driverTeamAssets[driverCode];
  if (driverAsset != null && driverAsset.isNotEmpty) {
    return driverAsset;
  }

  final fallbackTeamName = _resolveTeamName(reportedTeam, driverCode);
  if (fallbackTeamName == null || fallbackTeamName.isEmpty) {
    return defaultCarAsset;
  }

  return teamAssetsByName[_canonicalizeTeamName(fallbackTeamName)] ??
      defaultCarAsset;
}
