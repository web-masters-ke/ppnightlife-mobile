import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double height;
  final double? width;
  final Widget? icon;
  final bool isLoading;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradient = AppColors.primaryGradient,
    this.height = 52,
    this.width,
    this.icon,
    this.isLoading = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: isLoading ? null : gradient,
          color: isLoading ? AppColors.purple.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
