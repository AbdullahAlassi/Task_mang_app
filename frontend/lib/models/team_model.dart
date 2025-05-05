import 'package:flutter/material.dart';
import 'user_model.dart';

class Team {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final List<String> childrenIds;
  final List<TeamMember> members;
  final String? department;
  final String type;
  final String status;
  final TeamMetadata metadata;
  final TeamSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.childrenIds,
    required this.members,
    this.department,
    required this.type,
    required this.status,
    required this.metadata,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      parentId:
          json['parent'] is String ? json['parent'] : json['parent']?['_id'],
      childrenIds: (json['children'] as List<dynamic>?)
              ?.map((child) => child is String ? child : child['_id'])
              .where((id) => id != null)
              .cast<String>()
              .toList() ??
          [],
      members: (json['members'] as List<dynamic>?)
              ?.map((member) => TeamMember.fromJson(member))
              .toList() ??
          [],
      department: json['department'],
      type: json['type'] ?? 'functional',
      status: json['status'] ?? 'active',
      metadata: TeamMetadata.fromJson(json['metadata'] ?? {}),
      settings: TeamSettings.fromJson(json['settings'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'parent': parentId,
      'children': childrenIds,
      'members': members.map((m) => m.toJson()).toList(),
      'department': department,
      'type': type,
      'status': status,
      'metadata': metadata.toJson(),
      'settings': settings.toJson(),
    };
  }
}

class TeamMember {
  final String userId;
  final String role;
  final DateTime joinedAt;
  final List<String> responsibilities;
  final List<String> skills;

  TeamMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.responsibilities,
    required this.skills,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user'] is String ? json['user'] : json['user']['_id'],
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'responsibilities': responsibilities,
      'skills': skills,
    };
  }
}

class TeamMetadata {
  final String? location;
  final String? timezone;
  final String? workingHours;
  final String? meetingSchedule;

  TeamMetadata({
    this.location,
    this.timezone,
    this.workingHours,
    this.meetingSchedule,
  });

  factory TeamMetadata.fromJson(Map<String, dynamic> json) {
    return TeamMetadata(
      location: json['location'],
      timezone: json['timezone'],
      workingHours: json['workingHours'],
      meetingSchedule: json['meetingSchedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'timezone': timezone,
      'workingHours': workingHours,
      'meetingSchedule': meetingSchedule,
    };
  }
}

class TeamSettings {
  final bool allowMemberInvites;
  final bool requireApprovalForJoining;
  final String visibility;

  TeamSettings({
    required this.allowMemberInvites,
    required this.requireApprovalForJoining,
    required this.visibility,
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) {
    return TeamSettings(
      allowMemberInvites: json['allowMemberInvites'] ?? false,
      requireApprovalForJoining: json['requireApprovalForJoining'] ?? true,
      visibility: json['visibility'] ?? 'private',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowMemberInvites': allowMemberInvites,
      'requireApprovalForJoining': requireApprovalForJoining,
      'visibility': visibility,
    };
  }
}
