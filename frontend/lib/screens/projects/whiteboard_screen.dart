import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/whiteboard_provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import '../../config/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/whiteboard_model.dart';
import '../../services/project_service.dart';

class WhiteboardScreen extends StatefulWidget {
  final String projectId;

  const WhiteboardScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  bool _isLoading = true;
  late Project _project;
  final _projectService = ProjectService();

  // Matrix for transformations
  Matrix4 _matrix = Matrix4.identity();

  // For double tap to reset
  final GlobalKey _canvasKey = GlobalKey();

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

      setState(() {
        _project = project;
        _isLoading = false;
      });

      // Load whiteboard data
      final whiteboardProvider =
          Provider.of<WhiteboardProvider>(context, listen: false);
      await whiteboardProvider.loadWhiteboard(widget.projectId);
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
          : Consumer<WhiteboardProvider>(
              builder: (context, whiteboardProvider, _) {
                if (whiteboardProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (whiteboardProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${whiteboardProvider.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (whiteboardProvider.whiteboard == null) {
                  return const Center(
                    child: Text(
                      'No whiteboard data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      backgroundColor: const Color(
                          0xFFB5B3C8), // Purple/lavender color from the design
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            // Background color
                            Container(
                              color: const Color(0xFFB5B3C8),
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
                                    for (int i = 0; i < 4; i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
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

                    // Whiteboard Canvas
                    SliverFillRemaining(
                      child: _buildWhiteboardCanvas(whiteboardProvider),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddBoardDialog(context);
        },
      ),
    );
  }

  Widget _buildWhiteboardCanvas(WhiteboardProvider whiteboardProvider) {
    final whiteboard = whiteboardProvider.whiteboard!;

    return GestureDetector(
      onDoubleTap: _resetTransformation,
      child: Container(
        key: _canvasKey,
        color: const Color(0xFF1F222A), // Dark background for the canvas
        child: MatrixGestureDetector(
          onMatrixUpdate: (Matrix4 matrix, Matrix4 translationDeltaMatrix,
              Matrix4 scaleDeltaMatrix, Matrix4 rotationDeltaMatrix) {
            setState(() {
              _matrix = matrix;
            });

            // Update viewport in provider
            final scale = _matrix.getMaxScaleOnAxis();
            final translation = _matrix.getTranslation();
            whiteboardProvider.updateViewport(
              Offset(translation.x, translation.y),
              scale,
            );
          },
          child: Transform(
            transform: _matrix,
            child: Stack(
              children: [
                // Grid background (optional)
                _buildGrid(),

                // Boards
                ...whiteboard.boards
                    .map((board) => _buildBoard(board, whiteboardProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(
        width: 3000, // Large canvas size
        height: 3000,
      ),
    );
  }

  Widget _buildBoard(
      WhiteboardBoard board, WhiteboardProvider whiteboardProvider) {
    return Positioned(
      left: board.position.dx,
      top: board.position.dy,
      child: GestureDetector(
        onTap: () {
          whiteboardProvider.selectItem(board);
        },
        child: Draggable(
          feedback:
              _buildBoardCard(board, whiteboardProvider, isDragging: true),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildBoardCard(board, whiteboardProvider),
          ),
          onDragEnd: (details) {
            // Calculate position in the canvas
            final RenderBox renderBox =
                _canvasKey.currentContext!.findRenderObject() as RenderBox;
            final position = renderBox.globalToLocal(details.offset);

            // Update board position
            whiteboardProvider.updateBoardPosition(board.id, position);
          },
          child: _buildBoardCard(board, whiteboardProvider),
        ),
      ),
    );
  }

  Widget _buildBoardCard(
      WhiteboardBoard board, WhiteboardProvider whiteboardProvider,
      {bool isDragging = false}) {
    return Container(
      width: board.size.width,
      decoration: BoxDecoration(
        color: const Color(0xFF35383F),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF35383F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  board.board.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.add, color: Colors.white, size: 20),
                      onPressed: () {
                        _showAddTaskDialog(context, board.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        _showBoardOptionsMenu(context, board.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Due Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Due date: ${board.board.deadline != null ? DateFormat('MMM d').format(board.board.deadline!) : 'No deadline'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),

          // Tasks Container
          Container(
            height: 300, // Fixed height for tasks
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                ...board.tasks.map(
                    (task) => _buildTask(task, board.id, whiteboardProvider)),
              ],
            ),
          ),

          // Board Footer
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
                          i < board.board.assignedTo.length.clamp(0, 4);
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
                      '${board.board.commentCount}',
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

  Widget _buildTask(WhiteboardTask task, String boardId,
      WhiteboardProvider whiteboardProvider) {
    return Positioned(
      left: task.position.dx,
      top: task.position.dy,
      child: GestureDetector(
        onTap: () {
          whiteboardProvider.selectItem(task);
        },
        child: Draggable(
          feedback: _buildTaskCard(task, isDragging: true),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildTaskCard(task),
          ),
          onDragEnd: (details) {
            // Calculate position within the board
            final position = Offset(
              details.offset.dx - task.position.dx,
              details.offset.dy - task.position.dy,
            );

            // Update task position
            whiteboardProvider.updateTaskPosition(boardId, task.id, position);
          },
          child: _buildTaskCard(task),
        ),
      ),
    );
  }

  Widget _buildTaskCard(WhiteboardTask task, {bool isDragging = false}) {
    return Container(
      width: task.size.width,
      height: task.size.height,
      decoration: BoxDecoration(
        color: task.task.color ??
            const Color(0xFFB5B35C), // Yellowish-green color from the design
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.task.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (task.task.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task.task.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  void _resetTransformation() {
    setState(() {
      _matrix = Matrix4.identity();
    });
  }

  void _showAddBoardDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Add Board', style: const TextStyle(color: Colors.white)),
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
                final whiteboardProvider =
                    Provider.of<WhiteboardProvider>(context, listen: false);

                // Calculate center position
                final size = MediaQuery.of(context).size;
                final position = Offset(
                  size.width / 2 - 150, // Half of board width
                  size.height / 2 - 200, // Half of board height
                );

                whiteboardProvider.addBoard(titleController.text, position);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, String boardId) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Add Task', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Task Title',
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
                final whiteboardProvider =
                    Provider.of<WhiteboardProvider>(context, listen: false);

                // Default position within the board
                const position = Offset(10, 60);

                whiteboardProvider.addTask(
                    boardId, titleController.text, position);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showBoardOptionsMenu(BuildContext context, String boardId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title:
                const Text('Edit Board', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Show edit board dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Board',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteBoardConfirmation(context, boardId);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteBoardConfirmation(BuildContext context, String boardId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title:
            Text('Delete Board', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this board? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final whiteboardProvider =
                  Provider.of<WhiteboardProvider>(context, listen: false);
              whiteboardProvider.deleteBoard(boardId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
