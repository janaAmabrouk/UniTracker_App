import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class PostAuthSplashScreen extends StatefulWidget {
  final Duration delay;
  final VoidCallback onFinish;

  const PostAuthSplashScreen({
    super.key,
    this.delay = const Duration(seconds: 2),
    required this.onFinish,
  });

  @override
  State<PostAuthSplashScreen> createState() => _PostAuthSplashScreenState();
}

class _PostAuthSplashScreenState extends State<PostAuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(16),
            vertical: getProportionateScreenHeight(32),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(), // Top spacer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: getProportionateScreenWidth(80),
                    height: getProportionateScreenWidth(80),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bus_logo.png',
                        width: getProportionateScreenWidth(46),
                        height: getProportionateScreenWidth(46),
                        fit: BoxFit.contain,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(16)),
                  Text(
                    'UniTracker',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: getProportionateScreenWidth(36),
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    EdgeInsets.only(bottom: getProportionateScreenHeight(24)),
                child: Text(
                  'Know your bus, save your time',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
