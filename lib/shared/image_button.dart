// import 'package:flutter/material.dart';

// @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Parking Space'),
//       ),
//       body: _isLoading
//           ? Center(
//               child: CircularProgressIndicator(),
//             )
//           : SingleChildScrollView(
//               child: Container(
//                 padding: EdgeInsets.all(16.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // ...
//                       SizedBox(height: 16.0),
//                       Container(
//                         height: 200.0,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8.0),
//                           image: _image != null
//                               ? DecorationImage(
//                                   image: FileImage(_image!),
//                                   fit: BoxFit.cover,
//                                 )
//                               : DecorationImage(
//                                   image: AssetImage('assets/carpark.png'),
//                                   fit: BoxFit.cover,
//                                 ),
//                         ),
//                       ),
//                       SizedBox(height: 16.0),
//                       GestureDetector(
//                         onTap: _getImage,
//                         child: Container(
//                           height: 50.0,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.camera_alt),
//                               SizedBox(width: 8.0),
//                               Text('Change Image'),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 16.0),
//                       ElevatedButton(
//                         onPressed: _submitForm,
//                         child: Text('Save Changes'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }
// }