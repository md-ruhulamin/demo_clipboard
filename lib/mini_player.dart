import 'package:clipboard/file_player.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class MiniPlayer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final ConcatenatingAudioSource playlist;
  const MiniPlayer({
    super.key,
    required this.audioPlayer,
    required this.playlist,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        widget.audioPlayer.positionStream,
        widget.audioPlayer.bufferedPositionStream,
        widget.audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.audioPlayer.setLoopMode(LoopMode.all);
    await widget.audioPlayer.setAudioSource(widget.playlist);
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = widget.audioPlayer.sequenceState?.currentSource?.tag;

    if (mediaItem == null) return const SizedBox();

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Row(
            children: [
          //     /// Thumbnail
          //  ClipRRect(
          //       borderRadius: BorderRadius.circular(8),
          //       child: Image.network(
          //         mediaItem.artUri.toString(),
          //         height: 60,
          //         width: 60,
          //         fit: BoxFit.cover,
          //       ),
          //     ),
     Icon(Icons.audiotrack,size: 60,),
              const SizedBox(width: 5),

              /// Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mediaItem.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<PositionData>(
                      stream: _positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;

                        if (positionData == null) {
                          return const LinearProgressIndicator();
                        }

                        return Column(
                          children: [
                            Slider(
                              activeColor: Colors.deepPurple,
                              inactiveColor: Colors.grey[300],
                              min: 0.0,
                              max:
                                  positionData.duration.inMilliseconds
                                      .toDouble(),
                              value:
                                  positionData.position.inMilliseconds
                                      .clamp(
                                        0,
                                        positionData.duration.inMilliseconds,
                                      )
                                      .toDouble(),
                              onChanged: (value) {
                                widget.audioPlayer.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDurationHHMMSS(positionData.position),
                                ),
                                Row(
                                  children: [
                                    /// Rewind 10 seconds
                                    IconButton(
                                      icon: const Icon(Icons.replay_10),
                                      onPressed: () async {
                                        final currentPosition =
                                            await widget.audioPlayer.position;
                                        final newPosition =
                                            currentPosition -
                                            const Duration(seconds: 10);
                                        widget.audioPlayer.seek(
                                          newPosition >= Duration.zero
                                              ? newPosition
                                              : Duration.zero,
                                        );
                                      },
                                    ),

                                    /// Play / Pause Button
                                    StreamBuilder<PlayerState>(
                                      stream:
                                          widget.audioPlayer.playerStateStream,
                                      builder: (context, snapshot) {
                                        final playerState = snapshot.data;
                                        final playing =
                                            playerState?.playing ?? false;

                                        if (playing) {
                                          return IconButton(
                                            icon: const Icon(Icons.pause),
                                            onPressed: widget.audioPlayer.pause,
                                          );
                                        } else {
                                          return IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: widget.audioPlayer.play,
                                          );
                                        }
                                      },
                                    ),

                                    /// Forward 10 seconds
                                    IconButton(
                                      icon: const Icon(Icons.forward_10),
                                      onPressed: () async {
                                        final currentPosition =
                                            await widget.audioPlayer.position;
                                        final duration =
                                            await widget.audioPlayer.duration ??
                                            Duration.zero;
                                        final newPosition =
                                            currentPosition +
                                            const Duration(seconds: 10);
                                        widget.audioPlayer.seek(
                                          newPosition <= duration
                                              ? newPosition
                                              : duration,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  formatDurationHHMMSS(positionData.duration),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatDurationHHMMSS(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }
}
