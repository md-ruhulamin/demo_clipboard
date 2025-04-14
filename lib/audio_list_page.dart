// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously, unused_field
import 'dart:async';
import 'dart:io';
import 'package:clipboard/mini_player.dart';
import 'package:clipboard/premium.dart';
import 'package:clipboard/print_helper.dart';
import 'package:file_picker/file_picker.dart'
    show FilePicker, FilePickerResult, FileType;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:path/path.dart' as p;
class AudioListPage extends StatefulWidget {
  const AudioListPage({super.key});

  @override
  State<AudioListPage> createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage>
    with WidgetsBindingObserver {
  //Variables & Controllers
  late AudioPlayer _audioPlayer;
  int playindex = 0;
  int titleEditIndex = 1;
  bool isEditing = false;

  Duration? _duration;
  Duration? _position;

  final TextEditingController _controller = TextEditingController();

  bool isPlaying = false;
  List<FileSystemEntity> _mp3Files = [];
  Map<String, String> _durations = {};
  bool loadedDurations = false;
  String? _savedDirPath;
  String clipboardContent = '';
  String message = '';
  final Set<int> selectedIndices = {};

  // Lifecycle & Initialization

  final _playlist = ConcatenatingAudioSource(children: [  ], );
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initFolder();
    loadPlaylist();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initFolder() async {
    if (await Permission.storage.request().isGranted) {
      final dir = await getApplicationDocumentsDirectory();
      final mp3Dir = Directory('${dir.path}/democlipboard');

      if (!await mp3Dir.exists()) {
        await mp3Dir.create(recursive: true);
      }
      String _savedDirPath = mp3Dir.path;
    //  _loadMp3Files(_savedDirPath);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Storage permission denied")));
    }
  }

void loadPlaylist() async {
  final audioSources = await convertToAudioSources();
  _playlist.addAll(audioSources);
  PrintHelper.debugPrintWithLocation("PlayList Length  "+ _playlist.length.toString());
  setState(() {
    
  });
}
  Future<void> _pickAndPlayMP3() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.isNotEmpty) {
      List<AudioSource> newSources = [];

      for (var file in result.files) {
        PrintHelper.debugPrintWithLocation(file.path.toString());
        final filePath = file.path;
        if (filePath == null) continue;

        final fileExtension = filePath.split('.').last.toLowerCase();
        if (fileExtension != 'mp3') {
          // Skip non-mp3 file, or show a warning
          continue;
        }

        String fileName = file.name;
        debugPrintWithLocation("Picked File Path: $filePath");
        await copyToAppFolder(filePath, fileName);
        final mediaItem = MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName,
          artist: 'Unknown Artist',
          artUri: Uri.parse(
            'https://images.unsplash.com/photo-1519874179391-3ebc752241dd?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          ),
        );

        final source = AudioSource.uri(Uri.file(filePath), tag: mediaItem);
        newSources.add(source);
      }

      if (newSources.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select only valid MP3 files')),
        );
        return;
      }

      setState(() {
        _playlist.addAll(newSources);
        _mp3Files.addAll(result.paths.map((path) => File(path!)));
        debugPrintWithLocation("Playlist Length: ${_playlist.length}");
        PrintHelper.debugPrintWithLocation(
          "MP3 Files Length: ${_mp3Files.length}",
        );
      });
    } else {
      debugPrintWithLocation('No files selected');
    }
  }



Future<void> copyToAppFolder(String sourcePath, String fileName) async {
  final directory = await getExternalStorageDirectory(); // app-specific
  final newPath = '${directory!.path}/$fileName';

  final sourceFile = File(sourcePath);
  await sourceFile.copy(newPath);
  print("Saved to: $newPath");
}


Future<List<File>> getAllMP3Files() async {
  final directory = await getExternalStorageDirectory(); // App-specific dir
  final files = directory!.listSync();

  return files.whereType<File>().where((file) {
    final ext = p.extension(file.path).toLowerCase();
    return ext == '.mp3';
  }).toList();
}

