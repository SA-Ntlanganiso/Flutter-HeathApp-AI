import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _isCalling = false;
  double _speed = 0.0; // In km/h

  final List<EmergencyContact> _contacts = [
    EmergencyContact(
      name: 'Ambulance',
      number: '911',
      type: EmergencyType.ambulance,
    ),
    EmergencyContact(
      name: 'Police',
      number: '911',
      type: EmergencyType.police,
    ),
    EmergencyContact(
      name: 'Fire Department',
      number: '911',
      type: EmergencyType.fire,
    ),
    EmergencyContact(
      name: 'Dr. Sarah Johnson',
      number: '+1234567890',
      type: EmergencyType.doctor,
      imageUrl: 'https://randomuser.me/api/portraits/women/42.jpg',
      specialty: 'Cardiologist',
      distance: 2.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
      ),
      body: Column(
        children: [
          if (_isCalling) _buildCallInProgress(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._contacts.map((contact) => _buildContactCard(contact)),
                const SizedBox(height: 16),
                const Text(
                  'Nearest Hospitals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildHospitalCard('City General Hospital', '1.2 km', '24/7 Emergency'),
                _buildHospitalCard('Community Medical Center', '2.8 km', 'Trauma Center'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: contact.type == EmergencyType.doctor
            ? CircleAvatar(backgroundImage: NetworkImage(contact.imageUrl!))
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getContactColor(contact.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getContactIcon(contact.type), color: Colors.white),
              ),
        title: Text(contact.name),
        subtitle: contact.type == EmergencyType.doctor
            ? Text('${contact.specialty} • ${contact.distance} km')
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.red),
          onPressed: () => _initiateCall(contact),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(String name, String distance, String services) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_hospital, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text('$distance • $services'),
        trailing: const Icon(Icons.directions, color: Colors.blue),
        onTap: () {},
      ),
    );
  }

  Widget _buildCallInProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red[50],
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.red,
            child: Icon(Icons.call, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Call',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Connecting to Dr. Sarah Johnson...'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () {
              setState(() {
                _isCalling = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Color _getContactColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.ambulance:
        return Colors.red;
      case EmergencyType.police:
        return Colors.blue;
      case EmergencyType.fire:
        return Colors.orange;
      case EmergencyType.doctor:
        return Colors.green;
    }
  }

  IconData _getContactIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.ambulance:
        return Icons.medical_services;
      case EmergencyType.police:
        return Icons.security;
      case EmergencyType.fire:
        return Icons.fire_truck;
      case EmergencyType.doctor:
        return Icons.person;
    }
  }

  void _initiateCall(EmergencyContact contact) {
    // Check if user is moving too fast (possible cheating)
    if (_speed > 10) { // 10 km/h threshold
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Speed Warning'),
            content: const Text('You appear to be moving too fast for an emergency call. Are you in a vehicle?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startCall(contact);
                },
                child: const Text('Continue Anyway'),
              ),
            ],
          );
        },
      );
    } else {
      _startCall(contact);
    }
  }

  void _startCall(EmergencyContact contact) {
    setState(() {
      _isCalling = true;
    });
    
    // Simulate call connection
    Future.delayed(const Duration(seconds: 2), () {
      // In a real app, this would connect to actual call service
    });
  }
}

enum EmergencyType { ambulance, police, fire, doctor }

class EmergencyContact {
  final String name;
  final String number;
  final EmergencyType type;
  final String? imageUrl;
  final String? specialty;
  final double? distance;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.type,
    this.imageUrl,
    this.specialty,
    this.distance,
  });
}