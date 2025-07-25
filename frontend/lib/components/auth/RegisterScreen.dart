import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../layout/Layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controladores básicos
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controladores de estudiante
  final _nivelEstudioController = TextEditingController();
  final _generoController = TextEditingController();
  final _estadoCivilController = TextEditingController();
  final _parroquiaController = TextEditingController();
  final _origenIngresosController = TextEditingController();

  // Controladores de docente
  final _especializacionController = TextEditingController();

  String _selectedRol = 'estudiante';
  DateTime? _fechaNacimiento;
  DateTime? _fechaContratacion;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nivelEstudioController.dispose();
    _generoController.dispose();
    _estadoCivilController.dispose();
    _parroquiaController.dispose();
    _origenIngresosController.dispose();
    _especializacionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();

      final data = {
        'nombre_completo': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'rol': _selectedRol,
        'password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
      };

      // Agregar campos específicos según el rol
      if (_selectedRol == 'estudiante') {
        data.addAll({
          'nivel_estudio': _nivelEstudioController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0] ?? '',
          'genero': _generoController.text.trim(),
          'estado_civil': _estadoCivilController.text.trim(),
          'parroquia': _parroquiaController.text.trim(),
          'origen_ingresos': _origenIngresosController.text.trim(),
        });
      } else if (_selectedRol == 'docente') {
        data.addAll({
          'especialization': _especializacionController.text.trim(),
          'hire_date': _fechaContratacion?.toIso8601String().split('T')[0] ?? '',
        });
      }

      final result = await apiClient.register(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al layout principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Layout()),
        );
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

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF),
              Colors.white,
              Color(0xFFECFDF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Indicador de progreso
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? const Color(0xFF2563EB)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Contenido del formulario
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    children: [
                      _buildBasicInfoPage(),
                      _buildRoleSelectionPage(),
                      _buildProfileInfoPage(),
                    ],
                  ),
                ),
              ),

              // Botones de navegación
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          child: const Text('Anterior'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _currentPage == 2
                            ? _handleRegister
                            : _nextPage,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(_currentPage == 2 ? 'Crear Cuenta' : 'Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tus datos personales',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: Icon(Icons.person_outline),
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
            controller: _correoController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo electrónico';
              }
              if (!value.contains('@')) {
                return 'Por favor ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _cedulaController,
            decoration: const InputDecoration(
              labelText: 'Cédula',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu cédula';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor confirma tu contraseña';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Usuario',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona tu rol en la institución',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          _buildRoleCard(
            'estudiante',
            'Estudiante',
            'Acceso a cursos, calificaciones y servicios estudiantiles',
            Icons.school,
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildRoleCard(
            'docente',
            'Docente',
            'Gestión de clases, calificaciones y seguimiento académico',
            Icons.person_pin,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String value, String title, String description, IconData icon, Color color) {
    final isSelected = _selectedRol == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRol = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRol == 'estudiante' ? 'Información Académica' : 'Información Profesional',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedRol == 'estudiante'
                ? 'Completa tu perfil estudiantil'
                : 'Completa tu perfil docente',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          if (_selectedRol == 'estudiante') ..._buildStudentFields(),
          if (_selectedRol == 'docente') ..._buildTeacherFields(),
        ],
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      DropdownButtonFormField<String>(
        value: _nivelEstudioController.text.isEmpty ? null : _nivelEstudioController.text,
        decoration: const InputDecoration(
          labelText: 'Nivel de Estudio',
          prefixIcon: Icon(Icons.school_outlined),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona tu nivel de estudio';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 años
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _fechaNacimiento = date;
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Fecha de Nacimiento',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            controller: TextEditingController(
              text: _fechaNacimiento?.toString().split(' ')[0] ?? '',
            ),
            validator: (value) {
              if (_fechaNacimiento == null) {
                return 'Por favor selecciona tu fecha de nacimiento';
              }
              return null;
            },
          ),
        ),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona tu género';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      DropdownButtonFormField<String>(
        value: _estadoCivilController.text.isEmpty ? null : _estadoCivilController.text,
        decoration: const InputDecoration(
          labelText: 'Estado Civil',
          prefixIcon: Icon(Icons.favorite_outline),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona tu estado civil';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _parroquiaController,
        decoration: const InputDecoration(
          labelText: 'Parroquia',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa tu parroquia';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _origenIngresosController,
        decoration: const InputDecoration(
          labelText: 'Origen de Ingresos',
          prefixIcon: Icon(Icons.work_outline),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa tu origen de ingresos';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildTeacherFields() {
    return [
      TextFormField(
        controller: _especializacionController,
        decoration: const InputDecoration(
          labelText: 'Especialización',
          prefixIcon: Icon(Icons.school_outlined),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa tu especialización';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _fechaContratacion = date;
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Fecha de Contratación',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            controller: TextEditingController(
              text: _fechaContratacion?.toString().split(' ')[0] ?? '',
            ),
          ),
        ),
      ),
    ];
  }
}