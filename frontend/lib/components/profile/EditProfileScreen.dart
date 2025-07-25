import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({
    super.key,
    required this.userData,
    this.profileData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _nivelEstudioController;
  late final TextEditingController _generoController;
  late final TextEditingController _estadoCivilController;
  late final TextEditingController _parroquiaController;
  late final TextEditingController _origenIngresosController;
  late final TextEditingController _especializacionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController(text: widget.userData['nombre_completo'] ?? '');
    _telefonoController = TextEditingController(text: widget.userData['telefono'] ?? '');

    if (widget.profileData != null) {
      _nivelEstudioController = TextEditingController(text: widget.profileData!['nivel_estudio'] ?? '');
      _generoController = TextEditingController(text: widget.profileData!['genero'] ?? '');
      _estadoCivilController = TextEditingController(text: widget.profileData!['estado_civil'] ?? '');
      _parroquiaController = TextEditingController(text: widget.profileData!['parroquia'] ?? '');
      _origenIngresosController = TextEditingController(text: widget.profileData!['origen_ingresos'] ?? '');
      _especializacionController = TextEditingController(text: widget.profileData!['especialization'] ?? '');
    } else {
      _nivelEstudioController = TextEditingController();
      _generoController = TextEditingController();
      _estadoCivilController = TextEditingController();
      _parroquiaController = TextEditingController();
      _origenIngresosController = TextEditingController();
      _especializacionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _nivelEstudioController.dispose();
    _generoController.dispose();
    _estadoCivilController.dispose();
    _parroquiaController.dispose();
    _origenIngresosController.dispose();
    _especializacionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();

      final data = {
        'nombre_completo': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
      };

      // Agregar campos específicos según el rol
      if (widget.userData['rol'] == 'estudiante') {
        data.addAll({
          'nivel_estudio': _nivelEstudioController.text.trim(),
          'genero': _generoController.text.trim(),
          'estado_civil': _estadoCivilController.text.trim(),
          'parroquia': _parroquiaController.text.trim(),
          'origen_ingresos': _origenIngresosController.text.trim(),
        });
      } else if (widget.userData['rol'] == 'docente') {
        data.addAll({
          'especialization': _especializacionController.text.trim(),
        });
      }

      await apiClient.updateProfile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Básica',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu nombre completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información específica del rol
              if (widget.userData['rol'] == 'estudiante') ..._buildStudentFields(),
              if (widget.userData['rol'] == 'docente') ..._buildTeacherFields(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información Académica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _nivelEstudioController.text.isEmpty ? null : _nivelEstudioController.text,
                decoration: const InputDecoration(
                  labelText: 'Nivel de Estudio',
                  prefixIcon: Icon(Icons.school),
                ),
                items: const [
                  DropdownMenuItem(value: 'A1', child: Text('Principiante A1')),
                  DropdownMenuItem(value: 'A2', child: Text('Principiante A2')),
                  DropdownMenuItem(value: 'B1', child: Text('Intermedio B1')),
                  DropdownMenuItem(value: 'B2', child: Text('Intermedio B2')),
                  DropdownMenuItem(value: 'C1', child: Text('Avanzado C1')),
                  DropdownMenuItem(value: 'C2', child: Text('Avanzado C2')),
                ],
                onChanged: (value) {
                  _nivelEstudioController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _generoController.text.isEmpty ? null : _generoController.text,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  _generoController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estadoCivilController.text.isEmpty ? null : _estadoCivilController.text,
                decoration: const InputDecoration(
                  labelText: 'Estado Civil',
                  prefixIcon: Icon(Icons.favorite),
                ),
                items: const [
                  DropdownMenuItem(value: 'Soltero', child: Text('Soltero/a')),
                  DropdownMenuItem(value: 'Casado', child: Text('Casado/a')),
                  DropdownMenuItem(value: 'Divorciado', child: Text('Divorciado/a')),
                  DropdownMenuItem(value: 'Viudo', child: Text('Viudo/a')),
                  DropdownMenuItem(value: 'Union libre', child: Text('Unión libre')),
                ],
                onChanged: (value) {
                  _estadoCivilController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parroquiaController,
                decoration: const InputDecoration(
                  labelText: 'Parroquia',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _origenIngresosController,
                decoration: const InputDecoration(
                  labelText: 'Origen de Ingresos',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTeacherFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información Profesional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especializacionController,
                decoration: const InputDecoration(
                  labelText: 'Especialización',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}