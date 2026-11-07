import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id')) {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );

    // Attempt anonymous sign-in if enabled in Supabase
    try {
      final authResponse =
          await Supabase.instance.client.auth.signInAnonymously();
      debugPrint('Signed in anonymously as user: ${authResponse.user?.id}');
    } catch (e) {
      debugPrint('Anonymous sign-in skipped or unavailable: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WaitingRoomScreen(),
    );
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitClient() {
    final name = _controller.text;
    if (name.trim().isNotEmpty) {
      context.read<QueueProvider>().addClient(name);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Field and Add Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submitClient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitClient,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Realtime Queue List
            Expanded(
              child: Consumer<QueueProvider>(
                builder: (context, provider, _) {
                  if (provider.clients.isEmpty) {
                    return const Center(
                      child: Text('No one in queue yet...'),
                    );
                  }
                  return ListView.builder(
                    itemCount: provider.clients.length,
                    itemBuilder: (context, index) {
                      final client = provider.clients[index];
                      final lat = client['lat'];
                      final lng = client['lng'];
                      final String locationText;
                      if (lat == null || lng == null) {
                        locationText = '📍 Location not captured';
                      } else {
                        final latNum = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
                        final lngNum = (lng is num) ? lng.toDouble() : double.tryParse(lng.toString());
                        if (latNum != null && lngNum != null) {
                          locationText = '📍 ${latNum.toStringAsFixed(4)}, ${lngNum.toStringAsFixed(4)}';
                        } else {
                          locationText = '📍 Location not captured';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(client['name']?.toString() ?? ''),
                          subtitle: Text(
                            locationText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              context
                                  .read<QueueProvider>()
                                  .removeClient(client['id']?.toString() ?? '');
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Next Client Button
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<QueueProvider>().nextClient();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
