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
              child: SizedBox(
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

class HomeButtonEditable extends StatelessWidget {
  const HomeButtonEditable({
    Key? key,
    required this.image,
    required this.text,
    required this.deleteOnTap,
    required this.editOnTap,
    this.fontSize = 18,
  }) : super(key: key);
  final String image;
  final String text;
  final VoidCallback deleteOnTap;
  final VoidCallback editOnTap;
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
              child: SizedBox(
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
      Column(
        children: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: deleteOnTap,
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.grey,
            ),
            onPressed: editOnTap,
          ),
        ],
      ),
    ]);
  }
}