Future<List<AudioSource>> convertToAudioSources() async {
  final mp3Files = await getAllMP3Files();
  return mp3Files.map((file) {
    final fileName = p.basename(file.path);
    final uri = Uri.file(file.path);
    final mediaItem = MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: fileName,
      artist: "Unknown Artist",
      artUri: Uri.parse(
        'https://via.placeholder.com/150', // You can replace this with actual album art URL
      ),
    );
    return AudioSource.uri(uri, tag: mediaItem);
  }).toList();
}


  File? _pickedFile;

  bool get _isValidMp3Path {
    final path = clipboardContent;
    return path.endsWith('.mp3') && File(path).existsSync();
  }

  void handlePlayPause(int index, String filePath) async {
    if (playindex == index && _audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
      playindex = index;
    }

    setState(() {}); // to trigger UI rebuild
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  //Speech to Text
  final speechToText = SpeechToText.viaToken('Bearer', '<token-here>');
  final config = RecognitionConfig(
    encoding: AudioEncoding.LINEAR16,
    model: RecognitionModel.basic,
    enableAutomaticPunctuation: true,
    sampleRateHertz: 16000,
    languageCode: 'en-US',
  );

  Future<List<int>> _getAudioContent(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$name';
    return File(path).readAsBytesSync().toList();
  }

  void generateTRanscript(String filePath) async {
    final audio = await _getAudioContent(filePath);
    final response = await speechToText.recognize(config, audio);
    print(response);
  }

  void _clearSelection() {
    setState(() => selectedIndices.clear());
  }

  void _shareSelectedItems() {
    if (selectedIndices.isEmpty) return;

    final selectedSources = selectedIndices.map(
      (i) => _playlist.children[i] as UriAudioSource,
    );
    final filePaths =
        selectedSources
            .map((source) => File(source.uri.toFilePath()))
            .where((file) => file.existsSync())
            .map((file) => file.path)
            .toList();

    Share.shareXFiles(
      filePaths.map((path) => XFile(path)).toList(),
      text: 'Check out these MP3s!',
    );
    selectedIndices.clear();
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  String formatDurationHHMMSS(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    PrintHelper.debugPrintWithLocation(
      "MP# Length: " + _mp3Files.length.toString(),
    );
    print(_mp3Files.length);
    return GestureDetector(
      onTap: _clearSelection,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          //   backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          //   preferredSize: Size.fromHeight(60),
          title: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Row(
                    children: [
                      Text(
                        'All iCloud',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),

                  if (selectedIndices.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: _shareSelectedItems,
                    ),
                  IconButton(
                    icon: Icon(Icons.upload),
                    onPressed: () {
                      _pickAndPlayMP3();
                    },
                  ),
                  if (_isValidMp3Path)
                    IconButton(onPressed: () {}, icon: const Icon(Icons.paste)),
                  IconButton(
                    icon: Icon(CupertinoIcons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PremiumUpgradeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _playlist.children.length,
                  itemBuilder: (context, index) {
                    final source = _playlist.children[index] as UriAudioSource;
                    final mediaItem = source.tag as MediaItem;
                    final sourcePath = source.uri.toString();
                    final isSelected = selectedIndices.contains(index);
                    return GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Color(0xFFD7F3FD) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    child: GestureDetector(
                                      onDoubleTap: () {
                                        setState(() {
                                          isEditing = !isEditing;
                                          titleEditIndex =
                                              isEditing ? index : -1;

                                          _controller.text = mediaItem.title
                                              .replaceAll(".mp3", "");
                                        });
                                      },
                                      child:
                                          isEditing && titleEditIndex == index
                                              ? TextField(
                                                controller: _controller,
                                                autofocus: true,
                                                onSubmitted: (data) {
                                                  setState(() {
                                                    isEditing = false;
                                                    titleEditIndex = -1;
                                                  });

                                                  // file.renameSync(
                                                  //     '${_savedDirPath!}/$data.mp3',
                                                  //   );
                                                  //   _loadMp3Files();
                                                },
                                              )
                                              : Text(
                                                mediaItem.title.replaceAll(
                                                  '.mp3',
                                                  '',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 19,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  child:
                                      (playindex == index &&
                                              _audioPlayer.playing)
                                          ? Icon(Icons.audiotrack)
                                          : SizedBox(),
                                ),
                                // SizedBox(
                                //   child: ElevatedButton(
                                //     onPressed: () {
                                //       if (index == playindex) {
                                //         if (_audioPlayer.playing) {
                                //           _audioPlayer.pause();
                                //         } else {
                                //           _audioPlayer.play();
                                //         }
                                //       } else {
                                //         _audioPlayer.setAudioSource(source);
                                //         _audioPlayer.play();
                                //       }

                                //       setState(() {
                                //         playindex = index;
                                //       });
                                //     },
                                //     style: ElevatedButton.styleFrom(
                                //       padding: EdgeInsets.zero,
                                //       backgroundColor: Colors.white,
                                //       foregroundColor: Colors.black,
                                //       elevation: 1,
                                //     ),
                                //     child: Row(
                                //       mainAxisAlignment:
                                //           MainAxisAlignment.center,
                                //       children: [
                                //         (playindex == index &&
                                //                 _audioPlayer.playing)
                                //             ? Icon(Icons.audiotrack)
                                //             : SizedBox(),

                                //         SizedBox(width: 5),
                                //         Text('Play'),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            Text(sourcePath, maxLines: 1),
                          ],
                        ),
                      ),

                      onTap: () {
                        if (index == playindex) {
                          if (_audioPlayer.playing) {
                            //Nothing to do
                          } else {
                            _audioPlayer.play();
                          }
                        } else {
                          _audioPlayer.setAudioSource(source);
                          _audioPlayer.play();
                        }

                        setState(() {
                          playindex = index;
                        });
                      },
                      onLongPress: () => _toggleSelection(index),
                    );
                  },
                ),
              ),
            ),
            MiniPlayer(audioPlayer: _audioPlayer, playlist: _playlist),
          ],
        ),
      ),
    );
  }

  static void debugPrintWithLocation(String message) {
    final frames = Trace.current().frames;
    if (frames.length > 1) {
      final callerFrame = frames[1];
      print(
        '[${callerFrame.uri.pathSegments.last}:${callerFrame.line}]\n $message',
      );
    } else {
      print(message);
    }
  }
}
