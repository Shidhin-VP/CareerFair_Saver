// lib/pages/image_preview_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:url_launcher/url_launcher.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imagePath;

  const ImagePreviewPage({super.key, required this.imagePath});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  String? qrData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanQRCode();
  }

  Future<void> _scanQRCode() async {
    try {
      final data = await QrCodeToolsPlugin.decodeFrom(widget.imagePath);
      if (data != null && Uri.tryParse(data)?.hasAbsolutePath == true) {
        setState(() {
          qrData = data;
        });
      }
    } catch (_) {
      // It's okay if there's no QR
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _openUrl() async {
    if (qrData != null && await canLaunchUrl(Uri.parse(qrData!))) {
      await launchUrl(Uri.parse(qrData!), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);
    return Scaffold(
      appBar: AppBar(title: const Text("Image Preview")),
      body: Column(
        children: [
          Expanded(child: Image.file(file, fit: BoxFit.contain)),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (!isLoading && qrData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _openUrl,
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Open QR Link"),
              ),
            ),
        ],
      ),
    );
  }
}
