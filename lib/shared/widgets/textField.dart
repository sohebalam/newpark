import 'package:flutter/material.dart';

typedef StringValidator = String? Function(String?);

Widget textFieldWidget({
  required String title,
  // required IconData iconData,
  required TextEditingController controller,
  // required StringValidator? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xffA7A7A7))),
      const SizedBox(
        height: 6,
      ),
      Container(
        width: 400,
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 1)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: TextFormField(
          controller: controller,
          // validator: validator,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xffA7A7A7)),
          // decoration: InputDecoration(
          //   prefixIcon: Padding(
          //     padding: const EdgeInsets.only(left: 10),
          //     child: Icon(
          //       iconData,
          //       color: Colors.green,
          //     ),
          //   ),
          //   border: InputBorder.none,
          // ),
        ),
      )
    ],
  );
}
