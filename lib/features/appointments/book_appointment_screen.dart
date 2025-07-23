import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agcare_plus/core/models/doctor_model.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  int _currentStep = 0;
  final TextEditingController _searchController = TextEditingController();
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<Doctor> _doctors = [
    Doctor(
      id: '1',
      name: 'Dr. Sarah Johnson',
      specialty: 'Cardiologist',
      rating: 4.8,
      distance: 2.5,
      imageUrl: 'https://randomuser.me/api/portraits/women/42.jpg',
    ),
    Doctor(
      id: '2',
      name: 'Dr. Michael Chen',
      specialty: 'Dermatologist',
      rating: 4.6,
      distance: 1.2,
      imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
    Doctor(
      id: '3',
      name: 'Dr. Lisa Wong',
      specialty: 'Pediatrician',
      rating: 4.9,
      distance: 3.1,
      imageUrl: 'https://randomuser.me/api/portraits/women/65.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _continue,
        onStepCancel: _cancel,
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: [
          Step(
            title: const Text('Find Doctor'),
            content: _buildDoctorSearch(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Select Date & Time'),
            content: _buildDateTimePicker(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Confirm Booking'),
            content: _buildConfirmation(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSearch() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or specialty...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: _showFilters,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        ..._doctors.where((doctor) => 
          doctor.name.toLowerCase().contains(_searchController.text.toLowerCase()) || 
          doctor.specialty.toLowerCase().contains(_searchController.text.toLowerCase())
        ).map((doctor) => _buildDoctorCard(doctor)),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(doctor.imageUrl),
        ),
        title: Text(doctor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialty),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${doctor.rating} (${doctor.distance} km)'),
              ],
            ),
          ],
        ),
        trailing: _selectedDoctor?.id == doctor.id 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () {
          setState(() {
            _selectedDoctor = doctor;
          });
        },
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Select Date'),
          subtitle: Text(_selectedDate == null 
              ? 'No date selected' 
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Select Time'),
          subtitle: Text(_selectedTime == null 
              ? 'No time selected' 
              : _selectedTime!.format(context)),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                _selectedTime = time;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    if (_selectedDoctor == null || _selectedDate == null || _selectedTime == null) {
      return const Center(child: Text('Please complete all steps'));
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_selectedDoctor!.imageUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedDoctor!.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(_selectedDoctor!.specialty),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Date'),
                        Text(
                          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Time'),
                        Text(
                          _selectedTime!.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Reason for visit (optional)'),
        const SizedBox(height: 8),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Describe your symptoms or reason for visit...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _continue() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _selectedDoctor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor')),
        );
        return;
      }
      if (_currentStep == 1 && (_selectedDate == null || _selectedTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }
      setState(() => _currentStep += 1);
    } else {
      _confirmBooking();
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: const Text('Are you sure you want to book this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment booked successfully!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Doctors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Specialty'),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Cardiology'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Dermatology'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Pediatrics'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Distance'),
              Slider(
                value: 5,
                min: 1,
                max: 20,
                divisions: 19,
                label: '5 km',
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }
}