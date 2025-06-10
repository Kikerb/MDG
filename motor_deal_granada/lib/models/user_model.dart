import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final Timestamp createdAt;
  final int followersCount;
  final int followingCount;
  final int garageSlots;
  final int garageSlotsUsed;
  final bool isPremiumUser;
  final Timestamp lastActive;
  final List<String> interests;
  final String? bio;
  final List<String> savedVehicleIds; // <--- NEW FIELD: List of saved vehicle IDs

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.garageSlots = 3,
    this.garageSlotsUsed = 0,
    this.isPremiumUser = false,
    required this.lastActive,
    this.interests = const [],
    this.bio,
    this.savedVehicleIds = const [], // <--- Initialize in constructor
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? 'Usuario Anónimo',
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      garageSlots: data['garageSlots'] ?? 3,
      garageSlotsUsed: data['garageSlotsUsed'] ?? 0,
      isPremiumUser: data['isPremiumUser'] ?? false,
      lastActive: data['lastActive'] ?? Timestamp.now(),
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'] as String?,
      savedVehicleIds: List<String>.from(data['savedVehicleIds'] ?? []), // <--- Read from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'garageSlots': garageSlots,
      'garageSlotsUsed': garageSlotsUsed,
      'isPremiumUser': isPremiumUser,
      'lastActive': lastActive,
      'interests': interests,
      'bio': bio,
      'savedVehicleIds': savedVehicleIds, // <--- Write to Firestore
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    Timestamp? createdAt,
    int? followersCount,
    int? followingCount,
    int? garageSlots,
    int? garageSlotsUsed,
    bool? isPremiumUser,
    Timestamp? lastActive,
    List<String>? interests,
    String? bio,
    List<String>? savedVehicleIds, // <--- Add to copyWith
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      garageSlots: garageSlots ?? this.garageSlots,
      garageSlotsUsed: garageSlotsUsed ?? this.garageSlotsUsed,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      lastActive: lastActive ?? this.lastActive,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      savedVehicleIds: savedVehicleIds ?? this.savedVehicleIds, // <--- Assign in copyWith
    );
  }
}