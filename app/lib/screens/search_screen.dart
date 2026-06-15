import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/voter.dart';
import '../widgets/voter_card.dart';
import 'detail_screen.dart';

enum SearchType { byName, bySerialNo, byVoterId, byHouseNumber }

class SearchScreen extends StatefulWidget {
  final SearchType searchType;

  const SearchScreen({super.key, required this.searchType});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Voter> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _errorMessage = '';

  // ── Metadata per search type ─────────────────────────────────────────────

  String get _titleTe => switch (widget.searchType) {
        SearchType.byName => 'పేరు ద్వారా వెతకండి',
        SearchType.bySerialNo => 'సీరియల్ నంబరు ద్వారా',
        SearchType.byVoterId => 'ఓటర్ ఐడి ద్వారా',
        SearchType.byHouseNumber => 'ఇంటి నంబరు ద్వారా',
      };

  String get _titleEn => switch (widget.searchType) {
        SearchType.byName => 'Search by Name',
        SearchType.bySerialNo => 'Search by Serial No.',
        SearchType.byVoterId => 'Search by Voter ID (EPIC)',
        SearchType.byHouseNumber => 'Search by House Number',
      };

  String get _hintTe => switch (widget.searchType) {
        SearchType.byName => 'పేరు టైప్ చేయండి (తెలుగు లో)…',
        SearchType.bySerialNo => 'సీరియల్ నంబరు టైప్ చేయండి…',
        SearchType.byVoterId => 'EPIC నంబరు టైప్ చేయండి…',
        SearchType.byHouseNumber => 'ఇంటి నంబరు టైప్ చేయండి…',
      };

  String get _hintEn => switch (widget.searchType) {
        SearchType.byName => 'e.g. రెడ్డి or రామి',
        SearchType.bySerialNo => 'e.g. 42',
        SearchType.byVoterId => 'e.g. AP271850405225',
        SearchType.byHouseNumber => 'e.g. 1-5',
      };

  Color get _accentColor => switch (widget.searchType) {
        SearchType.byName => const Color(0xFF2E7D32),
        SearchType.bySerialNo => const Color(0xFF5D4037),
        SearchType.byVoterId => const Color(0xFF1565C0),
        SearchType.byHouseNumber => const Color(0xFFBF360C),
      };

  // ── Search logic ─────────────────────────────────────────────────────────

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
      _errorMessage = '';
      _results = [];
    });

    try {
      List<Voter> results;
      switch (widget.searchType) {
        case SearchType.byName:
          results = await DbHelper.instance.searchByName(query);
        case SearchType.bySerialNo:
          results = await DbHelper.instance.searchBySerialNo(query);
        case SearchType.byVoterId:
          results = await DbHelper.instance.searchByVoterId(query);
        case SearchType.byHouseNumber:
          results = await DbHelper.instance.searchByHouseNumber(query);
      }
      setState(() => _results = results);
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleTe,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'NotoSansTelugu',
              ),
            ),
            Text(
              _titleEn,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _accentColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search, color: _accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: '${_hintEn}  •  ${_hintTe}',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400]),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _results = [];
                    _searched = false;
                  });
                },
              ),
            InkWell(
              onTap: _search,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accentColor),
            const SizedBox(height: 12),
            Text('వెతుకుతున్నాము…',
                style: TextStyle(fontFamily: 'NotoSansTelugu', color: Colors.grey[600])),
            Text('Searching…', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_searched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'ఫలితాలు లేవు',
              style: TextStyle(
                fontFamily: 'NotoSansTelugu',
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            Text(
              'No results found',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _hintTe,
              style: TextStyle(
                fontFamily: 'NotoSansTelugu',
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            Text(
              _hintEn,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildResultCount(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return VoterCard(
                voter: _results[index],
                accentColor: _accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(voter: _results[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCount() {
    final count = _results.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _accentColor.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: _accentColor),
          const SizedBox(width: 6),
          Text(
            '$count ఫలితాలు  •  $count result${count == 1 ? '' : 's'} found',
            style: TextStyle(
              fontSize: 13,
              color: _accentColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoSansTelugu',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
