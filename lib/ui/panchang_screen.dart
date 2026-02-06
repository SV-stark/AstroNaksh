import 'package:fluent_ui/fluent_ui.dart';
import '../logic/panchang_service.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  DateTime _selectedDate = DateTime.now();
  final PanchangService _panchangService = PanchangService();
  PanchangResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePanchang();
  }

  Future<void> _calculatePanchang() async {
    setState(() => _isLoading = true);
    try {
      final location = Location(latitude: 28.6139, longitude: 77.2090);
      final result = await _panchangService.getPanchang(
        _selectedDate,
        location,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _calculatePanchang();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Daily Panchang'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarBuilderItem(
              builder: (context, mode, w) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DatePicker(
                    selected: _selectedDate,
                    onChanged: (date) {
                      setState(() => _selectedDate = date);
                      _calculatePanchang();
                    },
                  ),
                );
              },
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.calendar),
                label: const Text('Date'),
                onPressed: () {},
              ),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _calculatePanchang,
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : _result == null
          ? const Center(child: Text("No Data"))
          : CustomScrollView(
              slivers: [
                // Date Navigation Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FluentTheme.of(context).accentColor.withAlpha(30),
                          FluentTheme.of(context).accentColor.withAlpha(10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FluentTheme.of(context).accentColor.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Date Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(FluentIcons.chevron_left),
                              onPressed: () => _changeDate(-1),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEEE').format(_selectedDate),
                                    style: FluentTheme.of(context).typography.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: FluentTheme.of(context).accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _result!.date,
                                    style: FluentTheme.of(context).typography.title?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(FluentIcons.chevron_right),
                              onPressed: () => _changeDate(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Location indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FluentIcons.location,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New Delhi, India',
                              style: FluentTheme.of(context).typography.caption?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Panchang Elements
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panchang Elements',
                          style: FluentTheme.of(context).typography.subtitle?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                    children: [
                      _buildPanchangCard(
                        title: 'Tithi',
                        value: _result!.tithi,
                        subtitle: 'Lunar Day',
                        icon: FluentIcons.calendar_day,
                        color: Colors.orange,
                        description: 'The lunar day based on moon phases',
                      ),
                      _buildPanchangCard(
                        title: 'Nakshatra',
                        value: _result!.nakshatra,
                        subtitle: 'Lunar Mansion',
                        icon: FluentIcons.favorite_star,
                        color: Colors.purple,
                        description: 'The constellation moon is transiting',
                      ),
                      _buildPanchangCard(
                        title: 'Yoga',
                        value: _result!.yoga,
                        subtitle: 'Sun-Moon Angle',
                        icon: FluentIcons.flow,
                        color: Colors.blue,
                        description: 'Angular relationship between Sun and Moon',
                      ),
                      _buildPanchangCard(
                        title: 'Karana',
                        value: _result!.karana,
                        subtitle: 'Half Tithi',
                        icon: FluentIcons.stopwatch,
                        color: Colors.teal,
                        description: 'Half of a lunar day',
                      ),
                      _buildPanchangCard(
                        title: 'Vara',
                        value: _result!.vara,
                        subtitle: 'Weekday',
                        icon: FluentIcons.calendar,
                        color: Colors.green,
                        description: 'Day of the week ruled by a planet',
                      ),
                    ],
                  ),
                ),

                // Information Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FluentIcons.info,
                              size: 16,
                              color: FluentTheme.of(context).accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Panchang',
                              style: FluentTheme.of(context).typography.body?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Panchang (Five Limbs) is the Hindu almanac that provides astrological information about the day. '
                          'It consists of five elements: Tithi (lunar day), Nakshatra (lunar mansion), Yoga (sun-moon angle), '
                          'Karana (half tithi), and Vara (weekday). These elements help determine auspicious times and activities for the day.',
                          style: FluentTheme.of(context).typography.caption,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildPanchangCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return HoverButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: FluentTheme.of(context).typography.title?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(description),
              ],
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      builder: (context, states) {
        return Card(
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.all(12.0),
          backgroundColor: states.isHovered ? color.withAlpha(15) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
