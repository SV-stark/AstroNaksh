import 'models.dart';

class SampleCharts {
  static final List<BirthData> samples = [
    BirthData(
      name: 'Swami Vivekananda',
      dateTime: DateTime(1863, 1, 12, 6, 33),
      location: Location(latitude: 22.5726, longitude: 88.3639),
      place: 'Kolkata, West Bengal, India',
      timezone: 'Asia/Kolkata',
    ),
    BirthData(
      name: 'Albert Einstein',
      dateTime: DateTime(1879, 3, 14, 11, 30),
      location: Location(latitude: 48.3984, longitude: 9.9916),
      place: 'Ulm, Germany',
      timezone: 'Europe/Berlin',
    ),
    BirthData(
      name: 'Dr. A.P.J. Abdul Kalam',
      dateTime: DateTime(
        1931,
        10,
        15,
        1,
        15,
      ), // Approximate time often used in astrology
      location: Location(latitude: 9.2800, longitude: 79.3129),
      place: 'Rameswaram, Tamil Nadu, India',
      timezone: 'Asia/Kolkata',
    ),
  ];
}
