import 'package:flutter/material.dart';
import 'package:fittravel/theme.dart';

/// Filter types for the map
enum MapFilterType {
  all,
  gyms,
  food,
  trails,
  events,
  strava,
  saved,
}

/// Dietary filter types for food
enum DietaryFilterType {
  healthy,
  vegan,
  vegetarian,
  halal,
  glutenFree,
}

/// Horizontal scrolling filter bar for map place types
class MapFilterBar extends StatelessWidget {
  final Set<MapFilterType> activeFilters;
  final ValueChanged<Set<MapFilterType>> onFilterChanged;
  final Set<DietaryFilterType> activeDietaryFilters;
  final ValueChanged<Set<DietaryFilterType>>? onDietaryFilterChanged;
  final bool isStravaAuthenticated;

  const MapFilterBar({
    super.key,
    required this.activeFilters,
    required this.onFilterChanged,
    this.activeDietaryFilters = const {},
    this.onDietaryFilterChanged,
    this.isStravaAuthenticated = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final showDietaryFilters = activeFilters.contains(MapFilterType.food) &&
        onDietaryFilterChanged != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                icon: Icons.layers,
                isSelected: activeFilters.contains(MapFilterType.all),
                onTap: () => _handleFilterTap(MapFilterType.all),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Gyms',
                icon: Icons.fitness_center,
                isSelected: activeFilters.contains(MapFilterType.gyms),
                onTap: () => _handleFilterTap(MapFilterType.gyms),
                colors: colors,
                markerColor: Colors.blue,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Food',
                icon: Icons.restaurant,
                isSelected: activeFilters.contains(MapFilterType.food),
                onTap: () => _handleFilterTap(MapFilterType.food),
                colors: colors,
                markerColor: Colors.orange,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Trails',
                icon: Icons.terrain,
                isSelected: activeFilters.contains(MapFilterType.trails),
                onTap: () => _handleFilterTap(MapFilterType.trails),
                colors: colors,
                markerColor: Colors.green,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Events',
                icon: Icons.event,
                isSelected: activeFilters.contains(MapFilterType.events),
                onTap: () => _handleFilterTap(MapFilterType.events),
                colors: colors,
                markerColor: Colors.purple,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Saved',
                icon: Icons.bookmark,
                isSelected: activeFilters.contains(MapFilterType.saved),
                onTap: () => _handleFilterTap(MapFilterType.saved),
                colors: colors,
                markerColor: AppColors.xp,
              ),
              if (isStravaAuthenticated) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Strava',
                  icon: Icons.directions_run,
                  isSelected: activeFilters.contains(MapFilterType.strava),
                  onTap: () => _handleFilterTap(MapFilterType.strava),
                  colors: colors,
                  markerColor: Colors.orange,
                ),
              ],
            ],
          ),
        ),
        // Dietary sub-filters when Food is selected
        if (showDietaryFilters) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _DietaryChip(
                  label: 'Healthy',
                  emoji: '🥗',
                  isSelected:
                      activeDietaryFilters.contains(DietaryFilterType.healthy),
                  onTap: () =>
                      _handleDietaryFilterTap(DietaryFilterType.healthy),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _DietaryChip(
                  label: 'Vegan',
                  emoji: '🌱',
                  isSelected:
                      activeDietaryFilters.contains(DietaryFilterType.vegan),
                  onTap: () => _handleDietaryFilterTap(DietaryFilterType.vegan),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _DietaryChip(
                  label: 'Vegetarian',
                  emoji: '🥬',
                  isSelected: activeDietaryFilters
                      .contains(DietaryFilterType.vegetarian),
                  onTap: () =>
                      _handleDietaryFilterTap(DietaryFilterType.vegetarian),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _DietaryChip(
                  label: 'Halal',
                  emoji: '🍖',
                  isSelected:
                      activeDietaryFilters.contains(DietaryFilterType.halal),
                  onTap: () => _handleDietaryFilterTap(DietaryFilterType.halal),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _DietaryChip(
                  label: 'Gluten-Free',
                  emoji: '🌾',
                  isSelected: activeDietaryFilters
                      .contains(DietaryFilterType.glutenFree),
                  onTap: () =>
                      _handleDietaryFilterTap(DietaryFilterType.glutenFree),
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _handleFilterTap(MapFilterType filter) {
    if (filter == MapFilterType.all) {
      // "All" toggles everything
      onFilterChanged({MapFilterType.all});
      return;
    }

    final newFilters = Set<MapFilterType>.from(activeFilters);

    // Remove "All" if selecting specific filter
    newFilters.remove(MapFilterType.all);

    if (newFilters.contains(filter)) {
      newFilters.remove(filter);
      // If nothing selected, default to "All"
      if (newFilters.isEmpty) {
        newFilters.add(MapFilterType.all);
      }
    } else {
      newFilters.add(filter);
    }

    onFilterChanged(newFilters);
  }

  void _handleDietaryFilterTap(DietaryFilterType filter) {
    if (onDietaryFilterChanged == null) return;

    final newFilters = Set<DietaryFilterType>.from(activeDietaryFilters);

    if (newFilters.contains(filter)) {
      newFilters.remove(filter);
    } else {
      newFilters.add(filter);
    }

    onDietaryFilterChanged!(newFilters);
  }
}

/// Dietary filter chip widget
class _DietaryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _DietaryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colors.onPrimaryContainer
                      : colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final Color? markerColor;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    this.markerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashFactory: InkRipple.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (markerColor != null && isSelected) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colors.onPrimaryContainer
                    : colors.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colors.onPrimaryContainer
                      : colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
