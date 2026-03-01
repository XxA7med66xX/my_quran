import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/utils.dart';

class ThemeTilesPicker extends StatelessWidget {
  const ThemeTilesPicker({
    required this.selected,
    required this.onChanged,
    required this.supportsDynamic,
    super.key,
    this.deviceLightScheme,
  });

  final AppTheme selected;
  final ValueChanged<AppTheme> onChanged;
  final bool supportsDynamic;
  final ColorScheme? deviceLightScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThemeTile(
          title: 'قرآني',
          description: 'المظهر الافتراضي الخاص بتطبيق "قرآني"',
          icon: Icons.auto_awesome_outlined,
          previewColors: (
            bg: const Color(0xFFFAFDFC),
            accent: const Color(0xFF0F766E),
          ),
          isSelected: selected == AppTheme.myQuran,
          onTap: () => onChanged(AppTheme.myQuran),
        ),
        _ThemeTile(
          title: 'سيبيا',
          description: 'ألوان مشابهة للورق، مريحة للعين',
          icon: Icons.menu_book_sharp,
          previewColors: (
            bg: const Color(0xFFF2E7DA),
            accent: const Color(0xFF7A5A3A),
          ),
          isSelected: selected == AppTheme.sepia,
          onTap: () => onChanged(AppTheme.sepia),
        ),

        if (supportsDynamic)
          _ThemeTile(
            title: 'ألوان جهازك',
            description: 'يستخدم ألوان جهازك الشخصية مع التبديل التلقائي',
            icon: Icons.palette_outlined,
            previewColors: (
              bg:
                  deviceLightScheme?.primaryContainer ??
                  const Color(0xFFE8DEF8),
              accent: deviceLightScheme?.primary ?? const Color(0xFF6750A4),
            ),
            isSelected: selected == AppTheme.dynamic,
            onTap: () => onChanged(AppTheme.dynamic),
          ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.previewColors,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final ({Color bg, Color accent}) previewColors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.applyOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.applyOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Color preview circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: previewColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: previewColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Check
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
