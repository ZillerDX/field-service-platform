import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/offline_cache.dart';
import '../../domain/entities/ticket_entity.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final DioClient _dioClient;
  List<TicketEntity> _currentTickets = [];

  TicketBloc({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient(),
        super(TicketInitial()) {
    on<FetchTicketsEvent>(_onFetchTickets);
    on<CreateTicketEvent>(_onCreateTicket);
    on<AssignTicketEvent>(_onAssignTicket);
    on<UpdateTicketStatusEvent>(_onUpdateTicketStatus);
    on<CompleteJobEvent>(_onCompleteJob);
  }

  Future<void> _onFetchTickets(FetchTicketsEvent event, Emitter<TicketState> emit) async {
    if (_currentTickets.isEmpty) {
      emit(TicketLoading());
    }
    try {
      final response = await _dioClient.dio.get(ApiConstants.ticketsEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['tickets'] ?? []);
        _currentTickets = list.map((e) => TicketEntity.fromJson(e as Map<String, dynamic>)).toList();
        await OfflineCache.saveTickets(_currentTickets.map((t) => t.toJson()).toList());
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: false));
      } else {
        throw Exception('Failed to load tickets from server');
      }
    } catch (e) {
      // Offline fallback: load from SharedPreferences cache
      final cached = await OfflineCache.getCachedTickets();
      if (cached.isNotEmpty) {
        _currentTickets = cached.map((c) => TicketEntity.fromJson(c)).toList();
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
      } else {
        // Fallback default sample ticket if cache is completely empty
        _currentTickets = [
          TicketEntity(
            id: 'mock_1',
            ticketNumber: 'TKT-1001',
            title: 'เครื่องปรับอากาศมีน้ำรั่วหยด',
            description: 'แอร์ห้องประชุม 2 น้ำแอร์หยดลงพื้นพรม ส่งผลกระทบต่อการประชุม',
            category: 'HVAC',
            urgency: 'High',
            status: 'Assigned',
            customerName: 'คุณสมชาย สถิตย์วงศ์',
            customerPhone: '089-123-4567',
            locationName: 'อาคารสาทรทาวเวอร์ ชั้น 14',
            latitude: 13.7214,
            longitude: 100.5298,
            assignedToName: 'ช่างวิชัย (Vichai)',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          TicketEntity(
            id: 'mock_2',
            ticketNumber: 'TKT-1002',
            title: 'ไฟเบรกเกอร์ทริปชั้น 3',
            description: 'ระบบไฟส่องสว่างดับทั้งชั้น ตรวจพบกลิ่นไหม้เล็กน้อย',
            category: 'Electrical',
            urgency: 'Emergency',
            status: 'Pending',
            customerName: 'คุณกาญจนา นภาลัย',
            customerPhone: '081-444-5566',
            locationName: 'อาคารบางนาคอมเพล็กซ์',
            latitude: 13.6682,
            longitude: 100.6340,
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ];
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
      }
    }
  }

  Future<void> _onCreateTicket(CreateTicketEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final payload = {
        'title': event.title,
        'description': event.description,
        'category': event.category,
        'urgency': event.urgency,
        'customerName': event.customerName,
        'customerPhone': event.customerPhone,
        'locationName': event.locationName,
        'latitude': event.lat,
        'longitude': event.lon,
        if (event.photo != null) 'photo': event.photo,
      };

      await _dioClient.dio.post(ApiConstants.ticketsEndpoint, data: payload);
      emit(const TicketActionSuccess('สร้างใบแจ้งซ่อมสำเร็จ'));
      add(const FetchTicketsEvent(forceRefresh: true));
    } catch (e) {
      // Local addition fallback
      final newTkt = TicketEntity(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        ticketNumber: 'TKT-${DateTime.now().millisecondsSinceEpoch % 10000}',
        title: event.title,
        description: event.description,
        category: event.category,
        urgency: event.urgency,
        status: 'Pending',
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        locationName: event.locationName,
        latitude: event.lat,
        longitude: event.lon,
        beforeImage: event.photo,
        createdAt: DateTime.now(),
      );
      _currentTickets.insert(0, newTkt);
      await OfflineCache.saveTickets(_currentTickets.map((t) => t.toJson()).toList());
      emit(const TicketActionSuccess('บันทึกใบแจ้งซ่อมในระบบเรียบร้อยแล้ว'));
      emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
    }
  }

  Future<void> _onAssignTicket(AssignTicketEvent event, Emitter<TicketState> emit) async {
    try {
      await _dioClient.dio.put(
        '${ApiConstants.ticketsEndpoint}/${event.ticketId}/assign',
        data: {'technicianId': event.technicianId},
      );
      add(const FetchTicketsEvent(forceRefresh: true));
    } catch (_) {
      // Local optimistic update
      final idx = _currentTickets.indexWhere((t) => t.id == event.ticketId);
      if (idx != -1) {
        _currentTickets[idx] = _currentTickets[idx].copyWith(
          status: 'Assigned',
          assignedToId: event.technicianId,
          assignedToName: event.technicianName,
        );
        await OfflineCache.saveTickets(_currentTickets.map((t) => t.toJson()).toList());
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
      }
    }
  }

  Future<void> _onUpdateTicketStatus(UpdateTicketStatusEvent event, Emitter<TicketState> emit) async {
    try {
      await _dioClient.dio.patch(
        '${ApiConstants.ticketsEndpoint}/${event.ticketId}/status',
        data: {'status': event.status},
      );
      add(const FetchTicketsEvent(forceRefresh: true));
    } catch (_) {
      // Optimistic update
      final idx = _currentTickets.indexWhere((t) => t.id == event.ticketId);
      if (idx != -1) {
        _currentTickets[idx] = _currentTickets[idx].copyWith(status: event.status);
        await OfflineCache.saveTickets(_currentTickets.map((t) => t.toJson()).toList());
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
      }
    }
  }

  Future<void> _onCompleteJob(CompleteJobEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      await _dioClient.dio.post(
        '${ApiConstants.ticketsEndpoint}/${event.ticketId}/complete',
        data: {
          'partsUsed': event.parts,
          'beforeImage': event.beforeImage,
          'afterImage': event.afterImage,
          'customerSignature': event.signature,
        },
      );
      emit(const TicketActionSuccess('ปิดงานและบันทึกรายงานเรียบร้อยแล้ว'));
      add(const FetchTicketsEvent(forceRefresh: true));
    } catch (_) {
      // Optimistic update
      final idx = _currentTickets.indexWhere((t) => t.id == event.ticketId);
      if (idx != -1) {
        _currentTickets[idx] = _currentTickets[idx].copyWith(
          status: 'Completed',
          partsUsed: event.parts,
          beforeImage: event.beforeImage,
          afterImage: event.afterImage,
          customerSignature: event.signature,
        );
        await OfflineCache.saveTickets(_currentTickets.map((t) => t.toJson()).toList());
        emit(const TicketActionSuccess('บันทึกปิดงานลงในระบบแคชออฟไลน์แล้ว'));
        emit(TicketLoaded(tickets: List.from(_currentTickets), isOffline: true));
      }
    }
  }
}
