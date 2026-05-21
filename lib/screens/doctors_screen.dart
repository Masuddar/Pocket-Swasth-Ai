import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/appointment.dart';
import 'sos_screen.dart';

// ── Data models ──────────────────────────────────────────────────────────────
class DoctorModel {
  final String name, specialty, hospital, location, fee, availability, imageInitials;
  final double rating;
  final int experienceYears;
  final String phone;
  const DoctorModel({
    required this.name, required this.specialty, required this.hospital,
    required this.location, required this.fee, required this.availability,
    required this.imageInitials, required this.rating, required this.experienceYears,
    required this.phone,
  });
}

class HospitalModel {
  final String name, address, phone, type;
  final List<String> facilities;
  const HospitalModel({required this.name, required this.address, required this.phone, required this.type, required this.facilities});
}

const doctors = [
  DoctorModel(name:'Dr. Arjun Sharma', specialty:'Cardiologist', hospital:'Apollo Heart Centre', location:'Bandra West', fee:'₹800', availability:'Mon–Fri 10am–4pm', imageInitials:'AS', rating:4.8, experienceYears:16, phone:'+912222334455'),
  DoctorModel(name:'Dr. Priya Mehta', specialty:'General Physician', hospital:'Lilavati Hospital', location:'Bandra West', fee:'₹500', availability:'Mon–Sat 9am–6pm', imageInitials:'PM', rating:4.6, experienceYears:10, phone:'+912222334456'),
  DoctorModel(name:'Dr. Ramesh Patel', specialty:'Orthopedic', hospital:'Kokilaben Hospital', location:'Andheri West', fee:'₹900', availability:'Tue–Sat 11am–5pm', imageInitials:'RP', rating:4.7, experienceYears:20, phone:'+912222334457'),
  DoctorModel(name:'Dr. Sunita Rao', specialty:'Dermatologist', hospital:'Hinduja Hospital', location:'Mahim', fee:'₹700', availability:'Mon–Fri 2pm–7pm', imageInitials:'SR', rating:4.5, experienceYears:12, phone:'+912222334458'),
  DoctorModel(name:'Dr. Vikram Nair', specialty:'Neurologist', hospital:'Jaslok Hospital', location:'Peddar Road', fee:'₹1200', availability:'Wed–Fri 10am–3pm', imageInitials:'VN', rating:4.9, experienceYears:22, phone:'+912222334459'),
  DoctorModel(name:'Dr. Ananya Singh', specialty:'Pediatrician', hospital:'KEM Hospital', location:'Parel', fee:'₹400', availability:'Mon–Sat 8am–2pm', imageInitials:'AN', rating:4.6, experienceYears:8, phone:'+912222334460'),
  DoctorModel(name:'Dr. Deepak Joshi', specialty:'Gastroenterologist', hospital:'Wockhardt Hospital', location:'Mumbai Central', fee:'₹1000', availability:'Mon–Fri 9am–5pm', imageInitials:'DJ', rating:4.7, experienceYears:18, phone:'+912222334461'),
  DoctorModel(name:'Dr. Kavitha Iyer', specialty:'Gynecologist', hospital:'Breach Candy Hospital', location:'Breach Candy', fee:'₹800', availability:'Tue–Sat 10am–4pm', imageInitials:'KI', rating:4.8, experienceYears:14, phone:'+912222334462'),
  DoctorModel(name:'Dr. Suresh Malhotra', specialty:'Pulmonologist', hospital:'Hinduja Hospital', location:'Mahim', fee:'₹900', availability:'Mon–Thu 11am–6pm', imageInitials:'SM', rating:4.5, experienceYears:15, phone:'+912222334463'),
  DoctorModel(name:'Dr. Ritu Gupta', specialty:'ENT Specialist', hospital:'Lilavati Hospital', location:'Bandra West', fee:'₹600', availability:'Mon–Sat 9am–1pm', imageInitials:'RG', rating:4.4, experienceYears:9, phone:'+912222334464'),
];

