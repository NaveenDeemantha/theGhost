import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../models/network_device.dart';
import '../models/device_type.dart';
import 'risk_score_service.dart';

class ReportService {
  static Future<void> generateAndShare({
    required String networkSsid,
    required String encryption,
    required String connectedIp,
    required List<NetworkDevice> devices,
    required RiskResult riskResult,
    required DateTime scanTime,
  }) async {
    final pdf = pw.Document();
    final cameras = devices.where((d) => d.isCamera).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Container(
            color: PdfColors.deepPurple,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TheGhost Network Report',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Generated: ${_formatDate(scanTime)}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Network Info
          _sectionTitle('Network Information'),
          _infoTable([
            ['SSID', networkSsid],
            ['Encryption', encryption],
            ['Your IP', connectedIp],
            ['Devices Found', '${devices.length}'],
            ['Cameras Detected', '${cameras.length}'],
          ]),
          pw.SizedBox(height: 20),

          // Risk Score
          _sectionTitle('Risk Assessment'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _riskColor(riskResult.level)),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Risk Score: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('${riskResult.score}/100 — ${riskResult.level.label}',
                        style: pw.TextStyle(
                            color: _riskColor(riskResult.level),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 8),
                ...riskResult.factors.map((f) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Text('• $f', style: const pw.TextStyle(fontSize: 11)),
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Cameras
          if (cameras.isNotEmpty) ...[
            _sectionTitle('Cameras Detected (${cameras.length})'),
            _deviceTable(cameras),
            pw.SizedBox(height: 20),
          ],

          // All Devices
          _sectionTitle('All Devices (${devices.length})'),
          _deviceTable(devices),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/theghost_report_${scanTime.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], subject: 'TheGhost Network Report — $networkSsid');
  }

  static pw.Widget _sectionTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(title,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple)),
      );

  static pw.Widget _infoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: rows.map((row) {
        return pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(row[0],
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 11)),
          ),
        ]);
      }).toList(),
    );
  }

  static pw.Widget _deviceTable(List<NetworkDevice> devices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['IP Address', 'Type', 'Manufacturer', 'Open Ports']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ))
              .toList(),
        ),
        ...devices.map((d) => pw.TableRow(children: [
              _cell(d.ipAddress),
              _cell(d.deviceType.label),
              _cell(d.manufacturer ?? '—'),
              _cell(d.openPorts.join(', ')),
            ])),
      ],
    );
  }

  static pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );

  static PdfColor _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return PdfColors.green;
      case RiskLevel.medium:
        return PdfColors.orange;
      case RiskLevel.high:
        return PdfColors.red;
      case RiskLevel.critical:
        return PdfColors.deepPurple;
    }
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
