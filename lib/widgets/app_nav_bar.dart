import 'package:flutter/material.dart';
import 'app_language.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AppNavBar — shared bottom navigation bar.
//
//  The left square button shows the active language. Tapping it opens a small
//  popup above it with the other available languages.
//
//  Usage:
//    AppNavBar(
//      selectedIndex:    _selectedNav,
//      selectedLanguage: _selectedLanguage,
//      onTap:            _onNavTap,
//      onLanguageSelect: (lang) => setState(() => _selectedLanguage = lang),
//    )
// ═══════════════════════════════════════════════════════════════════════════════

class AppNavBar extends StatelessWidget {
  final int selectedIndex;
  final AppLanguage selectedLanguage;
  final ValueChanged<int> onTap;
  final ValueChanged<AppLanguage> onLanguageSelect;

  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.selectedLanguage,
    required this.onTap,
    required this.onLanguageSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _LanguageButton(
                language: selectedLanguage,
                onLanguageSelect: onLanguageSelect,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        label: 'Profile',
                        selected: selectedIndex == 0,
                        accentColor: selectedLanguage.accentColor,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        label: 'Study',
                        selected: selectedIndex == 1,
                        accentColor: selectedLanguage.accentColor,
                        onTap: () => onTap(1),
                      ),
                      _NavItem(
                        label: 'Courses',
                        selected: selectedIndex == 2,
                        accentColor: selectedLanguage.accentColor,
                        onTap: () => onTap(2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _LanguageButton extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageSelect;

  const _LanguageButton({
    required this.language,
    required this.onLanguageSelect,
  });

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const double _rowHeight = 44.0;
  static const double _popupVertPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    final renderBox =
    _key.currentContext!.findRenderObject() as RenderBox;
    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final others = widget.language.others;
    final popupHeight =
        others.length * _rowHeight + _popupVertPadding;

    setState(() => _isOpen = true);
    _animCtrl.forward(from: 0);

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: buttonOffset.dx,
            top: buttonOffset.dy - popupHeight - 8,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _LanguagePopup(
                  currentLanguage: widget.language,
                  buttonWidth: buttonSize.width,
                  onSelect: (lang) {
                    _close();
                    widget.onLanguageSelect(lang);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _close() {
    if (!_isOpen) return;
    _animCtrl.reverse().then((_) => _removeOverlay());
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.language.accentColor;

    return GestureDetector(
      key: _key,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 52,
        decoration: BoxDecoration(
          color: _isOpen ? accent : accent.withOpacity(0.88),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(_isOpen ? 0.55 : 0.35),
              blurRadius: _isOpen ? 18 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.language.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}


class _LanguagePopup extends StatelessWidget {
  final AppLanguage currentLanguage;
  final double buttonWidth;
  final ValueChanged<AppLanguage> onSelect;

  const _LanguagePopup({
    required this.currentLanguage,
    required this.buttonWidth,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final others = currentLanguage.others;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: buttonWidth + 88,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: const Color(0xFF2E2E2E), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: others
              .map((lang) =>
              _PopupItem(language: lang, onTap: () => onSelect(lang)))
              .toList(),
        ),
      ),
    );
  }
}

class _PopupItem extends StatefulWidget {
  final AppLanguage language;
  final VoidCallback onTap;

  const _PopupItem({required this.language, required this.onTap});

  @override
  State<_PopupItem> createState() => _PopupItemState();
}

class _PopupItemState extends State<_PopupItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.language.accentColor;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color:
          _pressed ? accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.language.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Colors.white
                : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
