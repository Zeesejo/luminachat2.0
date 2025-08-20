import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ButtonVariant {
  filled,
  outlined,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    
    // Size configurations
    double height;
    double fontSize;
    EdgeInsetsGeometry buttonPadding;
    
    switch (size) {
      case ButtonSize.small:
        height = 36;
        fontSize = 14;
        buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        break;
      case ButtonSize.medium:
        height = 48;
        fontSize = 16;
        buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        break;
      case ButtonSize.large:
        height = 56;
        fontSize = 18;
        buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        break;
    }

    Widget buttonChild = _buildButtonContent(fontSize);

    Widget button;
    switch (variant) {
      case ButtonVariant.filled:
        button = ElevatedButton(
          onPressed: (isLoading || !isEnabled) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppTheme.primaryColor,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: buttonPadding,
            side: BorderSide(
              color: backgroundColor ?? AppTheme.primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? AppTheme.primaryColor,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    return button;
  }

  Widget _buildButtonContent(double fontSize) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.filled 
              ? Colors.white 
              : AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
