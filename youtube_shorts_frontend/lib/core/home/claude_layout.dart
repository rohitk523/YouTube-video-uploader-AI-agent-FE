import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

class ClaudeLayout extends StatefulWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final List<NavigationItem> navigationItems;
  final List<Widget> appBarActions;

  const ClaudeLayout({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.navigationItems,
    this.appBarActions = const [],
  });

  @override
  State<ClaudeLayout> createState() => _ClaudeLayoutState();
}

class _ClaudeLayoutState extends State<ClaudeLayout> with TickerProviderStateMixin {
  bool _isNavigationExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 60.0,
      end: 240.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigationExpanded = !_isNavigationExpanded;
      if (_isNavigationExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left Sidebar Navigation
          AnimatedBuilder(
            animation: _widthAnimation,
            builder: (context, child) {
              return Container(
                width: _widthAnimation.value,
                                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                ),
                child: Column(
                  children: [
                    // Sidebar Header
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                             decoration: BoxDecoration(
                         color: Theme.of(context).scaffoldBackgroundColor,
                       ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  onPressed: _toggleNavigation,
                                  icon: Icon(
                                    _isNavigationExpanded ? Icons.close : Icons.menu,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ),
                              if (_isNavigationExpanded && constraints.maxWidth > 80) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Navigation',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    
                    // Navigation Items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.navigationItems[index];
                          final isSelected = index == widget.currentIndex;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return _buildNavItem(
                                  context,
                                  icon: item.icon,
                                  label: _isNavigationExpanded && constraints.maxWidth > 80 ? item.label : null,
                                  onTap: () => widget.onNavigationChanged(index),
                                  isSelected: isSelected,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(context, isDark),
                
                // Main Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: widget.body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Spacer(),
            
            // App Bar Actions
            ...widget.appBarActions,
            
            // Theme Toggle Button
            _buildThemeToggle(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return PopupMenuButton<ThemeMode>(
          onSelected: (ThemeMode mode) {
            themeManager.setThemeMode(mode);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    size: 18,
                    color: themeManager.themeMode == ThemeMode.light 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('Light'),
                  const Spacer(),
                  if (themeManager.themeMode == ThemeMode.light)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    size: 18,
                    color: themeManager.themeMode == ThemeMode.dark 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('Dark'),
                  const Spacer(),
                  if (themeManager.themeMode == ThemeMode.dark)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(
                    Icons.settings_system_daydream,
                    size: 18,
                    color: themeManager.themeMode == ThemeMode.system 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('System'),
                  const Spacer(),
                  if (themeManager.themeMode == ThemeMode.system)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
                    child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF2D2D2D) 
                : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              if (label != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  
  const NavigationItem({
    required this.icon,
    required this.label,
  });
} 