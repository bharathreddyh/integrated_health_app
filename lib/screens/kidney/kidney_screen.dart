class KidneyScreen extends StatefulWidget {
  final Patient? patient;

  const KidneyScreen({super.key, this.patient});

  @override
  State<KidneyScreen> createState() => _KidneyScreenState();
}

class _KidneyScreenState extends State<KidneyScreen> {
  // ... existing variables ...

  late Patient patient;

  @override
  void initState() {
    super.initState();
    patient = widget.patient ?? Patient(
      id: 'TEMP001',
      name: 'John Doe',
      age: 45,
      phone: '0000000000',
      date: DateTime.now().toString().split(' ')[0],
    );
  }}

// Rest of your existing kidney screen code
// Update patient info section to use: patient.name, patient.age.toString(), patient.phone