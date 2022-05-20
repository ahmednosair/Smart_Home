import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({
    Key? key,
    required this.image,
    required this.text,
    required this.onTap,
    this.fontSize = 18,
  }) : super(key: key);
  final String image;
  final String text;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: [
          Expanded(
            child: Center(
              child: Container(
                width: Get.width / 5,
                height: Get.height / 10,
                child: Image.asset(
                  image,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
        ]),
      ),
    );
  }
}

class HomeButtonDeletable extends StatelessWidget {
  const HomeButtonDeletable({
    Key? key,
    required this.image,
    required this.text,
    required this.onTap,
    this.fontSize = 18,
  }) : super(key: key);
  final String image;
  final String text;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: [
          Expanded(
            child: Center(
              child: Container(
                width: Get.width / 5,
                height: Get.height / 10,
                child: Image.asset(
                  image,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
        ]),
      ),
      IconButton(
        icon: Icon(Icons.cancel,color: Colors.red,),
        onPressed: onTap,
      ),
    ]);
  }
}
