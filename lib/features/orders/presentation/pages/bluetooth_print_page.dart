import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../dashboard/models/order_summary.dart';

class BluetoothPrintPage extends StatefulWidget {
  const BluetoothPrintPage({
    super.key,
    required this.order,
  });

  final OrderSummary order;

  @override
  State<BluetoothPrintPage> createState() => _BluetoothPrintPageState();
}

class _BluetoothPrintPageState extends State<BluetoothPrintPage> {
  List<BluetoothInfo> _devices = [];
  String? _selectedMac;
  bool _loading = false;
  String? _status;
  bool _isPromptOpen = false;

  @override
  void initState() {
    super.initState();
    _status = 'Tap Print Label to preview first. Connect printer only when ready.';
  }

  @override
  void dispose() {
    // Fire-and-forget: disconnect the printer when the page is closed.
    unawaited(PrintBluetoothThermal.disconnect);
    super.dispose();
  }

  Future<void> _openAppSettings() async {
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Settings')),
      );
    }
  }

  Future<void> _showBluetoothPrompt({
    required String title,
    required String message,
  }) async {
    if (_isPromptOpen || !mounted) return;
    _isPromptOpen = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    _isPromptOpen = false;
  }

  Future<void> _ensurePermissions() async {
    setState(() {
      _loading = true;
      _status = 'Checking permissions...';
    });
    try {
      final permissionGranted = await PrintBluetoothThermal
          .isPermissionBluetoothGranted
          .timeout(const Duration(seconds: 5), onTimeout: () => true);
      if (!permissionGranted) {
        setState(() {
          _status =
              'Bluetooth permission is required. Please allow it in Settings.';
          _loading = false;
        });
        await _showBluetoothPrompt(
          title: 'Bluetooth Permission Required',
          message:
              'Enable Bluetooth permission in Settings to discover and connect to printers.',
        );
        return;
      }

      if (!Platform.isIOS && !Platform.isMacOS) {
        final enabled = await PrintBluetoothThermal.bluetoothEnabled
            .timeout(const Duration(seconds: 5), onTimeout: () => true);
        if (!enabled) {
          setState(() {
            _status = 'Please enable Bluetooth to continue';
            _loading = false;
          });
          await _showBluetoothPrompt(
            title: 'Bluetooth Off',
            message: 'Turn on Bluetooth to search for nearby printers.',
          );
          return;
        }
      }
      await _loadDevices();
    } catch (e) {
      setState(() {
        _status = 'Bluetooth unavailable: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _status = 'Loading paired devices...';
    });
    try {
      final result = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _devices = result;
        _status = _devices.isEmpty ? 'No paired devices found' : null;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load devices: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connect(String mac) async {
    setState(() {
      _loading = true;
      _status = 'Connecting...';
    });
    try {
      final permissionGranted = await PrintBluetoothThermal
          .isPermissionBluetoothGranted
          .timeout(const Duration(seconds: 5), onTimeout: () => true);
      if (!permissionGranted) {
        setState(
          () => _status = 'Bluetooth permission is required. Please allow it in Settings.',
        );
        await _showBluetoothPrompt(
          title: 'Bluetooth Permission Required',
          message: 'Enable Bluetooth permission in Settings to connect to printers.',
        );
        return;
      }
      if (!Platform.isIOS && !Platform.isMacOS) {
        final bonded = await PrintBluetoothThermal.bluetoothEnabled
            .timeout(const Duration(seconds: 5), onTimeout: () => true);
        if (!bonded) {
          setState(() => _status = 'Please enable Bluetooth');
          await _showBluetoothPrompt(
            title: 'Bluetooth Off',
            message: 'Turn on Bluetooth to connect to a printer.',
          );
          return;
        }
      }
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (ok) {
        setState(() {
          _selectedMac = mac;
          _status = 'Connected';
        });
      } else {
        setState(() => _status = 'Failed to connect');
      }
    } catch (e) {
      setState(() => _status = 'Failed to connect: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _printLabel() async {
    final packages = _packagesForPrint();
    setState(() {
      _loading = true;
      _status = 'Preparing preview...';
    });
    Uint8List? previewBytes;
    try {
      previewBytes = await _buildPreviewPng(widget.order, packages.first);
    } catch (_) {
      previewBytes = null;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    if (!mounted) return;
    if (previewBytes == null) {
      setState(() => _status = 'Failed to render preview');
      return;
    }
    final confirm = await _showPrintPreview(previewBytes);
    if (!confirm) {
      setState(() => _status = 'Print cancelled');
      return;
    }
    if (_selectedMac == null) {
      setState(
        () => _status = 'Preview ready. Select/connect a printer, then tap Print Label.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Printing...';
    });
    try {
      for (final pkg in packages) {
        final bytes = await _buildTsplBitmap(widget.order, pkg);
        await PrintBluetoothThermal.writeBytes(bytes.toList());
      }
      setState(() => _status = 'Print sent');
    } catch (e) {
      setState(() => _status = 'Print failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Bluetooth Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _ensurePermissions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_status != null) ...[
              Text(
                _status!,
                style: TextStyle(
                  color: _status!.toLowerCase().contains('failed') ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, idx) {
                        final item = _devices[idx];
                        final name = item.name.isNotEmpty ? item.name : 'Unknown';
                        final mac = item.macAdress;
                        final selected = mac == _selectedMac;
                        return ListTile(
                          leading: Icon(
                            selected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: selected ? Colors.green : null,
                          ),
                          title: Text(name),
                          subtitle: Text(mac),
                          trailing: ElevatedButton(
                            onPressed: () => _connect(mac),
                            child: Text(selected ? 'Connected' : 'Connect'),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                onPressed: _loading ? null : _printLabel,
                label: const Text('Print Label'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildTsplBitmap(
    OrderSummary order,
    OrderPackageSummary pkg,
  ) async {
    const width = 600; // 75mm * 8 dots/mm @203dpi
    const height = 480; // 60mm * 8 dots/mm @203dpi

    final image = await _renderLabelImage(order, pkg, width: width, height: height);
    final raster = await _toTspl1Bpp(image, threshold: 150);
    final widthBytes = (width + 7) ~/ 8;

    final setup = ascii.encode(
      'SIZE 75 mm,60 mm\r\n'
      'GAP 2 mm,0\r\n'
      'DIRECTION 0\r\n'
      'REFERENCE 0,0\r\n'
      'CLS\r\n'
      'DENSITY 8\r\n'
      'SPEED 2\r\n',
    );
    final bitmapHeader = ascii.encode('BITMAP 0,0,$widthBytes,$height,0,');
    final print = ascii.encode('\r\nPRINT 1\r\n');

    return Uint8List.fromList([
      ...setup,
      ...bitmapHeader,
      ...raster,
      ...print,
    ]);
  }

  Future<ui.Image> _renderLabelImage(
    OrderSummary order,
    OrderPackageSummary pkg, {
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final fillBlack = Paint()
      ..color = black
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final font1 = const TextStyle(
      color: black,
      fontSize: 20,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );
    final font2 = const TextStyle(
      color: black,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );
    final font2Bold = font2.copyWith(fontWeight: FontWeight.w700);
    final font3 = const TextStyle(
      color: black,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );
    final font4 = const TextStyle(
      color: black,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = white,
    );

    final orderId = _clean(order.generatedOrderId, max: 32);
    final custOrderId = order.customerOrderId.isNotEmpty
        ? _clean(order.customerOrderId, max: 32)
        : '--------------';
    final packageId = _clean(pkg.generatedPackageId, max: 32);
    final deliveryCustomerName = _clean(order.receiverName, max: 48);
    final pickupCustomerName = _clean(order.pickupName.isNotEmpty ? order.pickupName : 'Unknown', max: 48);
    final deliveryAddressLine = _clean(
      order.destinationAddress.isNotEmpty ? order.destinationAddress : order.addressLine,
      max: 140,
    );
    final pickupAddressLine = _clean(order.pickupAddressLine, max: 140);

    final deliveryBlockCode = deliveryAddressLine.isNotEmpty ? 'INTL' : 'N/A';
    const deliveryBlockName = 'N/A';
    const deliveryRoadCode = 'N/A';
    const deliveryRoadName = 'N/A';
    const deliveryBuildingCode = 'N/A';
    const deliveryBuildingName = 'N/A';
    const pickupBlockCode = 'N/A';
    const pickupBlockName = 'N/A';
    const pickupRoadCode = 'N/A';
    const pickupRoadName = 'N/A';
    const pickupBuildingCode = 'N/A';
    const pickupBuildingName = 'N/A';
    final useDeliveryLine = true;
    final usePickupLine = true;
    final typeText = _labelType(order);

    final badgeDate = _labelDay(order.pickupDate);
    final badgeText = '$deliveryBlockCode-$badgeDate';

    _drawBarcode(canvas, Barcode.code128(), orderId, x: 0, y: 20, width: 255, height: 80);

    // Keep text safely below barcode (barcode: y=20..100).
    _drawTextTopLeft(canvas, orderId, x: 15, topY: 110, style: font3);
    _drawTextTopLeft(canvas, custOrderId, x: 15, topY: 145, style: font3);

    _drawBorderRect(
      canvas,
      const Rect.fromLTRB(260, 28, 370, 90),
      fillBlack,
      thickness: 4,
    );
    _drawBorderRect(
      canvas,
      const Rect.fromLTRB(0, 0, 576, 480),
      fillBlack,
      thickness: 4,
    );
    _drawTextTopLeft(canvas, typeText, x: 285, topY: 40, style: font4);

    await _drawLogo(canvas, x: 400, y: 30, width: 170);

    canvas.drawRect(const Rect.fromLTWH(400, 110, 160, 50), fillBlack);
    _drawCenteredText(
      canvas,
      badgeText,
      rect: const Rect.fromLTWH(400, 110, 160, 50),
      style: const TextStyle(
        color: white,
        fontSize: 35,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );

    const leftX = 10.0;
    const leftRight = 390.0;
    var yFlow = 170.0;
    yFlow = _drawWrappedTextTopLeft(
      canvas,
      'Deliver To:',
      x: leftX,
      topY: yFlow,
      maxRight: leftRight,
      style: font2Bold,
    );

    final deliveryLine =
        (useDeliveryLine && deliveryAddressLine.isNotEmpty)
        ? '$deliveryCustomerName, $deliveryAddressLine'
        : '$deliveryCustomerName, $deliveryBuildingName($deliveryBuildingCode), '
              '$deliveryRoadName($deliveryRoadCode), $deliveryBlockName($deliveryBlockCode)';
    yFlow = _drawWrappedTextTopLeft(
      canvas,
      deliveryLine,
      x: leftX,
      topY: yFlow,
      maxRight: leftRight,
      style: font2,
    );

    yFlow += 20;
    _drawTextTopLeft(canvas, 'Shipped By:', x: leftX, topY: yFlow, style: font2Bold);
    yFlow += _lineAdvance(font2, 1.1);

    final pickupLine =
        (usePickupLine && pickupAddressLine.isNotEmpty)
        ? '$pickupCustomerName, $pickupAddressLine'
        : '$pickupCustomerName, $pickupBuildingName($pickupBuildingCode), '
              '$pickupRoadName($pickupRoadCode), $pickupBlockName($pickupBlockCode)';
    yFlow = _drawWrappedTextTopLeft(
      canvas,
      pickupLine,
      x: leftX,
      topY: yFlow,
      maxRight: leftRight,
      style: font2,
    );

    const dmSize = 120.0;
    _drawBarcode(canvas, Barcode.dataMatrix(), packageId, x: 430, y: 180, width: dmSize, height: dmSize);

    canvas.save();
    canvas.translate(430 + dmSize / 2, 310 + dmSize / 2);
    canvas.rotate(math.pi);
    _drawBarcode(
      canvas,
      Barcode.dataMatrix(),
      packageId,
      x: -dmSize / 2,
      y: -dmSize / 2,
      width: dmSize,
      height: dmSize,
    );
    canvas.restore();

    _drawTextTopRight(canvas, packageId, rightX: 550, topY: 440, style: font1);

    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  Future<void> _drawLogo(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
  }) async {
    try {
      final img = await _loadMonochromeAsset('assets/icons/delybell.png');
      if (img == null) return;
      final targetH = width * img.height / img.width;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(x, y, width, targetH),
        Paint()..filterQuality = FilterQuality.none,
      );
    } catch (_) {
      // Logo is optional for printing.
    }
  }

  Future<ui.Image?> _loadMonochromeAsset(
    String assetPath, {
    int threshold = 160,
  }) async {
    final bd = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(bd.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final raw = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (raw == null) return src;

    final rgba = Uint8List.fromList(raw.buffer.asUint8List());
    for (var i = 0; i < rgba.length; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final a = rgba[i + 3];
      final luma = (0.299 * r + 0.587 * g + 0.114 * b).round();
      final bw = luma < threshold ? 0 : 255;
      rgba[i] = bw;
      rgba[i + 1] = bw;
      rgba[i + 2] = bw;
      rgba[i + 3] = a;
    }
    return _imageFromRgba(rgba, src.width, src.height);
  }

  Future<ui.Image> _imageFromRgba(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );
    return completer.future;
  }

  List<OrderPackageSummary> _packagesForPrint() {
    if (widget.order.packages.isNotEmpty) {
      return widget.order.packages;
    }
    return [
      OrderPackageSummary(
        generatedPackageId: widget.order.generatedOrderId,
        weight: widget.order.totalWeight,
        description: widget.order.destinationAddress,
        value: widget.order.shippingCharge,
        status: widget.order.status,
      ),
    ];
  }

  Future<Uint8List?> _buildPreviewPng(
    OrderSummary order,
    OrderPackageSummary pkg,
  ) async {
    const width = 600;
    const height = 480;
    final image = await _renderLabelImage(order, pkg, width: width, height: height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<bool> _showPrintPreview(Uint8List previewBytes) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Label Preview'),
          content: SizedBox(
            width: 340,
            child: AspectRatio(
              aspectRatio: 600 / 480,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Image.memory(
                  previewBytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _drawTextTopLeft(
    Canvas canvas,
    String text, {
    required double x,
    required double topY,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, Offset(x, topY));
  }

  void _drawTextTopRight(
    Canvas canvas,
    String text, {
    required double rightX,
    required double topY,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, Offset(rightX - tp.width, topY));
  }

  void _drawCenteredText(
    Canvas canvas,
    String text, {
    required Rect rect,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: rect.width);
    final dx = rect.left + (((rect.width - tp.width) / 2).clamp(0.0, rect.width) as double);
    final dy = rect.top + (((rect.height - tp.height) / 2).clamp(0.0, rect.height) as double);
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawBorderRect(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    double thickness = 4,
  }) {
    final t = thickness;
    final width = rect.width;
    final height = rect.height;
    if (width <= 0 || height <= 0 || t <= 0) return;

    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, width, t), paint);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - t, width, t),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, t, height), paint);
    canvas.drawRect(
      Rect.fromLTWH(rect.right - t, rect.top, t, height),
      paint,
    );
  }

  double _measureWidth(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  double _lineAdvance(TextStyle style, double spacing) {
    final tp = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.height * spacing;
  }

  double _drawWrappedTextTopLeft(
    Canvas canvas,
    String text, {
    required double x,
    required double topY,
    required double maxRight,
    required TextStyle style,
    double lineSpacing = 1.1,
  }) {
    final available = (maxRight - x).clamp(1.0, double.infinity) as double;
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return topY;

    final lines = <String>[];
    var current = '';

    void flushCurrent() {
      if (current.isNotEmpty) {
        lines.add(current);
        current = '';
      }
    }

    void breakLongWord(String word) {
      var start = 0;
      while (start < word.length) {
        var end = start + 1;
        var lastFit = start;
        while (end <= word.length) {
          final sub = word.substring(start, end);
          if (_measureWidth(sub, style) <= available) {
            lastFit = end;
            end++;
          } else {
            break;
          }
        }
        if (lastFit == start) {
          lines.add(word.substring(start, (start + 1).clamp(0, word.length) as int));
          start += 1;
        } else {
          lines.add(word.substring(start, lastFit));
          start = lastFit;
        }
      }
    }

    for (final w in words) {
      if (current.isEmpty) {
        if (_measureWidth(w, style) <= available) {
          current = w;
        } else {
          breakLongWord(w);
        }
      } else {
        final candidate = '$current $w';
        if (_measureWidth(candidate, style) <= available) {
          current = candidate;
        } else {
          flushCurrent();
          if (_measureWidth(w, style) <= available) {
            current = w;
          } else {
            breakLongWord(w);
          }
        }
      }
    }
    flushCurrent();

    var lineTop = topY;
    final advance = _lineAdvance(style, lineSpacing);
    for (final line in lines) {
      _drawTextTopLeft(canvas, line, x: x, topY: lineTop, style: style);
      lineTop += advance;
    }
    return lineTop;
  }

  void _drawBarcode(
    Canvas canvas,
    Barcode barcode,
    String data, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final value = data.trim();
    if (value.isEmpty) return;
    try {
      final bars = barcode.make(
        value,
        width: width,
        height: height,
        drawText: false,
      );
      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final bar in bars) {
        if (bar is BarcodeBar && bar.black) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + bar.left,
              y + bar.top,
              bar.width,
              bar.height,
            ),
            paint,
          );
        }
      }
    } catch (_) {
      // Keep label printable even if barcode encoding fails.
    }
  }

  /// Returns a short label for the type badge on the printed label.
  /// Priority: service type abbreviation (SD / ND / EXP), with COD / RET / INV
  /// prefix when applicable.
  String _labelType(OrderSummary order) {
    // Derive service-type abbreviation from the serviceType name.
    String serviceAbbr = '';
    final svc = order.serviceType.toLowerCase();
    if (svc.contains('same')) {
      serviceAbbr = 'SD';
    } else if (svc.contains('next')) {
      serviceAbbr = 'ND';
    } else if (svc.contains('express')) {
      serviceAbbr = 'EXP';
    }

    // Derive flow-type prefix.
    final flow = order.orderType.toLowerCase();
    String prefix = '';
    if (order.isCod) {
      prefix = 'COD';
    } else if (flow.contains('return')) {
      prefix = 'RET';
    } else if (flow.contains('inventory')) {
      prefix = 'INV';
    }

    if (prefix.isNotEmpty && serviceAbbr.isNotEmpty) {
      return '$prefix-$serviceAbbr';
    }
    if (serviceAbbr.isNotEmpty) return serviceAbbr;
    if (prefix.isNotEmpty) return prefix;
    return 'N/A';
  }

  String _labelDay(String rawDate) {
    final value = rawDate.trim();
    if (value.isEmpty) return '00';
    final digits = RegExp(r'(\d{2})$').firstMatch(value)?.group(1);
    if (digits != null) return digits;
    return value.length >= 2 ? value.substring(value.length - 2) : value;
  }

  Future<Uint8List> _toTspl1Bpp(ui.Image image, {int threshold = 150}) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      return Uint8List(0);
    }
    final rgba = bytes.buffer.asUint8List();
    final width = image.width;
    final height = image.height;
    final widthBytes = (width + 7) ~/ 8;
    final out = Uint8List(widthBytes * height);

    for (var y = 0; y < height; y++) {
      for (var xb = 0; xb < widthBytes; xb++) {
        var byte = 0;
        for (var bit = 0; bit < 8; bit++) {
          final x = xb * 8 + bit;
          if (x >= width) continue;
          final i = (y * width + x) * 4;
          final r = rgba[i];
          final g = rgba[i + 1];
          final b = rgba[i + 2];
          final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
          final isBlack = lum < threshold;
          if (isBlack) {
            byte |= (0x80 >> bit);
          }
        }
        out[y * widthBytes + xb] = byte;
      }
    }
    return out;
  }

  String _clean(String? value, {int max = 32}) {
    final v = (value ?? '').replaceAll('"', '').trim();
    if (v.isEmpty) return '--';
    return v.length <= max ? v : v.substring(0, max);
  }
}
