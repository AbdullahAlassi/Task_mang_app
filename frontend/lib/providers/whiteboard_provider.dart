import 'package:flutter/material.dart';
import 'package:frontend/services/whiteboard.service.dart';
import '../models/whiteboard_model.dart';

class WhiteboardProvider extends ChangeNotifier {
  final WhiteboardService _whiteboardService = WhiteboardService();

  Whiteboard? _whiteboard;
  bool _isLoading = false;
  String? _error;

  // Selected items
  WhiteboardItem? _selectedItem;

  // Getters
  Whiteboard? get whiteboard => _whiteboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  WhiteboardItem? get selectedItem => _selectedItem;

  // Load whiteboard for a project
  Future<void> loadWhiteboard(String projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _whiteboard = await _whiteboardService.getWhiteboardForProject(projectId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Save whiteboard
  Future<void> saveWhiteboard() async {
    if (_whiteboard == null) return;

    try {
      await _whiteboardService.saveWhiteboard(_whiteboard!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add board to whiteboard
  Future<void> addBoard(String title, Offset position) async {
    if (_whiteboard == null) return;

    try {
      final board = await _whiteboardService.addBoardToWhiteboard(
        _whiteboard!.projectId,
        title,
        position,
      );

      _whiteboard = _whiteboard!.copyWith(
        boards: [..._whiteboard!.boards, board],
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add task to board
  Future<void> addTask(String boardId, String title, Offset position) async {
    if (_whiteboard == null) return;

    try {
      final task = await _whiteboardService.addTaskToBoard(
        _whiteboard!.projectId,
        boardId,
        title,
        position,
      );

      final boardIndex = _whiteboard!.boards.indexWhere((b) => b.id == boardId);
      if (boardIndex == -1) return;

      final board = _whiteboard!.boards[boardIndex];
      final updatedBoard = board.copyWith(
        tasks: [...board.tasks, task],
      );

      final updatedBoards = [..._whiteboard!.boards];
      updatedBoards[boardIndex] = updatedBoard;

      _whiteboard = _whiteboard!.copyWith(
        boards: updatedBoards,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update board position
  Future<void> updateBoardPosition(String boardId, Offset position) async {
    if (_whiteboard == null) return;

    try {
      final boardIndex = _whiteboard!.boards.indexWhere((b) => b.id == boardId);
      if (boardIndex == -1) return;

      final board = _whiteboard!.boards[boardIndex];
      final updatedBoard = board.copyWith(
        position: position,
      );

      final updatedBoards = [..._whiteboard!.boards];
      updatedBoards[boardIndex] = updatedBoard;

      _whiteboard = _whiteboard!.copyWith(
        boards: updatedBoards,
      );

      notifyListeners();

      // Update on server
      await _whiteboardService.updateBoardPosition(
        _whiteboard!.projectId,
        boardId,
        position,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update task position
  Future<void> updateTaskPosition(
      String boardId, String taskId, Offset position) async {
    if (_whiteboard == null) return;

    try {
      final boardIndex = _whiteboard!.boards.indexWhere((b) => b.id == boardId);
      if (boardIndex == -1) return;

      final board = _whiteboard!.boards[boardIndex];
      final taskIndex = board.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = board.tasks[taskIndex];
      final updatedTask = task.copyWith(
        position: position,
      );

      final updatedTasks = [...board.tasks];
      updatedTasks[taskIndex] = updatedTask;

      final updatedBoard = board.copyWith(
        tasks: updatedTasks,
      );

      final updatedBoards = [..._whiteboard!.boards];
      updatedBoards[boardIndex] = updatedBoard;

      _whiteboard = _whiteboard!.copyWith(
        boards: updatedBoards,
      );

      notifyListeners();

      // Update on server
      await _whiteboardService.updateTaskPosition(
        _whiteboard!.projectId,
        boardId,
        taskId,
        position,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete board
  Future<void> deleteBoard(String boardId) async {
    if (_whiteboard == null) return;

    try {
      final updatedBoards =
          _whiteboard!.boards.where((b) => b.id != boardId).toList();

      _whiteboard = _whiteboard!.copyWith(
        boards: updatedBoards,
      );

      notifyListeners();

      // Delete on server
      await _whiteboardService.deleteBoard(
        _whiteboard!.projectId,
        boardId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete task
  Future<void> deleteTask(String boardId, String taskId) async {
    if (_whiteboard == null) return;

    try {
      final boardIndex = _whiteboard!.boards.indexWhere((b) => b.id == boardId);
      if (boardIndex == -1) return;

      final board = _whiteboard!.boards[boardIndex];
      final updatedTasks = board.tasks.where((t) => t.id != taskId).toList();

      final updatedBoard = board.copyWith(
        tasks: updatedTasks,
      );

      final updatedBoards = [..._whiteboard!.boards];
      updatedBoards[boardIndex] = updatedBoard;

      _whiteboard = _whiteboard!.copyWith(
        boards: updatedBoards,
      );

      notifyListeners();

      // Delete on server
      await _whiteboardService.deleteTask(
        _whiteboard!.projectId,
        boardId,
        taskId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update viewport position and scale
  void updateViewport(Offset position, double scale) {
    if (_whiteboard == null) return;

    _whiteboard = _whiteboard!.copyWith(
      viewportPosition: position,
      viewportScale: scale,
    );

    notifyListeners();
  }

  // Select item
  void selectItem(WhiteboardItem? item) {
    _selectedItem = item;
    notifyListeners();
  }
}
