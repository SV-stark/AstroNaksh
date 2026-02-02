import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// City Database with GPS Integration
/// Comprehensive database of world cities with coordinates
class CityDatabase {
  /// Major cities database
  static final List<City> _cities = [
    // India
    City(
      name: 'Delhi',
      country: 'India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Mumbai',
      country: 'India',
      latitude: 19.0760,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Kolkata',
      country: 'India',
      latitude: 22.5726,
      longitude: 88.3639,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Chennai',
      country: 'India',
      latitude: 13.0827,
      longitude: 80.2707,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bangalore',
      country: 'India',
      latitude: 12.9716,
      longitude: 77.5946,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Hyderabad',
      country: 'India',
      latitude: 17.3850,
      longitude: 78.4867,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Pune',
      country: 'India',
      latitude: 18.5204,
      longitude: 73.8567,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ahmedabad',
      country: 'India',
      latitude: 23.0225,
      longitude: 72.5714,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jaipur',
      country: 'India',
      latitude: 26.9124,
      longitude: 75.7873,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Lucknow',
      country: 'India',
      latitude: 26.8467,
      longitude: 80.9462,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Kanpur',
      country: 'India',
      latitude: 26.4499,
      longitude: 80.3319,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Nagpur',
      country: 'India',
      latitude: 21.1458,
      longitude: 79.0882,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Indore',
      country: 'India',
      latitude: 22.7196,
      longitude: 75.8577,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Thane',
      country: 'India',
      latitude: 19.2183,
      longitude: 72.9781,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bhopal',
      country: 'India',
      latitude: 23.2599,
      longitude: 77.4126,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Visakhapatnam',
      country: 'India',
      latitude: 17.6868,
      longitude: 83.2185,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Vadodara',
      country: 'India',
      latitude: 22.3072,
      longitude: 73.1812,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Firozabad',
      country: 'India',
      latitude: 27.1591,
      longitude: 78.3957,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ludhiana',
      country: 'India',
      latitude: 30.9010,
      longitude: 75.8573,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Rajkot',
      country: 'India',
      latitude: 22.3039,
      longitude: 70.8022,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Agra',
      country: 'India',
      latitude: 27.1767,
      longitude: 78.0081,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Siliguri',
      country: 'India',
      latitude: 26.7271,
      longitude: 88.3953,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Durgapur',
      country: 'India',
      latitude: 23.5204,
      longitude: 87.3119,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Chandigarh',
      country: 'India',
      latitude: 30.7333,
      longitude: 76.7794,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Shimla',
      country: 'India',
      latitude: 31.1046,
      longitude: 77.1734,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Guwahati',
      country: 'India',
      latitude: 26.1445,
      longitude: 91.7362,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Solapur',
      country: 'India',
      latitude: 17.6599,
      longitude: 75.9064,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Hubli',
      country: 'India',
      latitude: 15.3647,
      longitude: 75.1240,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Tiruchirappalli',
      country: 'India',
      latitude: 10.7905,
      longitude: 78.7047,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Mysore',
      country: 'India',
      latitude: 12.2958,
      longitude: 76.6394,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Coimbatore',
      country: 'India',
      latitude: 11.0168,
      longitude: 76.9558,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Patna',
      country: 'India',
      latitude: 25.5941,
      longitude: 85.1376,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Salem',
      country: 'India',
      latitude: 11.6643,
      longitude: 78.1460,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bhubaneswar',
      country: 'India',
      latitude: 20.2961,
      longitude: 85.8245,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Thiruvananthapuram',
      country: 'India',
      latitude: 8.5241,
      longitude: 76.9366,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Mangalore',
      country: 'India',
      latitude: 12.9141,
      longitude: 74.8560,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Warangal',
      country: 'India',
      latitude: 17.9689,
      longitude: 79.5941,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Guntur',
      country: 'India',
      latitude: 16.3067,
      longitude: 80.4365,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bhiwandi',
      country: 'India',
      latitude: 19.2813,
      longitude: 73.0483,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Saharanpur',
      country: 'India',
      latitude: 29.9640,
      longitude: 77.5467,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Gorakhpur',
      country: 'India',
      latitude: 26.7606,
      longitude: 83.3732,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bikaner',
      country: 'India',
      latitude: 28.0229,
      longitude: 73.3119,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Amravati',
      country: 'India',
      latitude: 20.9320,
      longitude: 77.7523,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Noida',
      country: 'India',
      latitude: 28.5355,
      longitude: 77.3910,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jamshedpur',
      country: 'India',
      latitude: 22.8046,
      longitude: 86.2029,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bhilai',
      country: 'India',
      latitude: 21.1938,
      longitude: 81.3509,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Cuttack',
      country: 'India',
      latitude: 20.4625,
      longitude: 85.8828,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Firozabad',
      country: 'India',
      latitude: 27.1591,
      longitude: 78.3957,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Kochi',
      country: 'India',
      latitude: 9.9312,
      longitude: 76.2673,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Nellore',
      country: 'India',
      latitude: 14.4426,
      longitude: 79.9865,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Bhavnagar',
      country: 'India',
      latitude: 21.7645,
      longitude: 72.1519,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Dehradun',
      country: 'India',
      latitude: 30.3165,
      longitude: 78.0322,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Durgapur',
      country: 'India',
      latitude: 23.5204,
      longitude: 87.3119,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Asansol',
      country: 'India',
      latitude: 23.6739,
      longitude: 86.9524,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Rourkela',
      country: 'India',
      latitude: 22.2270,
      longitude: 84.8524,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Nanded',
      country: 'India',
      latitude: 19.1383,
      longitude: 77.3210,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Kolhapur',
      country: 'India',
      latitude: 16.7050,
      longitude: 74.2433,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ajmer',
      country: 'India',
      latitude: 26.4499,
      longitude: 74.6399,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Akola',
      country: 'India',
      latitude: 20.7002,
      longitude: 77.0082,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Gulbarga',
      country: 'India',
      latitude: 17.3297,
      longitude: 76.8343,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jamnagar',
      country: 'India',
      latitude: 22.4707,
      longitude: 70.0577,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ujjain',
      country: 'India',
      latitude: 23.1765,
      longitude: 75.7885,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Loni',
      country: 'India',
      latitude: 28.7316,
      longitude: 77.3004,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Siliguri',
      country: 'India',
      latitude: 26.7271,
      longitude: 88.3953,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jhansi',
      country: 'India',
      latitude: 25.4484,
      longitude: 78.5685,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ulhasnagar',
      country: 'India',
      latitude: 19.2215,
      longitude: 73.1645,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jammu',
      country: 'India',
      latitude: 32.7266,
      longitude: 74.8570,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Sangli-Miraj & Kupwad',
      country: 'India',
      latitude: 16.8503,
      longitude: 74.5947,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Mangalore',
      country: 'India',
      latitude: 12.9141,
      longitude: 74.8560,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Erode',
      country: 'India',
      latitude: 11.3410,
      longitude: 77.7172,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Belgaum',
      country: 'India',
      latitude: 15.8497,
      longitude: 74.4977,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Ambattur',
      country: 'India',
      latitude: 13.1143,
      longitude: 80.1548,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Tirunelveli',
      country: 'India',
      latitude: 8.7139,
      longitude: 77.7567,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Malegaon',
      country: 'India',
      latitude: 20.5547,
      longitude: 74.5286,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Gaya',
      country: 'India',
      latitude: 24.7955,
      longitude: 84.9994,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Jalgaon',
      country: 'India',
      latitude: 21.0077,
      longitude: 75.5626,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Udaipur',
      country: 'India',
      latitude: 24.5854,
      longitude: 73.7125,
      timezone: 'Asia/Kolkata',
    ),
    City(
      name: 'Maheshtala',
      country: 'India',
      latitude: 22.5065,
      longitude: 88.2995,
      timezone: 'Asia/Kolkata',
    ),

    // United States
    City(
      name: 'New York',
      country: 'United States',
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: 'America/New_York',
    ),
    City(
      name: 'Los Angeles',
      country: 'United States',
      latitude: 34.0522,
      longitude: -118.2437,
      timezone: 'America/Los_Angeles',
    ),
    City(
      name: 'Chicago',
      country: 'United States',
      latitude: 41.8781,
      longitude: -87.6298,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'Houston',
      country: 'United States',
      latitude: 29.7604,
      longitude: -95.3698,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'Phoenix',
      country: 'United States',
      latitude: 33.4484,
      longitude: -112.0740,
      timezone: 'America/Phoenix',
    ),
    City(
      name: 'Philadelphia',
      country: 'United States',
      latitude: 39.9526,
      longitude: -75.1652,
      timezone: 'America/New_York',
    ),
    City(
      name: 'San Antonio',
      country: 'United States',
      latitude: 29.4241,
      longitude: -98.4936,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'San Diego',
      country: 'United States',
      latitude: 32.7157,
      longitude: -117.1611,
      timezone: 'America/Los_Angeles',
    ),
    City(
      name: 'Dallas',
      country: 'United States',
      latitude: 32.7767,
      longitude: -96.7970,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'San Jose',
      country: 'United States',
      latitude: 37.3382,
      longitude: -121.8863,
      timezone: 'America/Los_Angeles',
    ),
    City(
      name: 'Austin',
      country: 'United States',
      latitude: 30.2672,
      longitude: -97.7431,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'Jacksonville',
      country: 'United States',
      latitude: 30.3322,
      longitude: -81.6557,
      timezone: 'America/New_York',
    ),
    City(
      name: 'Fort Worth',
      country: 'United States',
      latitude: 32.7555,
      longitude: -97.3308,
      timezone: 'America/Chicago',
    ),
    City(
      name: 'Columbus',
      country: 'United States',
      latitude: 39.9612,
      longitude: -82.9988,
      timezone: 'America/New_York',
    ),
    City(
      name: 'Charlotte',
      country: 'United States',
      latitude: 35.2271,
      longitude: -80.8431,
      timezone: 'America/New_York',
    ),
    City(
      name: 'San Francisco',
      country: 'United States',
      latitude: 37.7749,
      longitude: -122.4194,
      timezone: 'America/Los_Angeles',
    ),
    City(
      name: 'Indianapolis',
      country: 'United States',
      latitude: 39.7684,
      longitude: -86.1581,
      timezone: 'America/New_York',
    ),
    City(
      name: 'Seattle',
      country: 'United States',
      latitude: 47.6062,
      longitude: -122.3321,
      timezone: 'America/Los_Angeles',
    ),
    City(
      name: 'Denver',
      country: 'United States',
      latitude: 39.7392,
      longitude: -104.9903,
      timezone: 'America/Denver',
    ),
    City(
      name: 'Washington',
      country: 'United States',
      latitude: 38.9072,
      longitude: -77.0369,
      timezone: 'America/New_York',
    ),

    // United Kingdom
    City(
      name: 'London',
      country: 'United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
    ),
    City(
      name: 'Birmingham',
      country: 'United Kingdom',
      latitude: 52.4862,
      longitude: -1.8904,
      timezone: 'Europe/London',
    ),
    City(
      name: 'Manchester',
      country: 'United Kingdom',
      latitude: 53.4808,
      longitude: -2.2426,
      timezone: 'Europe/London',
    ),
    City(
      name: 'Glasgow',
      country: 'United Kingdom',
      latitude: 55.8609,
      longitude: -4.2514,
      timezone: 'Europe/London',
    ),
    City(
      name: 'Liverpool',
      country: 'United Kingdom',
      latitude: 53.4084,
      longitude: -2.9916,
      timezone: 'Europe/London',
    ),

    // Canada
    City(
      name: 'Toronto',
      country: 'Canada',
      latitude: 43.6532,
      longitude: -79.3832,
      timezone: 'America/Toronto',
    ),
    City(
      name: 'Vancouver',
      country: 'Canada',
      latitude: 49.2827,
      longitude: -123.1207,
      timezone: 'America/Vancouver',
    ),
    City(
      name: 'Montreal',
      country: 'Canada',
      latitude: 45.5017,
      longitude: -73.5673,
      timezone: 'America/Toronto',
    ),
    City(
      name: 'Calgary',
      country: 'Canada',
      latitude: 51.0447,
      longitude: -114.0719,
      timezone: 'America/Edmonton',
    ),
    City(
      name: 'Ottawa',
      country: 'Canada',
      latitude: 45.4215,
      longitude: -75.6972,
      timezone: 'America/Toronto',
    ),

    // Australia
    City(
      name: 'Sydney',
      country: 'Australia',
      latitude: -33.8688,
      longitude: 151.2093,
      timezone: 'Australia/Sydney',
    ),
    City(
      name: 'Melbourne',
      country: 'Australia',
      latitude: -37.8136,
      longitude: 144.9631,
      timezone: 'Australia/Melbourne',
    ),
    City(
      name: 'Brisbane',
      country: 'Australia',
      latitude: -27.4698,
      longitude: 153.0251,
      timezone: 'Australia/Brisbane',
    ),
    City(
      name: 'Perth',
      country: 'Australia',
      latitude: -31.9505,
      longitude: 115.8605,
      timezone: 'Australia/Perth',
    ),
    City(
      name: 'Adelaide',
      country: 'Australia',
      latitude: -34.9285,
      longitude: 138.6007,
      timezone: 'Australia/Adelaide',
    ),

    // Europe
    City(
      name: 'Paris',
      country: 'France',
      latitude: 48.8566,
      longitude: 2.3522,
      timezone: 'Europe/Paris',
    ),
    City(
      name: 'Berlin',
      country: 'Germany',
      latitude: 52.5200,
      longitude: 13.4050,
      timezone: 'Europe/Berlin',
    ),
    City(
      name: 'Rome',
      country: 'Italy',
      latitude: 41.9028,
      longitude: 12.4964,
      timezone: 'Europe/Rome',
    ),
    City(
      name: 'Madrid',
      country: 'Spain',
      latitude: 40.4168,
      longitude: -3.7038,
      timezone: 'Europe/Madrid',
    ),
    City(
      name: 'Amsterdam',
      country: 'Netherlands',
      latitude: 52.3676,
      longitude: 4.9041,
      timezone: 'Europe/Amsterdam',
    ),
    City(
      name: 'Vienna',
      country: 'Austria',
      latitude: 48.2082,
      longitude: 16.3738,
      timezone: 'Europe/Vienna',
    ),
    City(
      name: 'Brussels',
      country: 'Belgium',
      latitude: 50.8503,
      longitude: 4.3517,
      timezone: 'Europe/Brussels',
    ),
    City(
      name: 'Zurich',
      country: 'Switzerland',
      latitude: 47.3769,
      longitude: 8.5417,
      timezone: 'Europe/Zurich',
    ),
    City(
      name: 'Stockholm',
      country: 'Sweden',
      latitude: 59.3293,
      longitude: 18.0686,
      timezone: 'Europe/Stockholm',
    ),
    City(
      name: 'Oslo',
      country: 'Norway',
      latitude: 59.9139,
      longitude: 10.7522,
      timezone: 'Europe/Oslo',
    ),
    City(
      name: 'Copenhagen',
      country: 'Denmark',
      latitude: 55.6761,
      longitude: 12.5683,
      timezone: 'Europe/Copenhagen',
    ),
    City(
      name: 'Helsinki',
      country: 'Finland',
      latitude: 60.1699,
      longitude: 24.9384,
      timezone: 'Europe/Helsinki',
    ),
    City(
      name: 'Moscow',
      country: 'Russia',
      latitude: 55.7558,
      longitude: 37.6173,
      timezone: 'Europe/Moscow',
    ),
    City(
      name: 'Prague',
      country: 'Czech Republic',
      latitude: 50.0755,
      longitude: 14.4378,
      timezone: 'Europe/Prague',
    ),
    City(
      name: 'Budapest',
      country: 'Hungary',
      latitude: 47.4979,
      longitude: 19.0402,
      timezone: 'Europe/Budapest',
    ),
    City(
      name: 'Warsaw',
      country: 'Poland',
      latitude: 52.2297,
      longitude: 21.0122,
      timezone: 'Europe/Warsaw',
    ),
    City(
      name: 'Dublin',
      country: 'Ireland',
      latitude: 53.3498,
      longitude: -6.2603,
      timezone: 'Europe/Dublin',
    ),
    City(
      name: 'Lisbon',
      country: 'Portugal',
      latitude: 38.7223,
      longitude: -9.1393,
      timezone: 'Europe/Lisbon',
    ),
    City(
      name: 'Athens',
      country: 'Greece',
      latitude: 37.9838,
      longitude: 23.7275,
      timezone: 'Europe/Athens',
    ),
    City(
      name: 'Istanbul',
      country: 'Turkey',
      latitude: 41.0082,
      longitude: 28.9784,
      timezone: 'Europe/Istanbul',
    ),

    // Asia
    City(
      name: 'Tokyo',
      country: 'Japan',
      latitude: 35.6762,
      longitude: 139.6503,
      timezone: 'Asia/Tokyo',
    ),
    City(
      name: 'Beijing',
      country: 'China',
      latitude: 39.9042,
      longitude: 116.4074,
      timezone: 'Asia/Shanghai',
    ),
    City(
      name: 'Shanghai',
      country: 'China',
      latitude: 31.2304,
      longitude: 121.4737,
      timezone: 'Asia/Shanghai',
    ),
    City(
      name: 'Singapore',
      country: 'Singapore',
      latitude: 1.3521,
      longitude: 103.8198,
      timezone: 'Asia/Singapore',
    ),
    City(
      name: 'Bangkok',
      country: 'Thailand',
      latitude: 13.7563,
      longitude: 100.5018,
      timezone: 'Asia/Bangkok',
    ),
    City(
      name: 'Seoul',
      country: 'South Korea',
      latitude: 37.5665,
      longitude: 126.9780,
      timezone: 'Asia/Seoul',
    ),
    City(
      name: 'Jakarta',
      country: 'Indonesia',
      latitude: -6.2088,
      longitude: 106.8456,
      timezone: 'Asia/Jakarta',
    ),
    City(
      name: 'Hong Kong',
      country: 'Hong Kong',
      latitude: 22.3193,
      longitude: 114.1694,
      timezone: 'Asia/Hong_Kong',
    ),
    City(
      name: 'Taipei',
      country: 'Taiwan',
      latitude: 25.0330,
      longitude: 121.5654,
      timezone: 'Asia/Taipei',
    ),
    City(
      name: 'Manila',
      country: 'Philippines',
      latitude: 14.5995,
      longitude: 120.9842,
      timezone: 'Asia/Manila',
    ),
    City(
      name: 'Kuala Lumpur',
      country: 'Malaysia',
      latitude: 3.1390,
      longitude: 101.6869,
      timezone: 'Asia/Kuala_Lumpur',
    ),
    City(
      name: 'Ho Chi Minh City',
      country: 'Vietnam',
      latitude: 10.8231,
      longitude: 106.6297,
      timezone: 'Asia/Ho_Chi_Minh',
    ),
    City(
      name: 'Hanoi',
      country: 'Vietnam',
      latitude: 21.0278,
      longitude: 105.8342,
      timezone: 'Asia/Ho_Chi_Minh',
    ),
    City(
      name: 'Dhaka',
      country: 'Bangladesh',
      latitude: 23.8103,
      longitude: 90.4125,
      timezone: 'Asia/Dhaka',
    ),
    City(
      name: 'Karachi',
      country: 'Pakistan',
      latitude: 24.8607,
      longitude: 67.0011,
      timezone: 'Asia/Karachi',
    ),
    City(
      name: 'Lahore',
      country: 'Pakistan',
      latitude: 31.5204,
      longitude: 74.3587,
      timezone: 'Asia/Karachi',
    ),
    City(
      name: 'Colombo',
      country: 'Sri Lanka',
      latitude: 6.9271,
      longitude: 79.8612,
      timezone: 'Asia/Colombo',
    ),
    City(
      name: 'Kathmandu',
      country: 'Nepal',
      latitude: 27.7172,
      longitude: 85.3240,
      timezone: 'Asia/Kathmandu',
    ),
    City(
      name: 'Thimphu',
      country: 'Bhutan',
      latitude: 27.4728,
      longitude: 89.6390,
      timezone: 'Asia/Thimphu',
    ),
    City(
      name: 'Male',
      country: 'Maldives',
      latitude: 4.1755,
      longitude: 73.5093,
      timezone: 'Indian/Maldives',
    ),

    // Middle East
    City(
      name: 'Dubai',
      country: 'UAE',
      latitude: 25.2048,
      longitude: 55.2708,
      timezone: 'Asia/Dubai',
    ),
    City(
      name: 'Abu Dhabi',
      country: 'UAE',
      latitude: 24.4539,
      longitude: 54.3773,
      timezone: 'Asia/Dubai',
    ),
    City(
      name: 'Riyadh',
      country: 'Saudi Arabia',
      latitude: 24.7136,
      longitude: 46.6753,
      timezone: 'Asia/Riyadh',
    ),
    City(
      name: 'Jeddah',
      country: 'Saudi Arabia',
      latitude: 21.4858,
      longitude: 39.1925,
      timezone: 'Asia/Riyadh',
    ),
    City(
      name: 'Doha',
      country: 'Qatar',
      latitude: 25.2854,
      longitude: 51.5310,
      timezone: 'Asia/Qatar',
    ),
    City(
      name: 'Kuwait City',
      country: 'Kuwait',
      latitude: 29.3759,
      longitude: 47.9774,
      timezone: 'Asia/Kuwait',
    ),
    City(
      name: 'Manama',
      country: 'Bahrain',
      latitude: 26.2285,
      longitude: 50.5860,
      timezone: 'Asia/Bahrain',
    ),
    City(
      name: 'Muscat',
      country: 'Oman',
      latitude: 23.5859,
      longitude: 58.4059,
      timezone: 'Asia/Muscat',
    ),
    City(
      name: 'Tehran',
      country: 'Iran',
      latitude: 35.6892,
      longitude: 51.3890,
      timezone: 'Asia/Tehran',
    ),
    City(
      name: 'Baghdad',
      country: 'Iraq',
      latitude: 33.3152,
      longitude: 44.3661,
      timezone: 'Asia/Baghdad',
    ),
    City(
      name: 'Jerusalem',
      country: 'Israel',
      latitude: 31.7683,
      longitude: 35.2137,
      timezone: 'Asia/Jerusalem',
    ),
    City(
      name: 'Tel Aviv',
      country: 'Israel',
      latitude: 32.0853,
      longitude: 34.7818,
      timezone: 'Asia/Jerusalem',
    ),
    City(
      name: 'Amman',
      country: 'Jordan',
      latitude: 31.9454,
      longitude: 35.9284,
      timezone: 'Asia/Amman',
    ),
    City(
      name: 'Beirut',
      country: 'Lebanon',
      latitude: 33.8938,
      longitude: 35.5018,
      timezone: 'Asia/Beirut',
    ),
    City(
      name: 'Cairo',
      country: 'Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      timezone: 'Africa/Cairo',
    ),
    City(
      name: 'Alexandria',
      country: 'Egypt',
      latitude: 31.2001,
      longitude: 29.9187,
      timezone: 'Africa/Cairo',
    ),

    // Africa
    City(
      name: 'Johannesburg',
      country: 'South Africa',
      latitude: -26.2041,
      longitude: 28.0473,
      timezone: 'Africa/Johannesburg',
    ),
    City(
      name: 'Cape Town',
      country: 'South Africa',
      latitude: -33.9249,
      longitude: 18.4241,
      timezone: 'Africa/Johannesburg',
    ),
    City(
      name: 'Durban',
      country: 'South Africa',
      latitude: -29.8587,
      longitude: 31.0218,
      timezone: 'Africa/Johannesburg',
    ),
    City(
      name: 'Lagos',
      country: 'Nigeria',
      latitude: 6.5244,
      longitude: 3.3792,
      timezone: 'Africa/Lagos',
    ),
    City(
      name: 'Abuja',
      country: 'Nigeria',
      latitude: 9.0765,
      longitude: 7.3986,
      timezone: 'Africa/Lagos',
    ),
    City(
      name: 'Nairobi',
      country: 'Kenya',
      latitude: -1.2921,
      longitude: 36.8219,
      timezone: 'Africa/Nairobi',
    ),
    City(
      name: 'Addis Ababa',
      country: 'Ethiopia',
      latitude: 9.1450,
      longitude: 40.4897,
      timezone: 'Africa/Addis_Ababa',
    ),
    City(
      name: 'Casablanca',
      country: 'Morocco',
      latitude: 33.5731,
      longitude: -7.5898,
      timezone: 'Africa/Casablanca',
    ),
    City(
      name: 'Tunis',
      country: 'Tunisia',
      latitude: 36.8065,
      longitude: 10.1815,
      timezone: 'Africa/Tunis',
    ),
    City(
      name: 'Algiers',
      country: 'Algeria',
      latitude: 36.7538,
      longitude: 3.0588,
      timezone: 'Africa/Algiers',
    ),
    City(
      name: 'Accra',
      country: 'Ghana',
      latitude: 5.6037,
      longitude: -0.1870,
      timezone: 'Africa/Accra',
    ),
    City(
      name: 'Dakar',
      country: 'Senegal',
      latitude: 14.7167,
      longitude: -17.4677,
      timezone: 'Africa/Dakar',
    ),

    // South America
    City(
      name: 'São Paulo',
      country: 'Brazil',
      latitude: -23.5505,
      longitude: -46.6333,
      timezone: 'America/Sao_Paulo',
    ),
    City(
      name: 'Rio de Janeiro',
      country: 'Brazil',
      latitude: -22.9068,
      longitude: -43.1729,
      timezone: 'America/Sao_Paulo',
    ),
    City(
      name: 'Brasília',
      country: 'Brazil',
      latitude: -15.7975,
      longitude: -47.8919,
      timezone: 'America/Sao_Paulo',
    ),
    City(
      name: 'Buenos Aires',
      country: 'Argentina',
      latitude: -34.6037,
      longitude: -58.3816,
      timezone: 'America/Argentina/Buenos_Aires',
    ),
    City(
      name: 'Lima',
      country: 'Peru',
      latitude: -12.0464,
      longitude: -77.0428,
      timezone: 'America/Lima',
    ),
    City(
      name: 'Bogotá',
      country: 'Colombia',
      latitude: 4.7110,
      longitude: -74.0721,
      timezone: 'America/Bogota',
    ),
    City(
      name: 'Santiago',
      country: 'Chile',
      latitude: -33.4489,
      longitude: -70.6693,
      timezone: 'America/Santiago',
    ),
    City(
      name: 'Caracas',
      country: 'Venezuela',
      latitude: 10.4806,
      longitude: -66.9036,
      timezone: 'America/Caracas',
    ),
    City(
      name: 'Montevideo',
      country: 'Uruguay',
      latitude: -34.9011,
      longitude: -56.1645,
      timezone: 'America/Montevideo',
    ),
    City(
      name: 'Quito',
      country: 'Ecuador',
      latitude: -0.1807,
      longitude: -78.4678,
      timezone: 'America/Guayaquil',
    ),

    // New Zealand
    City(
      name: 'Auckland',
      country: 'New Zealand',
      latitude: -36.8485,
      longitude: 174.7633,
      timezone: 'Pacific/Auckland',
    ),
    City(
      name: 'Wellington',
      country: 'New Zealand',
      latitude: -41.2865,
      longitude: 174.7762,
      timezone: 'Pacific/Auckland',
    ),
    City(
      name: 'Christchurch',
      country: 'New Zealand',
      latitude: -43.5321,
      longitude: 172.6362,
      timezone: 'Pacific/Auckland',
    ),
  ];

