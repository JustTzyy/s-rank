import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final bool applyFontScaling;
  final bool applySpacing;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.applyFontScaling = true,
    this.applySpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    // Apply font scaling and spacing
    Widget accessibleChild = child;
    
    if (applyFontScaling) {
      accessibleChild = MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: accessibilityService.fontScale,
        ),
        child: accessibleChild,
      );
    }
    
    return accessibleChild;
  }
}

class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? semanticLabel;
  final String? semanticHint;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.semanticLabel,
    this.semanticHint,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: Text(
        text,
        style: accessibilityService.getAccessibleTextStyle(
          style ?? const TextStyle(),
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AccessibleIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      child: Icon(
        icon,
        size: accessibilityService.getAccessibleIconSize(size ?? 24.0),
        color: color,
      ),
    );
  }
}

class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final ButtonStyle? style;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class AccessibleOutlinedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final ButtonStyle? style;

  const AccessibleOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: Card(
        margin: margin,
        child: Padding(
          padding: padding ?? accessibilityService.getAccessiblePadding(
            const EdgeInsets.all(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AccessibleSizedBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final bool applyScaling;

  const AccessibleSizedBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.applyScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (!applyScaling) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
    
    return SizedBox(
      width: width != null ? accessibilityService.getAccessibleSpacing(width!) : null,
      height: height != null ? accessibilityService.getAccessibleSpacing(height!) : null,
      child: child,
    );
  }
}

class AccessiblePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool applyScaling;

  const AccessiblePadding({
    super.key,
    required this.child,
    required this.padding,
    this.applyScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (!applyScaling) {
      return Padding(
        padding: padding,
        child: child,
      );
    }
    
    return Padding(
      padding: accessibilityService.getAccessiblePadding(padding),
      child: child,
    );
  }
}
