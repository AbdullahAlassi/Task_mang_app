import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/board_model.dart';
import '../../../services/board_service.dart';

class CreateBoardScreen extends StatefulWidget {
  final String projectId;
  final String? boardId; // If provided, we're editing an existing board

  const CreateBoardScreen({
    Key? key,
    required this.projectId,
    this.boardId,
  }) : super(key: key);

  @override
  State<CreateBoardScreen> createState() => _CreateBoardScreenState();
}

class _CreateBoardScreenState extends State<CreateBoardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _boardService = BoardService();

  DateTime? _deadline;
  List<String> _assignedTo = [];
  bool _isLoading = false;
  String _selectedType = 'To-do'; // Default board type
  bool _showCustomTitle = false;

  // Board type options
  final List<String> _boardTypes = [
    'To-do',
    'In Progress',
    'Done',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.boardId != null) {
      _loadBoardDetails();
    } else {
      // For new boards, set title based on default type
      _updateTitleBasedOnType(_selectedType);
    }
  }

  Future<void> _loadBoardDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final board = await _boardService.getBoardDetails(widget.boardId!);
      setState(() {
        _titleController.text = board.title;
        _selectedType = board.type;
        _showCustomTitle = _selectedType == 'Other';
        _deadline = board.deadline;
        _assignedTo = board.assignedTo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load board details: $e')),
        );
      }
    }
  }

  void _updateTitleBasedOnType(String type) {
    if (type != 'Other') {
      _titleController.text = type;
      setState(() {
        _showCustomTitle = false;
      });
    } else {
      _titleController.text = '';
      setState(() {
        _showCustomTitle = true;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.cardColor,
              onSurface: AppColors.textColor,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.cardColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _saveBoard() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final boardData = {
          'title': _titleController.text,
          'type': _selectedType,
          'deadline': _deadline?.toIso8601String(),
          'assignedTo': _assignedTo,
        };

        if (widget.boardId != null) {
          // Update existing board
          await _boardService.updateBoard(widget.boardId!, boardData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Board updated successfully')),
            );
          }
        } else {
          // Create new board
          await _boardService.createBoard(widget.projectId, boardData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Board created successfully')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save board: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(widget.boardId != null ? 'Edit Board' : 'Create Board'),
      ),
      body: _isLoading && widget.boardId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Board Type Selection
                    const Text(
                      'Board Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: AppColors.cardColor,
                          style: const TextStyle(color: AppColors.textColor),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primaryColor),
                          items: _boardTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedType = newValue;
                              });
                              _updateTitleBasedOnType(newValue);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title Field (only shown for "Other" type or when editing)
                    if (_showCustomTitle || widget.boardId != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Board Title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: AppColors.textColor),
                            enabled: _showCustomTitle || widget.boardId != null,
                            decoration: InputDecoration(
                              hintText: 'Enter board title',
                              filled: true,
                              fillColor: AppColors.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (_showCustomTitle &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter a board title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBoard,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.boardId != null
                                    ? 'Update Board'
                                    : 'Create Board',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
