import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: user == null
          ? const Center(child: Text('Usuario no autenticado'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar perfil'),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                final name = data['name'] ?? data['nombre'] ?? 'Sin nombre';
                final phone = data['phone'] ?? '';
                final email = data['email'] ?? user.email ?? '';
                  final direccion = data['direccion'] ?? '';

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 👤 AVATAR
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.orange,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 📛 NOMBRE
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ✉️ EMAIL
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),

                      ),

                      const SizedBox(height: 6),

                      // 📞 TELÉFONO
                      SelectableText(
                        phone.isEmpty
                            ? 'Teléfono no registrado'
                            : phone,
                        style: TextStyle(
                          color: phone.isEmpty
                              ? Colors.red
                              : Colors.grey,
                        ),
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          selectAll: true,
                        ),
                        showCursor: false,
                      ),
                      
                       // 🏠 DIRECCIÓN
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Dirección'),
                        subtitle: Text(
                          direccion.isEmpty
                              ? 'No registrada'
                              : direccion,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ✏️ EDITAR PERFIL
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar perfil'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🚪 LOGOUT
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