const _hospitals = [
  HospitalModel(name:'Apollo Hospital', address:'Parsik Hill Road, Navi Mumbai', phone:'18605008000', type:'Multi-Speciality', facilities:['ICU','Emergency 24/7','Blood Bank','NICU']),
  HospitalModel(name:'Kokilaben Hospital', address:'Rao Saheb Achutrao Patwardhan Marg, Andheri', phone:'02230999999', type:'Super-Speciality', facilities:['Cardiac Surgery','Neurosciences','Oncology','Emergency']),
  HospitalModel(name:'Lilavati Hospital', address:'A-791, Bandra Reclamation, Bandra West', phone:'02226751000', type:'Multi-Speciality', facilities:['Robotic Surgery','Maternity','Emergency 24/7','Blood Bank']),
  HospitalModel(name:'KEM Hospital', address:'Acharya Dhonde Marg, Parel', phone:'02224138000', type:'Government', facilities:['Emergency','Burns Unit','Trauma','Free OPD']),
  HospitalModel(name:'Breach Candy Hospital', address:'60-A Bhulabhai Desai Road, Breach Candy', phone:'02223667788', type:'Private', facilities:['ICU','Emergency','Maternity','Dialysis']),
];

const _specialties = ['All','General Physician','Cardiologist','Orthopedic','Dermatologist','Neurologist','Pediatrician','Gastroenterologist','Gynecologist','Pulmonologist','ENT Specialist'];

