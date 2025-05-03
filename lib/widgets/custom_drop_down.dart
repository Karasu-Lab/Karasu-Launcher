import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final Widget? hintWidget;
  final double borderRadius;
  final EdgeInsetsGeometry itemPadding;
  final Color? dropdownColor;
  final Color? focusColor;
  final bool isDense;
  final bool isExpanded;
  final EdgeInsetsGeometry? buttonPadding;
  final double? dropdownWidth;
  final double? dropdownMaxHeight;
  final Widget? customButton;
  final Offset? offset;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final double? buttonHeight;
  final double? buttonWidth;
  final Color? buttonColor;
  final double? iconSize;
  final Widget? icon;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.hintWidget,
    this.borderRadius = 8.0,
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.dropdownColor,
    this.focusColor,
    this.isDense = false,
    this.isExpanded = true,
    this.buttonPadding,
    this.dropdownWidth,
    this.dropdownMaxHeight,
    this.customButton,
    this.offset,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.buttonHeight,
    this.buttonWidth,
    this.buttonColor,
    this.iconSize = 24,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 固定幅またはデフォルト値を使用
    final effectiveWidth = buttonWidth ?? 200.0;

    return Container(
      width: effectiveWidth,
      constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: buttonColor ?? theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          value: value,
          items: _buildItems(),
          onChanged: onChanged,
          hint: hintWidget ?? (hint != null ? Text(hint!) : null),
          isExpanded: isExpanded,
          isDense: isDense,
          dropdownStyleData: DropdownStyleData(
            maxHeight: dropdownMaxHeight ?? 200,
            width: dropdownWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: dropdownColor ?? theme.cardColor,
            ),
            offset: offset ?? const Offset(0, 0),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: WidgetStateProperty.all<double>(6),
              thumbVisibility: WidgetStateProperty.all<bool>(true),
            ),
          ),
          buttonStyleData: ButtonStyleData(
            height: buttonHeight,
            width: buttonWidth,
            padding:
                buttonPadding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: buttonColor ?? theme.cardColor,
            ),
          ),
          iconStyleData: IconStyleData(
            icon: icon ?? const Icon(Icons.arrow_drop_down),
            iconSize: iconSize ?? 24,
            iconEnabledColor: iconEnabledColor,
            iconDisabledColor: iconDisabledColor,
          ),
          menuItemStyleData: MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.only(
              left: itemPadding.horizontal / 2,
              right: itemPadding.horizontal / 2,
            ),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  List<DropdownMenuItem<T>> _buildItems() {
    return items.map((item) {
      return DropdownMenuItem<T>(
        value: item.value,
        child: Padding(padding: itemPadding, child: item.child),
      );
    }).toList();
  }
}
