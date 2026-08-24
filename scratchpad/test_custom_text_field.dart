import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller; //Why is texteditingcontroller not highlighted here like string and bool. it is highlighted in the functioning file.
  final String label; // label at the top of the text box?
  final String hint;
  final IconData? prefixIcon; //what's this?
  final bool obscureText; // how is this used for passwords?
  final Widget? suffixIcon; // what's this? 
  final TextInputType keyboardType; // what's this?
  final String? Function(String?)? validator; // I don't really understand this.
  final int maxLines;
  // also, why are some parts of flutter seprated by comma's and others by semicolons?

  const CustomTextField({ // just a constructor
    super.key,
    required this.controller, // why no TextEditingController controller = texteditingcontroller(); ?
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1, // where is this value in the field? 
  });

  @override
  Widget build(BuildContext context) { //overwriting stateless widgets original build
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // columns go down the page. cross axis means going horizontally? and .start means at the beginning of the column left?
      children: [
        Text(
          label, // what is this? why is it not label: 
          style: const TextStyle( //editing the text physicality
            fontSize:13,
            fontWeight: FontWeight.w500, //boldness?
            color: Color(0xFF1A1A2E), //Do we have to type the hexadecimal for this each time?
          ), // this paranthese and the next are supposed to have flutter's ghost comments that note the closing of any widget/feature. i.e. // TextStyle here and // Text in the next line. but it's not here?
        ),

        const SizedBox(height: 8), // just some buffer space, but it's always height and never width - why?
        
        TextFormField( // This textFormField is what exactly? the box that contains the text widget we just wrote above?
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines, // What are all these ":" ?
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A2E), 
          ),
        )
      ]
    )
  }
}