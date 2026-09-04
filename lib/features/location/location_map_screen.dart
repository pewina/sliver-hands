import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../core/location_service.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  LatLng? _position;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await const LocationService().currentPosition();
      if (!mounted) return;
      setState(() {
        _position = LatLng(position.latitude, position.longitude);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Widget _demoMap() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFFDCEBE5),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _DemoMapPainter()),
              ),
              const Positioned(
                left: 145,
                top: 125,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.teal,
                  child: Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 28),
                ),
              ),
              const Positioned(
                right: 45,
                top: 55,
                child: _MapPin(label: 'Anand Celebrations', color: AppColors.rose),
              ),
              const Positioned(
                left: 35,
                bottom: 45,
                child: _MapPin(label: 'Asha Office Hub', color: AppColors.saffron),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Nearby opportunities', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.restaurant_rounded)),
            title: Text('Festival Gift Hampers'),
            subtitle: Text('4.5 km • High demand • 94% AI match'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.lunch_dining_rounded)),
            title: Text('Home-style Tiffins'),
            subtitle: Text('6.2 km • Monthly income • 91% AI match'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your location'),
        backgroundColor: AppColors.cream,
      ),
      body: !AppConfig.hasSupabase
          ? _demoMap()
          : _position == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _position!,
                zoom: 13,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('me'),
                  position: _position!,
                  infoWindow: const InfoWindow(title: 'You are here'),
                ),
              },
            ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x22000000))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _DemoMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;
    final road2 = Paint()
      ..color = const Color(0xFFBFD4CC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * .65), Offset(size.width, size.height * .22), road);
    canvas.drawLine(Offset(size.width * .18, 0), Offset(size.width * .72, size.height), road);
    canvas.drawLine(Offset(0, size.height * .25), Offset(size.width, size.height * .78), road);
    canvas.drawLine(Offset(0, size.height * .65), Offset(size.width, size.height * .22), road2);
    canvas.drawLine(Offset(size.width * .18, 0), Offset(size.width * .72, size.height), road2);
    canvas.drawLine(Offset(0, size.height * .25), Offset(size.width, size.height * .78), road2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
