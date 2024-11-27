import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final CollectionReference _notesCollection =
      FirebaseFirestore.instance.collection('notes');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _addOrEditNote({String? docId}) async {
    if (docId != null) {
      final doc = await _notesCollection.doc(docId).get();
      if (doc.exists) {
        _titleController.text = doc['title'] ?? '';
        _contentController.text = doc['content'] ?? '';
        _selectedDate = (doc['timestamp'] as Timestamp).toDate();
      }
    } else {
      _titleController.clear();
      _contentController.clear();
      _selectedDate = DateTime.now();
    }

    // Show the dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _selectedDate != null
                      ? 'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate!)}'
                      : 'Select Date',
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            _selectedDate ?? DateTime.now()),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty ||
                  _contentController.text.isEmpty ||
                  _selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (docId == null) {
                // Add a new note
                await _notesCollection.add({
                  'title': _titleController.text,
                  'content': _contentController.text,
                  'timestamp': Timestamp.fromDate(_selectedDate!),
                });
              } else {
                // Update an existing note
                await _notesCollection.doc(docId).update({
                  'title': _titleController.text,
                  'content': _contentController.text,
                  'timestamp': Timestamp.fromDate(_selectedDate!),
                });
              }

              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(String docId) async {
    await _notesCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: const Color.fromARGB(255, 107, 70, 176),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _notesCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notes available.'));
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final timestamp = note['timestamp'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                  : 'Unknown Date';

              return Card(
                child: ListTile(
                  title: Text(note['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['content'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $date',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEditNote(docId: note.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.blue),
                        onPressed: () {
                          Share.share(
                              'Title: ${note['title']}\nContent: ${note['content']}\nDate: $date');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(note.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: const Color.fromARGB(255, 107, 70, 176),
        child: const Icon(Icons.add),
      ),
    );
  }
}