  /// Search cities by name
  static List<City> searchCities(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _cities.where((city) {
      return city.name.toLowerCase().contains(lowerQuery) ||
          city.country.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get city by exact name
  static City? getCityByName(String name) {
    try {
      return _cities.firstWhere(
        (city) => city.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all cities in a country
  static List<City> getCitiesByCountry(String country) {
    return _cities
        .where((city) => city.country.toLowerCase() == country.toLowerCase())
        .toList();
  }

  /// Get current location using GPS
  static Future<City?> getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Find nearest city
      return findNearestCity(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Find nearest city to coordinates
  static City findNearestCity(double latitude, double longitude) {
    City? nearest;
    double minDistance = double.infinity;

    for (final city in _cities) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = city;
      }
    }

    return nearest!;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get all countries
  static List<String> get countries {
    return _cities.map((city) => city.country).toSet().toList()..sort();
  }

  /// Get all cities
  static List<City> get allCities => List.unmodifiable(_cities);

  /// Get total number of cities
  static int get cityCount => _cities.length;
}

/// City data class
class City {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;

  const City({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  String get displayName => '$name, $country';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.name == name && other.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ country.hashCode;
}

/// Location Service for managing GPS and city selection
class LocationService {
  /// Request location permission
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get city from current position
  static Future<City?> getCityFromCurrentPosition() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return CityDatabase.findNearestCity(position.latitude, position.longitude);
  }
}
