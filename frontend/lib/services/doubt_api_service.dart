// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// Models
class DoubtApiModel {
  final String? id;
  final String title;
  final String content;
  final String subject;
  final String author;
  final String authorAvatar;
  final List<String>? imageUrls;
  final List<String>? tags;
  final String? createdAt;
  final List<CommentApiModel>? comments;

  DoubtApiModel({
    this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.author,
    required this.authorAvatar,
    this.imageUrls,
    this.tags,
    this.createdAt,
    this.comments,
  });

  factory DoubtApiModel.fromJson(Map<String, dynamic> json) {
    return DoubtApiModel(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      subject: json['subject'] ?? 'General',
      author: json['author'] ?? 'Anonymous',
      authorAvatar: json['authorAvatar'] ?? 'A',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'],
      comments: (json['comments'] as List?)
          ?.map((c) => CommentApiModel.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'subject': subject,
      'author': author,
      'authorAvatar': authorAvatar,
      'imageUrls': imageUrls,
      'tags': tags,
    };
  }

  bool get hasImage => (imageUrls?.isNotEmpty) ?? false;
}

class CommentApiModel {
  final String? id;
  final String author;
  final String authorAvatar;
  final String content;
  final List<String>? imageUrls;
  final String? createdAt;
  final List<ReplyApiModel>? replies;

  CommentApiModel({
    this.id,
    required this.author,
    required this.authorAvatar,
    required this.content,
    this.imageUrls,
    this.createdAt,
    this.replies,
  });

  factory CommentApiModel.fromJson(Map<String, dynamic> json) {
    return CommentApiModel(
      id: json['_id'] ?? json['id'],
      author: json['author'] ?? 'Anonymous',
      authorAvatar: json['authorAvatar'] ?? 'A',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: json['createdAt'],
      replies: (json['replies'] as List?)
          ?.map((r) => ReplyApiModel.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls ?? [],
    };
  }
}

class ReplyApiModel {
  final String? id;
  final String author;
  final String authorAvatar;
  final String content;
  final String? createdAt;

  ReplyApiModel({
    this.id,
    required this.author,
    required this.authorAvatar,
    required this.content,
    this.createdAt,
  });

  factory ReplyApiModel.fromJson(Map<String, dynamic> json) {
    return ReplyApiModel(
      id: json['_id'] ?? json['id'],
      author: json['author'] ?? 'Anonymous',
      authorAvatar: json['authorAvatar'] ?? 'A',
      content: json['content'] ?? '',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'author': author, 'authorAvatar': authorAvatar, 'content': content};
  }
}

// API Service
class DoubtApiService {
  static const String baseUrl = 'http://localhost:8000/doubts';
  static const Duration timeout = Duration(seconds: 30);

  // ============================================================================
  // DOUBT OPERATIONS
  // ============================================================================

  /// Create a new doubt
  static Future<DoubtApiModel?> createDoubt({
    required String title,
    required String content,
    required String subject,
    required String author,
    required String authorAvatar,
    List<String>? imageUrls,
    List<String>? tags,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'content': content,
              'subject': subject,
              'author': author,
              'authorAvatar': authorAvatar,
              'imageUrls': imageUrls ?? [],
              'tags': tags ?? [],
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return DoubtApiModel.fromJson(json['data']);
        }
      }
      print('Failed to create doubt: ${response.body}');
      return null;
    } catch (e) {
      print('Error creating doubt: $e');
      return null;
    }
  }

  /// Get all doubts with pagination
  static Future<List<DoubtApiModel>?> getAllDoubts({
    int skip = 0,
    int limit = 20,
    String? subject,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/all').replace(
        queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
          if (subject != null) 'subject': subject,
        },
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return (json['data'] as List)
              .map((d) => DoubtApiModel.fromJson(d))
              .toList();
        }
      }
      print('Failed to get doubts: ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching doubts: $e');
      return null;
    }
  }

  /// Get specific doubt by ID
  static Future<DoubtApiModel?> getDoubtById(String doubtId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/$doubtId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return DoubtApiModel.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching doubt: $e');
      return null;
    }
  }

  /// Update a doubt
  static Future<bool> updateDoubt(
    String doubtId, {
    String? title,
    String? content,
    String? subject,
    List<String>? imageUrls,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (subject != null) body['subject'] = subject;
      if (imageUrls != null) body['imageUrls'] = imageUrls;
      if (tags != null) body['tags'] = tags;

      final response = await http
          .put(
            Uri.parse('$baseUrl/$doubtId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating doubt: $e');
      return false;
    }
  }

  /// Delete a doubt
  static Future<bool> deleteDoubt(String doubtId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/$doubtId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting doubt: $e');
      return false;
    }
  }

  // ============================================================================
  // COMMENT OPERATIONS
  // ============================================================================

  /// Add comment/answer to doubt
  static Future<CommentApiModel?> addComment(
    String doubtId, {
    required String author,
    required String authorAvatar,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$doubtId/comments'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'author': author,
              'authorAvatar': authorAvatar,
              'content': content,
              'imageUrls': imageUrls ?? [],
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return CommentApiModel.fromJson(json['data']);
        }
      }
      print('Failed to add comment: ${response.body}');
      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Update a comment
  static Future<bool> updateComment(
    String doubtId,
    String commentId, {
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (content != null) body['content'] = content;
      if (imageUrls != null) body['imageUrls'] = imageUrls;

      final response = await http
          .put(
            Uri.parse('$baseUrl/$doubtId/comments/$commentId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(String doubtId, String commentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/$doubtId/comments/$commentId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // ============================================================================
  // REPLY OPERATIONS
  // ============================================================================

  /// Add reply to comment
  static Future<ReplyApiModel?> addReply(
    String doubtId,
    String commentId, {
    required String author,
    required String authorAvatar,
    required String content,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$doubtId/comments/$commentId/replies'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'author': author,
              'authorAvatar': authorAvatar,
              'content': content,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return ReplyApiModel.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error adding reply: $e');
      return null;
    }
  }

  /// Delete a reply
  static Future<bool> deleteReply(
    String doubtId,
    String commentId,
    String replyId,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/$doubtId/comments/$commentId/replies/$replyId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting reply: $e');
      return false;
    }
  }

  // ============================================================================
  // FILE UPLOAD OPERATIONS
  // ============================================================================

  /// Upload single image
  static Future<String?> uploadImage(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );

      final response = await request.send().timeout(timeout);

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        if (json['success'] == true && json['filepath'] != null) {
          return json['filepath'];
        }
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images
  static Future<List<String>?> uploadImages(
    List<Uint8List> imageBytesList,
    List<String> filenames,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-images'),
      );

      for (int i = 0; i < imageBytesList.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            imageBytesList[i],
            filename: filenames[i],
          ),
        );
      }

      final response = await request.send().timeout(timeout);

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        if (json['success'] == true && json['filepaths'] != null) {
          return List<String>.from(json['filepaths']);
        }
      }
      return null;
    } catch (e) {
      print('Error uploading images: $e');
      return null;
    }
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Get doubt statistics
  static Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/stats/overview'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching statistics: $e');
      return null;
    }
  }
}
