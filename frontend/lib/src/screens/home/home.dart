import 'package:flutter/material.dart';
import 'package:frontend/src/screens/signIn/SignIn.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String? imageFilename;

  HomeScreen({required this.email, this.imageFilename});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String? _imageFilename;
  final ImagePicker _picker = ImagePicker();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageFilename != null) {
      _loadImage(widget.imageFilename!);
    }
  }

  Future<void> _loadImage(String filename) async {
    try {
      var response =
          await http.get(Uri.parse('http://192.168.1.13:3000/image/$filename'));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$filename');
        await tempFile.writeAsBytes(response.bodyBytes);
        setState(() {
          _image = tempFile;
        });
      } else {
        print('Failed to load image with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _uploadImage(_image!);
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.1.13:3000/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      request.fields['email'] = widget.email;

      var response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('Response body: $responseBody');
        final data = json.decode(responseBody);
        final uploadedFilename = data['filename'] as String?;
        if (uploadedFilename != null) {
          setState(() {
            _imageFilename = uploadedFilename;
          });
          _loadImage(_imageFilename!);
          print('Image uploaded successfully');
        } else {
          print('Filename not found in response');
        }
      } else {
        print('Image upload failed with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          actions: <Widget>[
            IconButton(
              icon: Icon(_isDarkMode ? Icons.brightness_7 : Icons.brightness_2),
              onPressed: _toggleTheme,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(),
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? Icon(Icons.camera_alt,
                                  size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.email,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
        body: Center(
          child: Text('Welcome to the Home Screen!'),
        ),
      ),
    );
  }
}
