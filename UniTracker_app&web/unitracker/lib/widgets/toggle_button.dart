import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';

// For backward compatibility with existing code
class SegmentOption {
  final String text;
  final IconData icon;
  final String value;

  SegmentOption({
    required this.text,
    required this.icon,
    required this.value,
  });
}

class ToggleButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const ToggleButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding:
              EdgeInsets.symmetric(vertical: getProportionateScreenHeight(12)),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.secondary,
            borderRadius:
                BorderRadius.circular(getProportionateScreenWidth(33)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : Colors.grey[600],
                size: getProportionateScreenWidth(20),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Text(
                text,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToggleButtonPair extends StatelessWidget {
  final String firstText;
  final IconData firstIcon;
  final String secondText;
  final IconData secondIcon;
  final bool isFirstSelected;
  final Function(bool) onToggle;

  const ToggleButtonPair({
    super.key,
    required this.firstText,
    required this.firstIcon,
    required this.secondText,
    required this.secondIcon,
    required this.isFirstSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onToggle(true),
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(100)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: getProportionateScreenHeight(12),
                      horizontal: getProportionateScreenWidth(8)),
                  decoration: BoxDecoration(
                    color: isFirstSelected ? Colors.white : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(getProportionateScreenWidth(100)),
                    boxShadow: isFirstSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.shadowColor
                                  .withOpacity(0.1),
                              blurRadius: getProportionateScreenWidth(8),
                              offset:
                                  Offset(0, getProportionateScreenHeight(2)),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        firstIcon,
                        color: isFirstSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        size: getProportionateScreenWidth(18),
                      ),
                      SizedBox(width: getProportionateScreenWidth(4)),
                      Flexible(
                        child: Text(
                          firstText,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: isFirstSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenWidth(13),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onToggle(false),
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(100)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: getProportionateScreenHeight(12),
                      horizontal: getProportionateScreenWidth(8)),
                  decoration: BoxDecoration(
                    color: !isFirstSelected ? Colors.white : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(getProportionateScreenWidth(100)),
                    boxShadow: !isFirstSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.shadowColor
                                  .withOpacity(0.1),
                              blurRadius: getProportionateScreenWidth(8),
                              offset:
                                  Offset(0, getProportionateScreenHeight(2)),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        secondIcon,
                        color: !isFirstSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        size: getProportionateScreenWidth(18),
                      ),
                      SizedBox(width: getProportionateScreenWidth(4)),
                      Flexible(
                        child: Text(
                          secondText,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: !isFirstSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenWidth(13),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// For backward compatibility with existing CustomSegmentedButton usage
class CustomSegmentedButton extends StatelessWidget {
  final List<SegmentOption> options;
  final String selectedValue;
  final Function(String) onValueChanged;
  final TabController? tabController;

  const CustomSegmentedButton({
    Key? key,
    required this.options,
    required this.selectedValue,
    required this.onValueChanged,
    this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final bool isSelected = selectedValue == option.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: options.indexOf(option) == 0
                  ? 0
                  : getProportionateScreenWidth(12),
            ),
            child: ToggleButton(
              text: option.text,
              icon: option.icon,
              isSelected: isSelected,
              onPressed: () {
                onValueChanged(option.value);
                if (tabController != null) {
                  tabController!.animateTo(options.indexOf(option));
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
