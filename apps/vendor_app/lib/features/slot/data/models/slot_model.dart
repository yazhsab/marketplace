class SlotModel {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int maxBookings;
  final int currentBookings;
  final bool isAvailable;

  const SlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.maxBookings = 1,
    this.currentBookings = 0,
    this.isAvailable = true,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      maxBookings: json['maxBookings'] as int? ?? 1,
      currentBookings: json['currentBookings'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T')[0],
        'startTime': startTime,
        'endTime': endTime,
        'maxBookings': maxBookings,
      };

  bool get isFull => currentBookings >= maxBookings;
  int get availableSlots => maxBookings - currentBookings;
}
