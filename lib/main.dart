
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo List App',
      home: HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _deskController = TextEditingController();

  final CollectionReference _productss =
      FirebaseFirestore.instance.collection('products');

  //menambah atau update jika tdk ada field yang kosong
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _taskController.text = documentSnapshot['task'];
      _deskController.text = documentSnapshot['desk']; 
      
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(top: 20, left: 20,right: 20,
              // kode agar keyboard tdk menutupi textfield
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'Aktivitas'),
              ),

              TextField(
                controller: _deskController,
                decoration: const InputDecoration(labelText: 'Keterangan'),
              ),

            
              const SizedBox(
                height: 20,
              ),

              ElevatedButton(
                child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    
                    final String task = _taskController.text;
                    final String desk = _deskController.text;
                    if (task != null && desk != null) {
                      if (action == 'create') {
                        //menambah list ke firestore
                        await _productss.add({"task": task, "desk": desk});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _productss
                            .doc(documentSnapshot!.id)
                            .update({"task": task, "desk": desk});
                      }

                      //mengosongkan text filed task dan desk
                      _taskController.text = '';
                      _deskController.text = '';

                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 25, 173, 231),
                  ),
              )
            ],
          ),
        );
      },
    );
  }

  // Hapus list berdasarkan id
  Future<void> _deleteProduct(String productId) async {
    await _productss.doc(productId).delete();

    //menampilkan toast/ snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('List berhasil dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List App'),
        backgroundColor: Color.fromARGB(255, 25, 173, 231),
      ),
      // menampilkan list
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];

                return Card(
                  margin: const EdgeInsets.only(top: 7, left: 10,right: 10,bottom: 4),
                  child: 
                  ListTile(
                    title: Text(documentSnapshot['task'], style: TextStyle(color: Colors.blueGrey, fontSize: 20, ),),
                    subtitle: Text(documentSnapshot['desk']),
                    
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // icon untuk edit list
                          
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _createOrUpdate(documentSnapshot)
                          ),
                          // icon untuk hapus list
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteProduct(documentSnapshot.id)
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),

      // Menambahakan list baru
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 25, 173, 231),
      ),
    );
  }
}