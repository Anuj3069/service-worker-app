import 'package:flutter_test/flutter_test.dart';
import 'package:worker_app/models/booking.dart';

void main() {
  test('Booking model parses JSON correctly', () {
    final json = {
      '_id': '123',
      'userId': {
        '_id': 'u1',
        'name': 'John Doe',
        'email': 'john@example.com',
      },
      'providerId': 'p1',
      'serviceId': {
        '_id': 's1',
        'name': 'AC Repair',
      },
      'date': '2026-05-24T00:00:00.000Z',
      'slot': '10:00 AM',
      'status': 'accepted',
      'price': 500,
      'createdAt': '2026-05-24T00:00:00.000Z',
      'customerLocation': {
        'coordinates': [77.2090, 28.6139],
        'address': 'Connaught Place, New Delhi',
      },
    };

    final booking = Booking.fromJson(json);

    expect(booking.id, '123');
    expect(booking.customerName, 'John Doe');
    expect(booking.customerEmail, 'john@example.com');
    expect(booking.serviceName, 'AC Repair');
    expect(booking.price, 500.0);
    expect(booking.customerLatitude, 28.6139);
    expect(booking.customerLongitude, 77.2090);
    expect(booking.customerAddress, 'Connaught Place, New Delhi');
  });
}
