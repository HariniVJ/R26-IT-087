String formatFarmDateTime(DateTime time) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final ampm = time.hour >= 12 ? 'PM' : 'AM';
  return '${time.day} ${months[time.month - 1]} ${time.year} - '
      '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $ampm';
}

String formatFarmDate(DateTime time) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${time.day} ${months[time.month - 1]} ${time.year}';
}
