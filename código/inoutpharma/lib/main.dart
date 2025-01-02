import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await cargarUsuariosDePreferencias();

  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? loggedInUser = prefs.getString('loggedInUser');

  if (isLoggedIn && loggedInUser != null && baseDeDatosUsuarios.containsKey(loggedInUser)) {
    correoIngresado = loggedInUser;
    runApp(InOutPharmaApp(initialRoute: '/home'));
  } else {
    runApp(const InOutPharmaApp(initialRoute: '/login'));
  }
}

class InOutPharmaApp extends StatelessWidget {
  final String initialRoute;

  const InOutPharmaApp({super.key, this.initialRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InOut Pharma',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2139AC)),
        primaryColor: const Color(0xFF2139AC),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2139AC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.roboto(fontSize: 16),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2139AC),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginView(),
        '/password': (context) => const PasswordView(),
        '/crear_cuenta': (context) => const CrearCuentaView(),
        '/crear_password': (context) => const CrearPasswordView(),
        '/pregunta_seguridad': (context) => const NuevaPreguntaSeguridadView(),
        '/bienvenida': (context) => const BienvenidaView(),
        '/home': (context) => const MainNavigator(),
        '/promociones': (context) => const PromocionesView(),
        '/perfil': (context) => const PerfilView(),
        '/mapa': (context) => const MapaView(),
      },
    );
  }
}

class Usuario {
  String nombre;
  String apellido;
  String correo;
  String password;
  String tipoDocumento;
  String numeroDocumento;
  String telefono;
  DateTime fechaNacimiento;
  String genero;
  bool tieneTratamiento;

  Usuario({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.password,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.fechaNacimiento,
    required this.genero,
    required this.tieneTratamiento,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'password': password,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'telefono': telefono,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      'genero': genero,
      'tieneTratamiento': tieneTratamiento,
    };
  }

  static Usuario fromMap(Map<String, dynamic> map) {
    return Usuario(
      nombre: map['nombre'],
      apellido: map['apellido'],
      correo: map['correo'],
      password: map['password'],
      tipoDocumento: map['tipoDocumento'],
      numeroDocumento: map['numeroDocumento'],
      telefono: map['telefono'],
      fechaNacimiento: DateTime.parse(map['fechaNacimiento']),
      genero: map['genero'],
      tieneTratamiento: map['tieneTratamiento'],
    );
  }
}

Map<String, Usuario> baseDeDatosUsuarios = {};
String correoIngresado = '';
String passwordIngresada = '';
String nombreIngresado = '';
String apellidoIngresado = '';
String tipoDocumentoIngresado = 'DNI';
String numeroDocumentoIngresado = '';
String telefonoIngresado = '';
DateTime? fechaNacimientoIngresada;
String generoIngresado = 'Masculino';
bool tieneTratamientoIngresado = false;

Future<void> guardarUsuariosEnPreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  final Map<String, dynamic> data = {};
  for (var entry in baseDeDatosUsuarios.entries) {
    data[entry.key] = entry.value.toMap();
  }
  await prefs.setString('usuarios', jsonEncode(data));
}

Future<void> cargarUsuariosDePreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  final usuariosStr = prefs.getString('usuarios');
  if (usuariosStr != null && usuariosStr.isNotEmpty) {
    final data = jsonDecode(usuariosStr) as Map<String, dynamic>;
    baseDeDatosUsuarios.clear();
    data.forEach((key, value) {
      baseDeDatosUsuarios[key] = Usuario.fromMap(value);
    });
  }
}

bool validarEmail(String email) {
  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return regex.hasMatch(email);
}

bool validarPassword(String pass) {
  return pass.length >= 5;
}

Widget whiteBackground({required Widget child}) {
  return Container(
    constraints: const BoxConstraints.expand(),
    color: Colors.white,
    child: child,
  );
}