// ── Main Screen ───────────────────────────────────────────────────────────────
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSpecialty = 'All';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DoctorModel> get _filtered => doctors.where((d) {
    final matchSpec = _selectedSpecialty == 'All' || d.specialty == _selectedSpecialty;
    final matchSearch = _search.isEmpty || d.name.toLowerCase().contains(_search) || d.specialty.toLowerCase().contains(_search);
    return matchSpec && matchSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Doctors & Hospitals'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Doctors'),
            Tab(text: 'Hospitals'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.emergency_rounded, color: Colors.white),
        label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        heroTag: 'sos_fab',
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorsTab(),
          _buildHospitalsTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search doctors or specialty...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderLight)),
              filled: true, fillColor: AppTheme.white,
            ),
          ),
        ),
        // Specialty filter chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _specialties.length,
            itemBuilder: (_, i) {
              final s = _specialties[i];
              final selected = s == _selectedSpecialty;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: selected ? AppTheme.white : AppTheme.textMuted)),
                  selected: selected,
                  selectedColor: AppTheme.primaryTeal,
                  backgroundColor: AppTheme.borderLight.withOpacity(0.4),
                  onSelected: (_) => setState(() => _selectedSpecialty = s),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No doctors found', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _DoctorCard(doctor: _filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildHospitalsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _hospitals.length,
      itemBuilder: (_, i) => _HospitalCard(hospital: _hospitals[i]),
    );
  }

  Widget _buildBookingsTab() {
    return Consumer<HealthProvider>(
      builder: (context, hp, child) {
        final list = hp.appointments;
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 64, color: AppTheme.primaryTeal),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Bookings Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book appointments with our elite doctors or use the Swasth AI Agent to match symptoms instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _tabController.animateTo(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Find a Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final apt = list[i];
            Color statusColor = Colors.green;
            if (apt.status == 'Rescheduled') statusColor = Colors.orange;
            if (apt.status == 'Cancelled') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(
                                apt.status,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'ID: #${apt.id.substring(apt.id.length - 4)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      apt.doctorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${apt.doctorSpecialty} • ${apt.hospitalName}',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          apt.dateTimeStr,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          apt.slot,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (apt.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              apt.notes,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (apt.status != 'Cancelled') ...[
                          OutlinedButton.icon(
                            onPressed: () => _showRescheduleSheet(context, apt),
                            icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                            label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              side: const BorderSide(color: AppTheme.primaryTeal),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showCancelDialog(context, apt),
                            icon: const Icon(Icons.cancel_rounded, size: 14),
                            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              Provider.of<HealthProvider>(context, listen: false).removeAppointmentRecord(apt.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('🗑️ Appointment record deleted'),
                                backgroundColor: Colors.black87,
                              ));
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 14),
                            label: const Text('Delete Record', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue)),
        content: Text('Are you sure you want to cancel your appointment with ${appointment.doctorName} on ${appointment.dateTimeStr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<HealthProvider>(context, listen: false).cancelAppointment(appointment.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('❌ Appointment with ${appointment.doctorName} cancelled'),
                backgroundColor: Colors.red,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRescheduleSheet(BuildContext context, Appointment appointment) {
    final dateCtrl = TextEditingController(text: appointment.dateTimeStr);
    String selectedSlot = appointment.slot;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 24, left: 20, right: 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              const Text('Reschedule Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.secondaryBlue)),
              Text('With ${appointment.doctorName}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 18),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (d != null) dateCtrl.text = '${d.day}/${d.month}/${d.year}';
                },
                decoration: InputDecoration(labelText: 'Select New Date', prefixIcon: const Icon(Icons.calendar_today_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ['Morning (9am–12pm)', 'Afternoon (12pm–4pm)', 'Evening (4pm–7pm)'].contains(selectedSlot)
                    ? selectedSlot
                    : 'Morning (9am–12pm)',
                decoration: InputDecoration(labelText: 'Time Slot', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Morning (9am–12pm)', 'Afternoon (12pm–4pm)', 'Evening (4pm–7pm)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setS(() => selectedSlot = v!),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Provider.of<HealthProvider>(context, listen: false).rescheduleAppointment(appointment.id, dateCtrl.text, selectedSlot);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ Rescheduled with ${appointment.doctorName} to ${dateCtrl.text} ($selectedSlot)'),
                    backgroundColor: Colors.green,
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Confirm Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Doctor Card ───────────────────────────────────────────────────────────────
class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorCard({required this.doctor});

  Color get _specialtyColor {
    const map = {'Cardiologist': Colors.red, 'Neurologist': Colors.purple, 'Orthopedic': Colors.orange, 'Dermatologist': Colors.pink, 'Gynecologist': Colors.pinkAccent, 'Pediatrician': Colors.blue, 'Gastroenterologist': Colors.brown};
    return (map[doctor.specialty] as Color?) ?? AppTheme.primaryTeal;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _specialtyColor.withOpacity(0.12),
                  child: Text(doctor.imageInitials, style: TextStyle(color: _specialtyColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondaryBlue)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _specialtyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(doctor.specialty, style: TextStyle(fontSize: 11, color: _specialtyColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 14), const SizedBox(width: 2), Text(doctor.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
                    const SizedBox(height: 4),
                    Text(doctor.fee, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.local_hospital_outlined, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text('${doctor.hospital} • ${doctor.location}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(doctor.availability, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
              const Spacer(),
              Text('${doctor.experienceYears} yrs exp', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${doctor.phone}')),
                  icon: const Icon(Icons.call_rounded, size: 14),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryTeal, side: const BorderSide(color: AppTheme.primaryTeal), padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => showBookingSheet(context, doctor),
                  icon: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: const Text('Book Appointment', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: AppTheme.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

void showBookingSheet(BuildContext context, DoctorModel doctor) {
  final dateCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String selectedSlot = 'Morning (9am–12pm)';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 24, left: 20, right: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text('Book with ${doctor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.secondaryBlue)),
            Text('${doctor.specialty} • ${doctor.hospital}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                if (d != null) dateCtrl.text = '${d.day}/${d.month}/${d.year}';
              },
              decoration: InputDecoration(labelText: 'Select Date', prefixIcon: const Icon(Icons.calendar_today_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSlot,
              decoration: InputDecoration(labelText: 'Time Slot', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Morning (9am–12pm)', 'Afternoon (12pm–4pm)', 'Evening (4pm–7pm)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setS(() => selectedSlot = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: 'Reason / Notes (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                final dateStr = dateCtrl.text.isEmpty
                    ? '${DateTime.now().add(const Duration(days: 1)).day}/${DateTime.now().add(const Duration(days: 1)).month}/${DateTime.now().add(const Duration(days: 1)).year}'
                    : dateCtrl.text;
                Provider.of<HealthProvider>(context, listen: false).bookAppointment(
                  doctorName: doctor.name,
                  doctorSpecialty: doctor.specialty,
                  hospitalName: doctor.hospital,
                  dateTimeStr: dateStr,
                  slot: selectedSlot,
                  notes: noteCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Appointment confirmed with ${doctor.name} on $dateStr'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Confirm Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Hospital Card ─────────────────────────────────────────────────────────────
class _HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  const _HospitalCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.local_hospital_rounded, color: Colors.red, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondaryBlue)),
                Text(hospital.type, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ])),
            ]),
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.textMuted), const SizedBox(width: 4), Expanded(child: Text(hospital.address, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)))]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: hospital.facilities.map((f) => Chip(
              label: Text(f, style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryLightTeal.withOpacity(0.3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList()),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${hospital.phone}')),
              icon: const Icon(Icons.call_rounded, size: 14),
              label: Text('Call ${hospital.phone}', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
