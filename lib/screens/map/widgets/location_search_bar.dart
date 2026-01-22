import 'package:flutter/material.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:fittravel/theme.dart';

/// Location search bar with autocomplete for the map screen
class LocationSearchBar extends StatefulWidget {
  final Function(double lat, double lng, String locationName)
      onLocationSelected;
  final String? initialLocation;

  const LocationSearchBar({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  final FocusNode _focusNode = FocusNode();

  List<CitySuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Initialize with persisted location if available
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!;
    }
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Rebuild to update border styling on focus change
    setState(() {});

    if (!_focusNode.hasFocus) {
      // Hide suggestions when focus is lost (with delay for tap to register)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text;

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      final results = await _placesService.autocompleteCities(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('LocationSearchBar: Error fetching suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSuggestionTapped(CitySuggestion suggestion) async {
    setState(() {
      _searchController.text = suggestion.description;
      _showSuggestions = false;
      _isLoading = true;
    });

    _focusNode.unfocus();

    try {
      // Geocode the selected city to get coordinates
      final coordinates = await _placesService.geocodeCity(
        suggestion.city,
        country: suggestion.country,
      );

      if (coordinates != null && mounted) {
        widget.onLocationSelected(
          coordinates.$1,
          coordinates.$2,
          suggestion.description,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find location coordinates')),
        );
      }
    } catch (e) {
      debugPrint('LocationSearchBar: Error geocoding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error finding location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colors.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              suffixIcon: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colors.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderGold.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderGold.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Suggestions dropdown with premium styling
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderGold,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colors.outline.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSuggestionTapped(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.city,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (suggestion.subtitle != null)
                                  Text(
                                    suggestion.subtitle!,
                                    style: TextStyle(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
