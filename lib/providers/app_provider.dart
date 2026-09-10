// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';

// import '../models/call_model.dart';
// import '../models/user_model.dart';

// final currentUserProvider =
//     StateProvider<UserModel>((ref) {
//   return const UserModel(
//     id: 'me',
//     name: 'Alex Morgan',
//     email: 'alex@example.com',
//     initials: 'AM',
//     online: true, phoneNumber: '',
//   );
// });

// final contactsProvider =
//     Provider<List<UserModel>>((ref) {
//   return const [
//     UserModel(
//       id: '1',
//       name: 'Sarah Johnson',
//       email: 'sarah@example.com',
//       initials: 'SJ',
//       online: true, phoneNumber: '',
//     ),

//     UserModel(
//       id: '2',
//       name: 'Michael Chen',
//       email: 'michael@example.com',
//       initials: 'MC',
//       online: true, phoneNumber: '',
//     ),

//     UserModel(
//       id: '3',
//       name: 'Emily Davis',
//       email: 'emily@example.com',
//       initials: 'ED',
//       online: false, phoneNumber: '',
//     ),

//     UserModel(
//       id: '4',
//       name: 'David Wilson',
//       email: 'david@example.com',
//       initials: 'DW',
//       online: true, phoneNumber: '',
//     ),

//     UserModel(
//       id: '5',
//       name: 'Olivia Brown',
//       email: 'olivia@example.com',
//       initials: 'OB',
//       online: false, phoneNumber: '',
//     ),
//   ];
// });

// final selectedTabProvider =
//     StateProvider<int>((ref) => 0);

// final callHistoryProvider =
//     StateProvider<List<CallModel>>((ref) {
//   final contacts = ref.read(contactsProvider);

//   return [
//     CallModel(
//       user: contacts[0],
//       type: CallType.video,
//       direction: CallDirection.outgoing,
//       status: CallStatus.completed,
//       time: 'Today, 10:42 AM',
//       duration: '08:24',
//     ),

//     CallModel(
//       user: contacts[1],
//       type: CallType.audio,
//       direction: CallDirection.incoming,
//       status: CallStatus.completed,
//       time: 'Yesterday, 6:18 PM',
//       duration: '04:12',
//     ),

//     CallModel(
//       user: contacts[2],
//       type: CallType.video,
//       direction: CallDirection.incoming,
//       status: CallStatus.missed,
//       time: 'Yesterday, 2:30 PM',
//       duration: '—',
//     ),
//   ];
// });