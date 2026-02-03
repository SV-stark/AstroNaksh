import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../logic/varshaphal_system.dart';

class VarshaphalScreen extends StatefulWidget {
  final BirthData birthData;

  const VarshaphalScreen({super.key, required this.birthData});

  @override
  State<VarshaphalScreen> createState() => _VarshaphalScreenState();
}

class _VarshaphalScreenState extends State<VarshaphalScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Varshaphal (Annual Chart)')),
      content: FutureBuilder<VarshaphalChart>(
        future: VarshaphalSystem.calculateVarshaphal(
          widget.birthData,
          _selectedYear,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final varshaphal = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Year selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Year:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(FluentIcons.remove),
                            onPressed: () {
                              setState(() {
                                _selectedYear--;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$_selectedYear',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.add),
                            onPressed: () {
                              setState(() {
                                _selectedYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Solar return info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solar Return',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(varshaphal.solarReturnTime)}',
                      ),
                      Text('Year Lord: ${varshaphal.yearLord}'),
                      Text('Muntha in House: ${varshaphal.muntha}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Varshik Dasha
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Varshik Dasha Periods',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...varshaphal.varshikDasha.map((period) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(period.planet)),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${period.durationDays.toStringAsFixed(1)} days',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sahams
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sahams (Arabic Parts)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...varshaphal.sahams.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(
                                '${entry.value.longitude.toStringAsFixed(2)}°',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Yearly predictions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Annual Predictions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(varshaphal.interpretation),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
