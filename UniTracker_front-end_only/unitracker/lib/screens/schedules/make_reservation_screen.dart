import 'package:flutter/material.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/models/bus_route.dart';
import 'package:unitracker/utils/responsive_utils.dart';

class MakeReservationScreen extends StatefulWidget {
  final BusRoute route;

  const MakeReservationScreen({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  State<MakeReservationScreen> createState() => _MakeReservationScreenState();
}

class _MakeReservationScreenState extends State<MakeReservationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.primaryColor,
        title: Text(
          'Make Reservation',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Information',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                        ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                  Text(
                    'Route Name',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(4)),
                  Text(
                    widget.route.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: getProportionateScreenHeight(24)),
                  Text(
                    'Passenger Information',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                        ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              child: InkWell(
                onTap: () {
                  // Handle reservation confirmation
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: getProportionateScreenHeight(12),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor,
                    borderRadius: BorderRadius.circular(33),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: getProportionateScreenWidth(6),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: getProportionateScreenWidth(20),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Text(
                        'Confirm Reservation',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