// ------------------- Vistas -------------------

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _correoController = TextEditingController();

  void _continuar() {
    String email = _correoController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo de correo está vacío.')),
      );
      return;
    }
    if (!validarEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un correo válido (ejemplo@dominio.com).')),
      );
      return;
    }
    correoIngresado = email;
    if (baseDeDatosUsuarios.containsKey(correoIngresado)) {
      Navigator.pushReplacementNamed(context, '/password');
    } else {
      Navigator.pushReplacementNamed(context, '/crear_cuenta');
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Image.asset('assets/images/logo.png', height: 150),
                ),
                const SizedBox(height: 20),
                Text(
                  "InOut Pharma",
                  style: GoogleFonts.roboto(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Bienvenido",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _continuar,
                  child: const Text('Continuar'),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordView extends StatefulWidget {
  const PasswordView({super.key});

  @override
  State<PasswordView> createState() => _PasswordViewState();
}

class _PasswordViewState extends State<PasswordView> {
  final TextEditingController _passwordController = TextEditingController();

  void _continuar() async {
    String pass = _passwordController.text;
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo de contraseña está vacío.')),
      );
      return;
    }
    if (!validarPassword(pass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 5 caracteres.')),
      );
      return;
    }
    passwordIngresada = pass;
    if (baseDeDatosUsuarios.containsKey(correoIngresado)) {
      if (baseDeDatosUsuarios[correoIngresado]!.password == passwordIngresada) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('loggedInUser', correoIngresado);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no encontrado')),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset('assets/images/logo.png', height: 100),
              ),
              const SizedBox(height: 10),
              Text(
                "InOut Pharma",
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ingrese su contraseña",
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _continuar,
                        child: const Text('Continuar'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class CrearCuentaView extends StatefulWidget {
  const CrearCuentaView({super.key});

  @override
  State<CrearCuentaView> createState() => _CrearCuentaViewState();
}

class _CrearCuentaViewState extends State<CrearCuentaView> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _numeroDocController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  DateTime? fechaNacimiento;
  final List<String> generos = ['Masculino', 'Femenino', 'Otro'];
  String generoSeleccionado = 'Masculino';
  final List<String> tiposDocumento = ['DNI', 'Pasaporte'];
  String tipoDocSeleccionado = 'DNI';

  @override
  void initState() {
    super.initState();
    _correoController.text = correoIngresado;
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fechaNacimiento = picked;
      });
    }
  }

  String? validarCampos() {
    String n = _nombreController.text.trim();
    if (n.isEmpty) return 'El nombre está vacío.';
    if (n.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    String a = _apellidoController.text.trim();
    if (a.isEmpty) return 'El apellido está vacío.';
    if (a.length < 2) return 'El apellido debe tener al menos 2 caracteres.';
    String c = _correoController.text.trim();
    if (c.isEmpty) return 'El correo está vacío.';
    if (!validarEmail(c)) return 'El correo no es válido.';
    String doc = _numeroDocController.text.trim();
    if (doc.isEmpty) return 'El número de documento está vacío.';
    if (doc.length < 5) return 'El número de documento es muy corto.';
    String tel = _telefonoController.text.trim();
    if (tel.isEmpty) return 'El teléfono está vacío.';
    if (tel.length < 7) return 'El teléfono es muy corto.';
    if (fechaNacimiento == null) return 'Seleccione una fecha de nacimiento.';
    return null;
  }

  void _continuar() {
    String? error = validarCampos();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    nombreIngresado = _nombreController.text.trim();
    apellidoIngresado = _apellidoController.text.trim();
    correoIngresado = _correoController.text.trim();
    tipoDocumentoIngresado = tipoDocSeleccionado;
    numeroDocumentoIngresado = _numeroDocController.text.trim();
    telefonoIngresado = _telefonoController.text.trim();
    fechaNacimientoIngresada = fechaNacimiento;
    generoIngresado = generoSeleccionado;

    if (baseDeDatosUsuarios.containsKey(correoIngresado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este correo ya está registrado.')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/crear_password');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _numeroDocController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Crear Cuenta",
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: tipoDocSeleccionado,
                    decoration: const InputDecoration(labelText: 'Tipo de documento'),
                    items: tiposDocumento
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        tipoDocSeleccionado = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _numeroDocController,
                    decoration: InputDecoration(
                      labelText: tipoDocSeleccionado == 'DNI'
                          ? 'Número de DNI'
                          : 'Número de Pasaporte',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fechaNacimiento == null
                            ? 'Fecha de nacimiento'
                            : DateFormat('yyyy-MM-dd').format(fechaNacimiento!),
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                    ),
                    items: generos
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        generoSeleccionado = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _continuar,
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrearPasswordView extends StatefulWidget {
  const CrearPasswordView({super.key});

  @override
  State<CrearPasswordView> createState() => _CrearPasswordViewState();
}

class _CrearPasswordViewState extends State<CrearPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool validarPass(String p) => p.length >= 5;

  void _crearCuenta() async {
    String p1 = _passwordController.text;
    String p2 = _confirmPassController.text;
    if (p1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo de contraseña está vacío.')),
      );
      return;
    }
    if (p2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo de confirmar contraseña está vacío.')),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    if (!validarPass(p1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 5 caracteres.')),
      );
      return;
    }
    if (baseDeDatosUsuarios.containsKey(correoIngresado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este correo ya está registrado.')),
      );
      return;
    }

    baseDeDatosUsuarios[correoIngresado] = Usuario(
      nombre: nombreIngresado,
      apellido: apellidoIngresado,
      correo: correoIngresado,
      password: p1,
      tipoDocumento: tipoDocumentoIngresado,
      numeroDocumento: numeroDocumentoIngresado,
      telefono: telefonoIngresado,
      fechaNacimiento: fechaNacimientoIngresada!,
      genero: generoIngresado,
      tieneTratamiento: false,
    );

    await guardarUsuariosEnPreferencias();

    Navigator.pushReplacementNamed(context, '/pregunta_seguridad');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Crear Contraseña",
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _confirmPassController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar Contraseña',
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _crearCuenta,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Continuar'),
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}

