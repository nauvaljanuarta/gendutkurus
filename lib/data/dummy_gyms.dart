import '../models/gym_model.dart';

const List<String> gymCategories = [
  'Semua',
  'Gym Premium',
  'Gym Murah',
  'Gym 24 Jam',
  'Fitness Wanita',
  'CrossFit',
];

const List<Gym> dummyGyms = [
  Gym(
    id: 'gym1',
    name: 'Iron Studio Surabaya',
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1200&q=80',
    rating: 4.8,
    address: 'Jl. Mayjen Sungkono No.17, Surabaya',
    distance: '1.2 km',
    openHours: '05:00 - 23:00',
    facilities: ['Free Wifi', 'Sauna', 'Personal Trainer', 'Kelas Yoga'],
    description:
        'Iron Studio menyediakan peralatan premium, area cardio luas, dan program kebugaran profesional untuk semua level.',
    isFavorite: true,
    category: 'Gym Premium',
  ),
  Gym(
    id: 'gym2',
    name: 'FitHouse Murah',
    imageUrl:
        'https://images.unsplash.com/photo-1571019613914-85f342c4d68f?auto=format&fit=crop&w=1200&q=80',
    rating: 4.3,
    address: 'Jl. Darmo Permai II No.45, Surabaya',
    distance: '3.6 km',
    openHours: '06:00 - 22:00',
    facilities: ['Loker', 'Parkir Luas', 'Kelas Zumba'],
    description:
        'Solusi gym hemat dengan fasilitas lengkap dan suasana ramah untuk pemula dan keluarga.',
    isFavorite: false,
    category: 'Gym Murah',
  ),
  Gym(
    id: 'gym3',
    name: 'Gym 24/7 Surabaya',
    imageUrl:
        'https://images.unsplash.com/photo-1594737625785-4365c4d189d2?auto=format&fit=crop&w=1200&q=80',
    rating: 4.6,
    address: 'Jl. Siwalankerto No.12, Surabaya',
    distance: '2.8 km',
    openHours: 'Buka 24 Jam',
    facilities: ['24 Jam', 'Trainer Tersedia', 'Kelas Malam'],
    description:
        'Gym 24 jam yang cocok untuk pekerja shift dan member yang ingin fleksibel berolahraga kapan saja.',
    isFavorite: true,
    category: 'Gym 24 Jam',
  ),
  Gym(
    id: 'gym4',
    name: 'HerFit Surabaya',
    imageUrl:
        'https://images.unsplash.com/photo-1546484959-f9c5da3853c0?auto=format&fit=crop&w=1200&q=80',
    rating: 4.7,
    address: 'Jl. Tunjungan No.86, Surabaya',
    distance: '4.1 km',
    openHours: '06:00 - 22:00',
    facilities: [
      'Kelas Pilates',
      'Instruktur Wanita',
      'Ruang Ganti',
      'Kafe Sehat',
    ],
    description:
        'HerFit fokus pada kenyamanan wanita dengan kelas khusus dan lingkungan yang mendukung.',
    isFavorite: false,
    category: 'Fitness Wanita',
  ),
  Gym(
    id: 'gym5',
    name: 'CrossFit Surabaya',
    imageUrl:
        'https://images.unsplash.com/photo-1508609349937-5ec4ae374ebf?auto=format&fit=crop&w=1200&q=80',
    rating: 4.9,
    address: 'Jl. Raya Darmo No.202, Surabaya',
    distance: '2.0 km',
    openHours: '06:00 - 21:00',
    facilities: ['CrossFit Box', 'Kelas Grup', 'Nutrisi'],
    description:
        'Tempat terbaik untuk sesi CrossFit intens dengan coach tersertifikasi dan suasana kompetitif.',
    isFavorite: false,
    category: 'CrossFit',
  ),
];
