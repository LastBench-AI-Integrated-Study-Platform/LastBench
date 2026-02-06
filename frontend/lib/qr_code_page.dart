import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const QRCodePage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  late String sessionId;

  @override
  void initState() {
    super.initState();
    generateQR();
  }

  void generateQR() {
    sessionId =
        "pwd_reset_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("Scan the QR code to verify your identity"),

                const SizedBox(height: 20),

                QrImageView(
                  data: sessionId,
                  size: 250,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: widget.onNext,
                  child: const Text("Next Step"),
                ),

                TextButton(
                  onPressed: widget.onBack,
                  child: const Text("Back to Login"),
                ),

                TextButton(
                  onPressed: () {
                    setState(() => generateQR());
                  },
                  child: const Text("Generate New QR Code"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