class NuevaPreguntaSeguridadView extends StatefulWidget {
  const NuevaPreguntaSeguridadView({super.key});

  @override
  State<NuevaPreguntaSeguridadView> createState() =>
      _NuevaPreguntaSeguridadViewState();
}

class _NuevaPreguntaSeguridadViewState
    extends State<NuevaPreguntaSeguridadView> {
  Future<void> _actualizarTratamiento(bool valor) async {
    if (baseDeDatosUsuarios.containsKey(correoIngresado)) {
      final u = baseDeDatosUsuarios[correoIngresado]!;
      baseDeDatosUsuarios[correoIngresado] = Usuario(
        nombre: u.nombre,
        apellido: u.apellido,
        correo: u.correo,
        password: u.password,
        tipoDocumento: u.tipoDocumento,
        numeroDocumento: u.numeroDocumento,
        telefono: u.telefono,
        fechaNacimiento: u.fechaNacimiento,
        genero: u.genero,
        tieneTratamiento: valor,
      );
      await guardarUsuariosEnPreferencias();
    }
    Navigator.pushReplacementNamed(context, '/bienvenida');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Recibe tratamiento médico actualmente?",
                      style: GoogleFonts.roboto(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _actualizarTratamiento(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            minimumSize: const Size(100, 50),
                          ),
                          child: const Text('Sí'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            _actualizarTratamiento(false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            minimumSize: const Size(100, 50),
                          ),
                          child: const Text('No'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BienvenidaView extends StatefulWidget {
  const BienvenidaView({super.key});

  @override
  State<BienvenidaView> createState() => _BienvenidaViewState();
}

class _BienvenidaViewState extends State<BienvenidaView> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dots = List<Widget>.generate(3, (index) {
      return Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: currentPage == index ? const Color(0xFF2139AC) : Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    });

    final slides = [
      Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 175,
              ),
              const SizedBox(height: 25),
              Text(
                "InOut Pharma",
                style: GoogleFonts.roboto(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Farmaproductos confiables y siempre a tu alcance",
                style: GoogleFonts.roboto(fontSize: 22.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/cuidar_medio_ambiente.png',
                height: 250,
              ),
              const SizedBox(height: 25),
              Text(
                "En InOut Pharma, cuidamos al medio ambiente, ¡tu salud y tu bolsillo también!",
                style: GoogleFonts.roboto(
                  fontSize: 22.5,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
      Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/explora_ahora.png',
                height: 225,
              ),
              const SizedBox(height: 25),
              Text(
                "Explora ahora",
                style: GoogleFonts.roboto(
                  fontSize: 37.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 187.5,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text('Continuar'),
                ),
              )
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: slides,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (currentIndex == 0) {
      body = const HomeViewInternal();
    } else if (currentIndex == 1) {
      body = const PromocionesView();
    } else {
      body = const PerfilView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) {
          setState(() {
            currentIndex = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: 'Promociones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        selectedItemColor: const Color(0xFF2139AC),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomeViewInternal extends StatelessWidget {
  const HomeViewInternal({super.key});

  List<Map<String, String>> generarProductos() {
    return [
      {'imagen': 'assets/images/producto1.png', 'nombre': 'Paracetamol'},
      {'imagen': 'assets/images/producto2.png', 'nombre': 'Ibuprofeno'},
      {'imagen': 'assets/images/producto3.png', 'nombre': 'Vitamina C'},
      {'imagen': 'assets/images/producto4.png', 'nombre': 'Aspirina'},
      {'imagen': 'assets/images/producto5.png', 'nombre': 'Omeprazol'},
      {'imagen': 'assets/images/producto6.png', 'nombre': 'Loratadina'},
      {'imagen': 'assets/images/producto7.png', 'nombre': 'Amoxicilina'},
      {'imagen': 'assets/images/producto8.png', 'nombre': 'Metformina'},
      {'imagen': 'assets/images/producto9.png', 'nombre': 'Atorvastatina'},
      {'imagen': 'assets/images/producto10.png', 'nombre': 'Clorfeniramina'},
      {'imagen': 'assets/images/producto11.png', 'nombre': 'Diclofenaco'},
      {'imagen': 'assets/images/producto12.png', 'nombre': 'Azitromicina'},
      {'imagen': 'assets/images/producto13.png', 'nombre': 'Ranitidina'},
      {'imagen': 'assets/images/producto14.png', 'nombre': 'Losartán'},
      {'imagen': 'assets/images/producto15.png', 'nombre': 'Simvastatina'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final promociones = [
      'assets/images/noticia1.png',
      'assets/images/noticia2.png',
      'assets/images/noticia3.png',
      'assets/images/noticia4.png',
      'assets/images/noticia5.png',
      'assets/images/noticia6.png',
      'assets/images/noticia7.png',
      'assets/images/noticia8.png',
      'assets/images/noticia9.png',
      'assets/images/noticia10.png',
    ];
    final categorias = [
      {'imagen': 'assets/images/categoria1.png', 'nombre': 'Analgésicos'},
      {'imagen': 'assets/images/categoria2.png', 'nombre': 'Vitaminas'},
      {'imagen': 'assets/images/categoria3.png', 'nombre': 'Antigripales'},
      {'imagen': 'assets/images/categoria4.png', 'nombre': 'Cuidado personal'},
      {'imagen': 'assets/images/categoria5.png', 'nombre': 'Suplementos'},
    ];

    final tiendas = <Map<String, dynamic>>[
      {
        'fondo': 'assets/images/tienda_fondo1.png',
        'perfil': 'assets/images/avatar_generico1.png',
        'nombre': 'Botica Joseph',
        'ubicacion': 'Callao',
        'costo': 'S/ 5.00',
        'tiempo': '30 min',
        'productos': generarProductos()
      },
      {
        'fondo': 'assets/images/tienda_fondo2.png',
        'perfil': 'assets/images/avatar_generico2.png',
        'nombre': 'Botica Dayfama',
        'ubicacion': 'Callao',
        'costo': 'S/ 4.00',
        'tiempo': '25 min',
        'productos': generarProductos()
      },
      {
        'fondo': 'assets/images/tienda_fondo3.png',
        'perfil': 'assets/images/avatar_generico3.png',
        'nombre': 'Droguería Bienestar',
        'ubicacion': 'Calle Salud 789',
        'costo': 'S/ 3.00',
        'tiempo': '20 min',
        'productos': generarProductos()
      },
    ];

    return whiteBackground(
      child: SafeArea(
        child: Stack(
          children: [
            // Contenido principal dentro de un SingleChildScrollView
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/mapa');
                          },
                          child:
                              const Icon(Icons.map, size: 30, color: Color(0xFF2139AC)),
                        ),
                        const Spacer(),
                        Row(
                          children: const [
                            Icon(Icons.notifications,
                                size: 30, color: Color(0xFF2139AC)),
                            SizedBox(width: 20),
                            Icon(Icons.shopping_cart,
                                size: 30, color: Color(0xFF2139AC)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Busca lo que necesitas',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Categorías
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Categorías",
                        style: GoogleFonts.roboto(
                          fontSize: 22.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2139AC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categorias.length,
                        itemBuilder: (context, index) {
                          final cat = categorias[index];
                          final img = cat['imagen']!;
                          final nom = cat['nombre']!;
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(img),
                                    fit: BoxFit.cover,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                nom,
                                style: GoogleFonts.roboto(fontSize: 15),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Promociones
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Promociones",
                        style: GoogleFonts.roboto(
                          fontSize: 22.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2139AC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 187.5,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: promociones.length,
                        itemBuilder: (context, index) {
                          final fondo = promociones[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 250,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(fondo),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Descubre
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Descubre",
                        style: GoogleFonts.roboto(
                          fontSize: 22.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2139AC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < tiendas.length; i++) ...[
                      Stack(
                        children: [
                          Container(
                            height: 187.5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(tiendas[i]['fondo']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      AssetImage(tiendas[i]['perfil']),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tiendas[i]['nombre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      tiendas[i]['ubicacion'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Costo delivery: ${tiendas[i]['costo']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Tiempo: ${tiendas[i]['tiempo']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 187.5,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var prod in tiendas[i]['productos'])
                                Container(
                                  width: 125,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.asset(
                                          prod['imagen']!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Text(
                                        prod['nombre']!,
                                        style: GoogleFonts.roboto(fontSize: 15),
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Ver más productos')),
                                  );
                                },
                                child: Container(
                                  width: 62.5,
                                  height: 62.5,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2139AC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (i < tiendas.length - 1)
                        const Divider(color: Colors.grey),
                      const SizedBox(height: 20),
                    ]
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Aquí puedes agregar la lógica para la orientación farmacéutica
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orientación Farmacéutica'),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF2139AC),
                tooltip: 'Orientación Farmacéutica',
                child: const Icon(
                  FontAwesomeIcons.userDoctor,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromocionesView extends StatelessWidget {
  const PromocionesView({super.key});

  @override
  Widget build(BuildContext context) {
    final promociones = [
      {
        'imagen': 'assets/images/noticia1.png',
        'titulo': 'Descuento en Vitaminas',
        'descripcion':
            'Aprovecha un 20% de descuento en todas nuestras vitaminas.'
      },
      {
        'imagen': 'assets/images/noticia2.png',
        'titulo': 'Oferta de Analgésicos',
        'descripcion': 'Compra 2 y lleva 3 en nuestra línea de analgésicos.'
      },
      {
        'imagen': 'assets/images/noticia3.png',
        'titulo': 'Promo Antigripales',
        'descripcion':
            'Compra ahora y recibe una bolsa gratis de pañuelos.'
      },
      {
        'imagen': 'assets/images/noticia4.png',
        'titulo': 'Cuidado Personal',
        'descripcion':
            'Descuentos especiales en productos de cuidado personal.'
      },
      {
        'imagen': 'assets/images/noticia5.png',
        'titulo': 'Suplementos en Oferta',
        'descripcion':
            'Ahorra en tus suplementos favoritos durante esta semana.'
      },
      {
        'imagen': 'assets/images/noticia6.png',
        'titulo': 'Medicamentos Genéricos',
        'descripcion':
            'Precios reducidos en una amplia gama de medicamentos genéricos.'
      },
      {
        'imagen': 'assets/images/noticia7.png',
        'titulo': 'Nuevas Llegadas',
        'descripcion':
            'Descubre los últimos productos disponibles en nuestra tienda.'
      },
      {
        'imagen': 'assets/images/noticia8.png',
        'titulo': 'Promoción de Verano',
        'descripcion':
            'Descuentos exclusivos en productos seleccionados para el verano.'
      },
      {
        'imagen': 'assets/images/noticia9.png',
        'titulo': 'Paquete Familiar',
        'descripcion':
            'Compra paquetes familiares y ahorra más en tus compras.'
      },
      {
        'imagen': 'assets/images/noticia10.png',
        'titulo': 'Salud y Bienestar',
        'descripcion':
            'Ofertas especiales en productos para tu salud y bienestar.'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: promociones.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 312.5,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12.5,
                mainAxisSpacing: 12.5,
              ),
              itemBuilder: (context, index) {
                final promo = promociones[index];
                final img = promo['imagen']!;
                final tit = promo['titulo']!;
                final desc = promo['descripcion']!;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(img),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tit,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              desc,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 17.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  void _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('loggedInUser');

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = baseDeDatosUsuarios.containsKey(correoIngresado)
        ? baseDeDatosUsuarios[correoIngresado]!
        : null;
    final nombre =
        usuario != null ? '${usuario.nombre} ${usuario.apellido}' : 'Usuario';

    final secciones = <Map<String, dynamic>>[
      {'icono': Icons.person, 'texto': 'Datos'},
      {'icono': Icons.receipt, 'texto': 'Pedidos'},
      {'icono': Icons.local_offer, 'texto': 'Promociones'},
      {'icono': Icons.payment, 'texto': 'Pagos'},
      {'icono': Icons.support_agent, 'texto': 'Soporte'},
      {'icono': Icons.logout, 'texto': 'Cerrar sesión'},
      {'icono': Icons.location_on, 'texto': 'Direcciones'},
      {'icono': Icons.eco, 'texto': 'Impacto'},
      {'icono': Icons.subscriptions, 'texto': 'Suscripción'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.blue[50],
                height: 80,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    CircleAvatar(
                      backgroundImage: AssetImage(
                        usuario != null
                            ? 'assets/images/avatar_generico${(usuario.correo.hashCode % 3) + 1}.png'
                            : 'assets/images/avatar_generico1.png',
                      ),
                      radius: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nombre,
                        style: GoogleFonts.roboto(
                          fontSize: 25.6,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.shopping_cart,
                      size: 37.5,
                      color: Color(0xFF2139AC),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: secciones.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final sec = secciones[index];
                    final icono = sec['icono'] as IconData;
                    final texto = sec['texto'] as String;
                    return GestureDetector(
                      onTap: () {
                        if (texto == 'Cerrar sesión') {
                          _cerrarSesion(context);
                        }
                        // Aquí se pueden manejar otras secciones
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icono,
                              size: 50,
                              color: Colors.blue[800],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              texto,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(fontSize: 17.5),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  late GoogleMapController _controller;

  final LatLng _initialPosition = const LatLng(-12.046374, -77.042793);
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('ubicacion'),
      position: LatLng(-12.046374, -77.042793),
      infoWindow: const InfoWindow(title: 'Mi ubicación'),
    ),
    Marker(
      markerId: const MarkerId('botica1'),
      position: LatLng(-12.045, -77.04),
      infoWindow: const InfoWindow(title: 'Botica 1'),
    ),
    Marker(
      markerId: const MarkerId('botica2'),
      position: LatLng(-12.047, -77.045),
      infoWindow: const InfoWindow(title: 'Botica 2'),
    ),
    Marker(
      markerId: const MarkerId('botica3'),
      position: LatLng(-12.044, -77.043),
      infoWindow: const InfoWindow(title: 'Botica 3'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: whiteBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  title: Text(
                    'Mapa',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.7),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFF2139AC)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
