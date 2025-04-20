import 'dart:ui';
import 'package:flutter/material.dart';
import 'board_model.dart';
import 'task_model.dart';

class WhiteboardItem {
  String id;
  Offset position;
  Size size;
  double scale;
  double rotation;

  WhiteboardItem({
    required this.id,
    required this.position,
    required this.size,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'size': {
        'width': size.width,
        'height': size.height,
      },
      'scale': scale,
      'rotation': rotation,
    };
  }

  factory WhiteboardItem.fromJson(Map<String, dynamic> json) {
    return WhiteboardItem(
      id: json['id'],
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
      scale: json['scale']?.toDouble() ?? 1.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
    );
  }
}

class WhiteboardBoard extends WhiteboardItem {
  Board board;
  List<WhiteboardTask> tasks;

  WhiteboardBoard({
    required String id,
    required Offset position,
    required Size size,
    double scale = 1.0,
    double rotation = 0.0,
    required this.board,
    required this.tasks,
  }) : super(
          id: id,
          position: position,
          size: size,
          scale: scale,
          rotation: rotation,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['board'] = board.toJson();
    json['tasks'] = tasks.map((task) => task.toJson()).toList();
    json['type'] = 'board';
    return json;
  }

  factory WhiteboardBoard.fromJson(Map<String, dynamic> json) {
    return WhiteboardBoard(
      id: json['id'],
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
      scale: json['scale']?.toDouble() ?? 1.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      board: Board.fromJson(json['board']),
      tasks: (json['tasks'] as List)
          .map((task) => WhiteboardTask.fromJson(task))
          .toList(),
    );
  }

  WhiteboardBoard copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? scale,
    double? rotation,
    Board? board,
    List<WhiteboardTask>? tasks,
  }) {
    return WhiteboardBoard(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      board: board ?? this.board,
      tasks: tasks ?? this.tasks,
    );
  }
}

class WhiteboardTask extends WhiteboardItem {
  Task task;

  WhiteboardTask({
    required String id,
    required Offset position,
    required Size size,
    double scale = 1.0,
    double rotation = 0.0,
    required this.task,
  }) : super(
          id: id,
          position: position,
          size: size,
          scale: scale,
          rotation: rotation,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['task'] = task.toJson();
    json['type'] = 'task';
    return json;
  }

  factory WhiteboardTask.fromJson(Map<String, dynamic> json) {
    return WhiteboardTask(
      id: json['id'],
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
      scale: json['scale']?.toDouble() ?? 1.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      task: Task.fromJson(json['task']),
    );
  }

  WhiteboardTask copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? scale,
    double? rotation,
    Task? task,
  }) {
    return WhiteboardTask(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      task: task ?? this.task,
    );
  }
}

class Whiteboard {
  String id;
  String projectId;
  String title;
  List<WhiteboardBoard> boards;
  Offset viewportPosition;
  double viewportScale;

  Whiteboard({
    required this.id,
    required this.projectId,
    required this.title,
    required this.boards,
    this.viewportPosition = Offset.zero,
    this.viewportScale = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'boards': boards.map((board) => board.toJson()).toList(),
      'viewportPosition': {
        'x': viewportPosition.dx,
        'y': viewportPosition.dy,
      },
      'viewportScale': viewportScale,
    };
  }

  factory Whiteboard.fromJson(Map<String, dynamic> json) {
    return Whiteboard(
      id: json['id'],
      projectId: json['projectId'],
      title: json['title'],
      boards: (json['boards'] as List)
          .map((board) => WhiteboardBoard.fromJson(board))
          .toList(),
      viewportPosition: json['viewportPosition'] != null
          ? Offset(
              json['viewportPosition']['x'].toDouble(),
              json['viewportPosition']['y'].toDouble(),
            )
          : Offset.zero,
      viewportScale: json['viewportScale']?.toDouble() ?? 1.0,
    );
  }

  Whiteboard copyWith({
    String? id,
    String? projectId,
    String? title,
    List<WhiteboardBoard>? boards,
    Offset? viewportPosition,
    double? viewportScale,
  }) {
    return Whiteboard(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      boards: boards ?? this.boards,
      viewportPosition: viewportPosition ?? this.viewportPosition,
      viewportScale: viewportScale ?? this.viewportScale,
    );
  }
}
