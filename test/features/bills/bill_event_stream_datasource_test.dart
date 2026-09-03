import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/data/datasources/bill_event_stream_datasource.dart';

void main() {
  group('parseBillSseLines', () {
    test('parses standard SSE events with event name and JSON data', () async {
      final lines = Stream.fromIterable([
        'event: ocr.updated',
        'data: {"job_id":"j-1","status":"succeeded"}',
        '',
      ]);

      final frames = await parseBillSseLines(lines).toList();

      expect(frames.length, 1);
      expect(frames.first.event, 'ocr.updated');
      expect(frames.first.data['job_id'], 'j-1');
      expect(frames.first.data['status'], 'succeeded');
    });

    test('ignores heartbeat comments starting with colon', () async {
      final lines = Stream.fromIterable([
        ': ping',
        'event: heartbeat',
        'data: {"timestamp":1788400000}',
        '',
        ': keepalive',
        'event: ocr.updated',
        'data: {"status":"failed","error":"OCR timeout"}',
        '',
      ]);

      final frames = await parseBillSseLines(lines).toList();

      expect(frames.length, 2);
      expect(frames[0].event, 'heartbeat');
      expect(frames[1].event, 'ocr.updated');
      expect(frames[1].data['status'], 'failed');
      expect(frames[1].data['error'], 'OCR timeout');
    });

    test('correctly parses initial snapshot event', () async {
      final lines = Stream.fromIterable([
        'event: snapshot',
        'data: {"bill_id":"b-123","ocr_job":{"id":"j-99","status":"processing"}}',
        '',
      ]);

      final frames = await parseBillSseLines(lines).toList();

      expect(frames.length, 1);
      expect(frames.first.event, 'snapshot');
      expect(frames.first.data['bill_id'], 'b-123');
      expect(frames.first.data['ocr_job']['status'], 'processing');
    });
  });
}
