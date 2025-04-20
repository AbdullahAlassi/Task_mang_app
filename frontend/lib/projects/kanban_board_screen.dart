import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../../../config/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../models/board_model.dart';
import '../../../models/task_model.dart';
import '../../../services/project_service.dart';
import '../../../services/board_service.dart';

class KanbanBoardScreen extends StatefulWidget {
  final String projectId;

  const KanbanBoardScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  bool _isLoading = true;
  late Project _project;
  List<KanbanColumn> _columns = [];

  final _projectService = ProjectService();
  final _boardService = BoardService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final project = await _projectService.getProjectDetails(widget.projectId);
      final columns = await _boardService.getKanbanColumns(widget.projectId);

      setState(() {
        _project = project;
        _columns = columns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load project data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: _project.getBannerColor(),
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        // Background color
                        Container(
                          color: _project.getBannerColor(),
                        ),

                        // Back button
                        Positioned(
                          top: 40,
                          left: 16,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // More options button
                        Positioned(
                          top: 40,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.more_horiz,
                                  color: Colors.black),
                              onPressed: () {
                                // Show options menu
                              },
                            ),
                          ),
                        ),

                        // Team members
                        Positioned(
                          top: 100,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                // Display actual project members
                                for (int i = 0;
                                    i < _project.memberIds.length.clamp(0, 4);
                                    i++)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey[300],
                                      child: Text(
                                        _project.memberIds[i]
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Show "+X more" if there are more than 4 members
                                if (_project.memberIds.length > 4)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      '+${_project.memberIds.length - 4}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Project Info
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Title
                        Text(
                          _project.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        // Project Description and Date
                        Text(
                          'Description ${_project.description} - ${DateFormat('MMM d, yyyy').format(_project.createdAt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Progress Indicator
                        Row(
                          children: [
                            // Progress Text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF35383F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_project.completedTasks} / ${_project.totalTasks}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Progress Circle
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                children: [
                                  CircularProgressIndicator(
                                    value: _project.progress / 100,
                                    backgroundColor: Colors.grey[800],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFB5B3C8)),
                                    strokeWidth: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Kanban Board
                SliverFillRemaining(
                  child: _buildKanbanBoard(),
                ),
              ],
            ),
    );
  }

  Widget _buildKanbanBoard() {
    return Container(
      width: double.infinity,
      child: DragAndDropLists(
        children: _buildLists(),
        onItemReorder: _onItemReorder,
        onListReorder: _onListReorder,
        axis: Axis.horizontal,
        listWidth: 300,
        listPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemDivider: const SizedBox(height: 8),
        itemDecorationWhileDragging: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        listInnerDecoration: BoxDecoration(
          color: const Color(0xFF1F222A),
          borderRadius: BorderRadius.circular(8),
        ),
        lastItemTargetHeight: 8,
        addLastItemTargetHeightToTop: true,
        lastListTargetSize: 40,
      ),
    );
  }

  List<DragAndDropList> _buildLists() {
    return _columns.map((column) {
      return DragAndDropList(
        header: _buildColumnHeader(column),
        children: column.boards.map((board) {
          return DragAndDropItem(
            child: _buildBoardCard(board),
          );
        }).toList(),
        contentsWhenEmpty: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No boards',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildColumnHeader(KanbanColumn column) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Column Title with Count
          Row(
            children: [
              Text(
                column.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: column.id == 'to-do'
                      ? Colors.blue
                      : column.id == 'in-progress'
                          ? Colors.orange
                          : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${column.boards.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Add Board Button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              // Show add board dialog
              _showAddBoardDialog(column);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(Board board) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF35383F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board Title and Due Date
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  board.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due date: ${board.deadline != null ? DateFormat('MMM d').format(board.deadline!) : 'No deadline'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Task Preview (if any)
          if (board.tasks.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: board.tasks.first.color ?? Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

          // Board Footer (Assignees and Comments)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Assignees
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0;
                          i < board.assignedTo.length.clamp(0, 4);
                          i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              '👤',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Comments Count
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${board.commentCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      // Get the board that was moved
      final movedBoard = _columns[oldListIndex].boards[oldItemIndex];

      // Remove the board from its old position
      _columns[oldListIndex].boards.removeAt(oldItemIndex);

      // Add the board to its new position
      _columns[newListIndex].boards.insert(newItemIndex, movedBoard);

      // Update the board status based on the new column
      _updateBoardStatus(movedBoard, _columns[newListIndex].id);
    });
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      // Get the column that was moved
      final movedColumn = _columns[oldListIndex];

      // Remove the column from its old position
      _columns.removeAt(oldListIndex);

      // Add the column to its new position
      _columns.insert(newListIndex, movedColumn);
    });
  }

  void _updateBoardStatus(Board board, String columnId) {
    // Update the status of all tasks in the board based on the new column
    String newStatus;

    switch (columnId) {
      case 'to-do':
        newStatus = 'To Do';
        break;
      case 'in-progress':
        newStatus = 'In Progress';
        break;
      case 'done':
        newStatus = 'Done';
        break;
      default:
        newStatus = 'To Do';
    }

    // Update the board on the server (in a real app)
    // _boardService.updateBoard(board.id, {'status': newStatus});
  }

  void _showAddBoardDialog(KanbanColumn column) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Add Board to ${column.title}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Board Title',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addBoard(column, titleController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addBoard(KanbanColumn column, String title) {
    // Create a new board
    final newBoard = Board(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      title: title,
      deadline: DateTime.now().add(const Duration(days: 7)),
      assignedTo: [],
      tasks: [],
      commentCount: 0,
    );

    setState(() {
      // Add the board to the column
      column.boards.add(newBoard);
    });

    // In a real app, you would save the board to the server
    // _boardService.createBoard(widget.projectId, {
    //   'title': title,
    //   'status': column.id == 'to-do' ? 'To Do' : column.id == 'in-progress' ? 'In Progress' : 'Done',
    // });
  }
}
