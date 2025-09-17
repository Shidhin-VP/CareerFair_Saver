import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/EntryModel/entryModel.dart';
import '../widgets/provider/providerFile.dart';

class DatePage extends StatefulWidget {
  final String dateKey;
  const DatePage({super.key, required this.dateKey});

  @override
  State<DatePage> createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _headController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _pickedImage;

  @override
  void dispose() {
    _employerController.dispose();
    _headController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission is required")),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _pickedImage = File(photo.path);
      });
    }
  }

  Future<void> _showAddEntryDialog() async {
    _employerController.clear();
    _headController.clear();
    _noteController.clear();
    _pickedImage = null;

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("Add Entry for ${widget.dateKey}")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _employerController,
                  decoration: InputDecoration(
                    labelText: "Employer Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _headController,
                  decoration: InputDecoration(
                    labelText: "Head",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: "Add Notes (Optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_pickedImage != null)
                  Image.file(_pickedImage!, height: 150),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickImageFromCamera,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final employer = _employerController.text.trim();
                final head = _headController.text.trim();
                final note = _noteController.text.trim().isNotEmpty
                    ? _noteController.text.trim()
                    : null;

                if (employer.isEmpty || head.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Employer and Head are required."),
                    ),
                  );
                  return;
                }

                final entry = EntryModel(
                  employerName: employer,
                  head: head,
                  note: note,
                  imagePath: _pickedImage?.path,
                );

                Provider.of<UpdateData>(
                  context,
                  listen: false,
                ).addEntryToDate(widget.dateKey, entry);

                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageDialog(File imageFile) async {
    String? qrData;
    try {
      qrData = await QrCodeToolsPlugin.decodeFrom(imageFile.path);
    } catch (_) {
      qrData = null;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: const Text("Image Preview")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(imageFile, height: 200),
              const SizedBox(height: 10),
              if (qrData != null)
                Text("QR Found:\n$qrData", textAlign: TextAlign.center),
            ],
          ),
          actions: [
            if (qrData != null && Uri.tryParse(qrData)?.hasAbsolutePath == true)
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(qrData!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cannot launch link")),
                    );
                  }
                },
                child: const Text("Go to Link"),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UpdateData>(context);
    final entries = provider.getEntriesForDate(widget.dateKey);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Entries for ${widget.dateKey}",style: TextStyle(fontFamily: "Asimovian"),)),elevation: 5,backgroundColor: Colors.limeAccent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? const Center(child: Text("No entries yet."))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  leading: e.imagePath != null
                      ? GestureDetector(
                          onTap: () => _showImageDialog(File(e.imagePath!)),
                          child: Image.file(
                            File(e.imagePath!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(e.employerName),
                  subtitle: Text(
                    "${e.head}${e.note != null ? " • ${e.note}" : ""}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.blueGrey),
                    onPressed: () {
                      provider.deleteEntry(widget.dateKey, e);
                    },
                  ),
                );
              },
            ),
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_code_tools/qr_code_tools.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../widgets/EntryModel/entryModel.dart';
// import '../widgets/provider/providerFile.dart';

// class DatePage extends StatefulWidget {
//   final String dateKey;
//   const DatePage({super.key, required this.dateKey});

//   @override
//   State<DatePage> createState() => _DatePageState();
// }

// class _DatePageState extends State<DatePage> {
//   final TextEditingController _employerController = TextEditingController();
//   final TextEditingController _headController = TextEditingController();
//   final TextEditingController _noteController = TextEditingController();
//   File? _pickedImage;

//   @override
//   void dispose() {
//     _employerController.dispose();
//     _headController.dispose();
//     _noteController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImageFromCamera() async {
//     final status = await Permission.camera.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Camera permission is required")),
//       );
//       return;
//     }

//     final ImagePicker picker = ImagePicker();
//     final XFile? photo = await picker.pickImage(source: ImageSource.camera);

//     if (photo != null) {
//       setState(() {
//         _pickedImage = File(photo.path);
//       });
//     }
//   }

//   Future<void> _showAddEntryDialog() async {
//     _employerController.clear();
//     _headController.clear();
//     _noteController.clear();
//     _pickedImage = null;

//     return showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Center(child: Text("Add Entry for ${widget.dateKey}")),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: _employerController,
//                   decoration: InputDecoration(
//                     labelText: "Employer Name",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _headController,
//                   decoration: InputDecoration(
//                     labelText: "Head",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _noteController,
//                   decoration: InputDecoration(
//                     labelText: "Add Notes (Optional)",
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 if (_pickedImage != null)
//                   Image.file(_pickedImage!, height: 150),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.camera_alt),
//                       onPressed: _pickImageFromCamera,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 final employer = _employerController.text.trim();
//                 final head = _headController.text.trim();
//                 final note = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null;

//                 if (employer.isEmpty || head.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Employer and Head are required.")),
//                   );
//                   return;
//                 }

//                 final entry = EntryModel(
//                   employerName: employer,
//                   head: head,
//                   note: note,
//                   imagePath: _pickedImage?.path,
//                 );

//                 Provider.of<UpdateData>(context, listen: false)
//                     .addEntryToDate(widget.dateKey, entry);

//                 Navigator.of(context).pop();
//               },
//               child: const Text("Add"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _showImageDialog(File imageFile) async {
//     String? qrData;
//     try {
//       qrData = await QrCodeToolsPlugin.decodeFrom(imageFile.path);
//     } catch (_) {
//       qrData = null;
//     }

//     return showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Center(child: const Text("Image Preview")),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.file(imageFile, height: 200),
//               const SizedBox(height: 10),
//               if (qrData != null)
//                 Text("QR Found:\n$qrData", textAlign: TextAlign.center),
//             ],
//           ),
//           actions: [
//             if (qrData != null && Uri.tryParse(qrData)?.hasAbsolutePath == true)
//               TextButton(
//                 onPressed: () async {
//                   final uri = Uri.parse(qrData!);
//                   if (await canLaunchUrl(uri)) {
//                     await launchUrl(uri, mode: LaunchMode.externalApplication);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Cannot launch link")),
//                     );
//                   }
//                 },
//                 child: const Text("Go to Link"),
//               ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text("Close"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<UpdateData>(context);
//     final entries = provider.getEntriesForDate(widget.dateKey);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Entries for ${widget.dateKey}"),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddEntryDialog,
//         child: const Icon(Icons.add),
//       ),
//       body: entries.isEmpty
//           ? const Center(child: Text("No entries yet."))
//           : ListView.builder(
//               itemCount: entries.length,
//               itemBuilder: (context, index) {
//                 final e = entries[index];
//                 return ListTile(
//                   leading: e.imagePath != null
//                       ? GestureDetector(
//                           onTap: () => _showImageDialog(File(e.imagePath!)),
//                           child: Image.file(
//                             File(e.imagePath!),
//                             width: 50,
//                             height: 50,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : const Icon(Icons.image_not_supported),
//                   title: Text(e.employerName),
//                   subtitle: Text("${e.head}${e.note != null ? " • ${e.note}" : ""}"),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete),
//                     onPressed: () {
//                       provider.deleteEntry(widget.dateKey, e);
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
