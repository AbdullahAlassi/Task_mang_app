import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../services/project_service.dart';
import '../../services/board_service.dart';
import '../../services/task_service.dart';
import '../../widgets/reorderable_row.dart';
import '../tasks/create_task_screen.dart';
import '../boards/create_board_screen.dart';
import '../boards/board_detail_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../projects/create_project_screen.dart';

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
  final ProjectService _projectService = ProjectService();
  final BoardService _boardService = BoardService();
  final TaskService _taskService = TaskService();
  Project? _project;
  List<Board> _boards = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkIfManager() async {
    final currentUserId = await _projectService.getCurrentUserId();
    setState(() {
      _isManager = _project?.managerId == currentUserId;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Loading Project Data ===');
      final project = await _projectService.getProjectDetails(widget.projectId);
      print('Project ID: ${project.id}');
      print('Project loaded: ${project.title}');
      print('Project Manager ID: ${project.managerId}');

      print('=== Fetching Boards for Project Debug ===');
      final boards = await _boardService.getBoardsForProject(widget.projectId);

      final updatedBoards = await Future.wait(boards.map((board) async {
        final tasks = await _taskService.getTasksForBoard(board.id);
        return board.copyWith(tasks: tasks);
      }));

      final currentUserId = await _projectService
          .getCurrentUserId(); // Updated to use the correct method
      print('Current User ID: $currentUserId');

      final isManagerNow =
          currentUserId != null && project.managerId == currentUserId;
      print('Is Manager: $isManagerNow');

      setState(() {
        _project = project;
        _boards = updatedBoards;
        _isManager = isManagerNow;
        _isLoading = false;
      });

      print('=== Project Data Loading Complete ===');
    } catch (e) {
      print('Error loading data: $e');
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
    if (_isLoading || _project == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF181A20),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBoardScreen(
                projectId: widget.projectId,
              ),
            ),
          ).then((value) {
            if (value == true) {
              _loadData();
            }
          });
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: _project!.getBannerColor(),
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Background color
                  Container(
                    color: _project!.getBannerColor(),
                  ),

                  // More options button
                  Positioned(
                    top: 40,
                    right: 16,
                    child: _isLoading
                        ? const SizedBox() // Don't show menu until loading finishes
                        : Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz,
                                  color: Colors.black),
                              onSelected: (value) {
                                if (value == 'NoPermission') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Only the project manager can perform this action.'),
                                    ),
                                  );
                                  return;
                                }

                                switch (value) {
                                  case 'Edit Project':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateProjectScreen(
                                          project: _project,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        _loadData();
                                      }
                                    });
                                    break;

                                  case 'Delete Project':
                                    _confirmDeleteProject();
                                    break;
                                }
                              },
                              itemBuilder: (context) => _isManager
                                  ? [
                                      const PopupMenuItem(
                                        value: 'Edit Project',
                                        child: Text('Edit Project'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'Delete Project',
                                        child: Text(
                                          'Delete Project',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ]
                                  : [
                                      const PopupMenuItem(
                                        value: 'NoPermission',
                                        child: Text(
                                          'Only manager can edit or delete',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ],
                            ),
                          ),
                  ),

                  // Team members
                  Positioned(
                    bottom: 15,
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
                              i < _project!.memberIds.length.clamp(0, 4);
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  _project!.memberIds[i]
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
                          if (_project!.memberIds.length > 4)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '+${_project!.memberIds.length - 4}',
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
              color: const Color(0xFF181A20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Title
                  Text(
                    _project!.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Project Description and Date
                  Text(
                    'Description ${_project!.description} - ${DateFormat('MMM d, yyyy').format(_project!.createdAt)}',
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
                          '${_boards.fold(0, (sum, board) => sum + board.tasks.where((task) => task.status == 'Done').length)} / ${_boards.fold(0, (sum, board) => sum + board.tasks.length)}',
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
                              value: _boards.fold(
                                          0,
                                          (sum, board) =>
                                              sum + board.tasks.length) >
                                      0
                                  ? _boards.fold(
                                          0,
                                          (sum, board) =>
                                              sum +
                                              board.tasks
                                                  .where((task) =>
                                                      task.status == 'Done')
                                                  .length) /
                                      _boards.fold(
                                          0,
                                          (sum, board) =>
                                              sum + board.tasks.length)
                                  : 0,
                              backgroundColor: Colors.grey[800],
                              valueColor: const AlwaysStoppedAnimation<Color>(
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
    if (_boards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_customize_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No boards yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a board to get started',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateBoardScreen(
                      projectId: widget.projectId,
                    ),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadData();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Board'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: ReorderableRow(
        scrollController: _scrollController,
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            // No need to adjust newIndex as we're handling the reordering directly
            final board = _boards.removeAt(oldIndex);
            _boards.insert(newIndex, board);
          });

          try {
            // Update positions in the backend
            await _boardService.updateBoardPositions(
              widget.projectId,
              _boards.map((board) => board.id).toList(),
            );
          } catch (e) {
            // If the update fails, reload the data to restore the original order
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update board order: $e')),
              );
            }
          }
        },
        children: _boards.map((board) {
          return Container(
            key: ValueKey(board.id),
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F222A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 100,
                maxHeight: 700,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBoardHeader(board),
                  Expanded(
                    child: DragTarget<Task>(
                      onWillAccept: (task) => true,
                      onAccept: (task) async {
                        print('\n=== Task Drag Debug ===');
                        print('Task ID: ${task.id}');
                        print('Task Title: ${task.title}');
                        print('Target Board ID: ${board.id}');
                        print('Target Board Title: ${board.title}');

                        // Find the old board
                        final oldBoard = _boards.firstWhere(
                          (b) => b.tasks.any((t) => t.id == task.id),
                        );
                        print('Source Board ID: ${oldBoard.id}');
                        print('Source Board Title: ${oldBoard.title}');

                        setState(() {
                          // Remove task from old board
                          oldBoard.tasks.removeWhere((t) => t.id == task.id);
                          // Add task to new board
                          board.tasks.add(task);
                        });

                        try {
                          print('\n1. Updating task in backend...');
                          // Update task's board and status in backend
                          await _taskService.updateTask(
                            task.id,
                            {
                              'board': board.id,
                              'status': board.title,
                            },
                          );
                          print('Task updated successfully');

                          print('\n2. Updating project status...');
                          // Update project status
                          await _projectService
                              .updateProjectStatus(board.projectId);
                          print('Project status updated successfully');

                          print('\n3. Refreshing data...');
                          _loadData(); // Refresh data
                          print('Data refresh completed');
                        } catch (e, stackTrace) {
                          print('\nError during task drag:');
                          print('Error message: $e');
                          print('Stack trace:');
                          print(stackTrace);

                          _loadData(); // Refresh to ensure UI is in sync
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to update task: $e')),
                            );
                          }
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: board.tasks.length,
                          itemBuilder: (context, index) {
                            return Draggable<Task>(
                              data: board.tasks[index],
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 280,
                                  child:
                                      _buildTaskCard(board.tasks[index], board),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child:
                                    _buildTaskCard(board.tasks[index], board),
                              ),
                              child: _buildTaskCard(board.tasks[index], board),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (board.tasks.isEmpty)
                    DragTarget<Task>(
                      onWillAccept: (task) => true,
                      onAccept: (task) async {
                        // Find the old board
                        final oldBoard = _boards.firstWhere(
                          (b) => b.tasks.any((t) => t.id == task.id),
                        );

                        setState(() {
                          // Remove task from old board
                          oldBoard.tasks.removeWhere((t) => t.id == task.id);
                          // Add task to new board
                          board.tasks.add(task);
                        });

                        try {
                          // Update task's board and status in backend
                          await _taskService.updateTask(
                            task.id,
                            {
                              'board': board.id,
                              'status': board.title,
                            },
                          );
                          // Update project status
                          await _projectService
                              .updateProjectStatus(board.projectId);
                          _loadData(); // Refresh data
                        } catch (e) {
                          print('Error updating task: $e');
                          _loadData(); // Refresh to ensure UI is in sync
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to update task: $e')),
                            );
                          }
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No tasks',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    _showAddTaskDialog(board);
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Task'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoardHeader(Board board) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF35383F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Board Title and Task Count
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoardDetailScreen(board: board),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadData();
                  }
                });
              },
              child: Row(
                children: [
                  // Board Type Indicator
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: board.getBoardTypeColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Board Title
                  Expanded(
                    child: Text(
                      board.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Task Count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${board.tasks.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Board Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF35383F),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editBoard(board);
                  break;
                case 'delete':
                  _deleteBoard(board);
                  break;
                case 'add_task':
                  _showAddTaskDialog(board);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_task',
                child: Text('Add Task', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'edit',
                child:
                    Text('Edit Board', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child:
                    Text('Delete Board', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, Board board) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF35383F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(taskId: task.id),
            ),
          ).then((value) {
            if (value == true) {
              _loadData();
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color banner
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: task.color ?? AppColors.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Title and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white, size: 18),
                        color: const Color(0xFF35383F),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editTask(task, board);
                              break;
                            case 'delete':
                              _deleteTask(task, board);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit',
                                style: TextStyle(color: Colors.white)),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Task Description
                  if (task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Task Footer (Due Date, Assignees)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Due Date
                      if (task.deadline != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d').format(task.deadline!),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Assignees
                      if (task.assignedTo.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${task.assignedTo.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(Board board) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          projectId: widget.projectId,
          boardId: board.id,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _editBoard(Board board) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBoardScreen(
          projectId: widget.projectId,
          boardId: board.id,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _deleteBoard(Board board) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Delete Board',
            style: TextStyle(color: AppColors.textColor)),
        content: Text(
          'Are you sure you want to delete "${board.title}"? This will also delete all tasks in this board. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _boardService.deleteBoard(board.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Board deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete board: $e')),
          );
        }
      }
    }
  }

  void _editTask(Task task, Board board) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          projectId: widget.projectId,
          boardId: board.id,
          taskId: task.id,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _deleteTask(Task task, Board board) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Delete Task',
            style: TextStyle(color: AppColors.textColor)),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _taskService.deleteTask(task.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: $e')),
          );
        }
      }
    }
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex,
      int newListIndex) async {
    setState(() {
      // Get the task that was moved
      final movedTask = _boards[oldListIndex].tasks[oldItemIndex];

      // Remove the task from its old position
      _boards[oldListIndex].tasks.removeAt(oldItemIndex);

      // Add the task to its new position
      _boards[newListIndex].tasks.insert(newItemIndex, movedTask);
    });

    try {
      final newBoard = _boards[newListIndex];

      // Map board type to task status
      String newStatus;
      switch (newBoard.type) {
        case 'To-do':
          newStatus = 'To Do';
          break;
        case 'In Progress':
          newStatus = 'In Progress';
          break;
        case 'Done':
          newStatus = 'Done';
          break;
        default:
          newStatus = 'To Do';
      }

      // Update both the board ID and status of the task
      await _taskService.updateTask(
        _boards[newListIndex].tasks[newItemIndex].id,
        {
          'board': newBoard.id,
          'status': newStatus,
        },
      );

      // Reload data to ensure UI is in sync with server
      _loadData();
    } catch (e) {
      print('Error updating task: $e');
      // Reload data to ensure UI is in sync with server
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  void _confirmDeleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Delete Project',
            style: TextStyle(color: AppColors.textColor)),
        content: Text(
          'Are you sure you want to delete "${_project?.title}"? This will also delete all boards and tasks in this project. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _projectService.deleteProject(_project!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
          Navigator.pop(context); // Return to projects list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete project: $e')),
          );
        }
      }
    }
  }
}
