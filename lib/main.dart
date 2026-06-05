import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:rapilead/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rapilead/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  // 1. Asegura que los canales de comunicación nativa estén listos
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// ─── Colores ──────────────────────────────────────────────────────────────────
class AppColors {
  // Marca
  static const Color primary = Color(0xFF3BBDF5); // azul cian del logo
  static const Color accent = Color(0xFFF5A623); // naranja del logo

  // Alias
  static const Color blue = primary;
  static const Color blueDark = Color(0xFF1A9FD8);
  static const Color orange = accent;

  // Fondos
  static const Color bgPage = Color(0xFFF8FBFF);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFFFFFFF);

  // Textos
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textGrey = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color labelGrey = Color(0xFF94A3B8);

  // Bordes
  static const Color inputBorder = Color(0xFFE2EAF4);
  static const Color divider = Color(0xFFE2EAF4);

  // Estados con color
  static const Color error = Color(0xFFEF4444); // rojo
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color success = Color(0xFF22C55E); // verde
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B); // amarillo
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3BBDF5); // cian

  // Roles (para las tarjetas de Vendedor/Administrador)
  static const Color vendedor = Color(0xFF3BBDF5); // cian
  static const Color admin = Color(0xFFF5A623); // naranja
}

// ─── Seguridad ────────────────────────────────────────────────────────────────
class SecurityHelper {
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  static String generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());

  static bool isValidPassword(String password) => password.length >= 8;

  static double passwordStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.33;
    if (p.length >= 12) s += 0.17;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) s += 0.10;
    return s.clamp(0, 1);
  }
}

// ─── Sesión ───────────────────────────────────────────────────────────────────
class SessionManager {
  static const _keySession = 'sesion_iniciada';
  static const _keyEmail = 'correo';
  static const _keyExpiry = 'sesion_expiry';
  static const _keyAttempts = 'login_attempts';
  static const _keyLockout = 'lockout_until';
  static const _sessionDurationHours = 24;
  static const _maxAttempts = 5;
  static const _lockoutMinutes = 5;

  static Future<void> saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now()
        .add(const Duration(hours: _sessionDurationHours))
        .millisecondsSinceEpoch;
    await prefs.setBool(_keySession, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setInt(_keyExpiry, expiry);
    await prefs.setInt(_keyAttempts, 0);
  }

  static Future<String?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_keySession) ?? false;
    final email = prefs.getString(_keyEmail);
    final expiry = prefs.getInt(_keyExpiry) ?? 0;
    if (!active || email == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await clearSession();
      return null;
    }
    return email;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyExpiry);
  }

  static Future<bool> registerFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final lockout = prefs.getInt(_keyLockout) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockout) return true;
    int attempts = (prefs.getInt(_keyAttempts) ?? 0) + 1;
    await prefs.setInt(_keyAttempts, attempts);
    if (attempts >= _maxAttempts) {
      await prefs.setInt(_keyLockout, now + (_lockoutMinutes * 60 * 1000));
      await prefs.setInt(_keyAttempts, 0);
    }
    return false;
  }

  static Future<int> getLockoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockout = prefs.getInt(_keyLockout) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < lockout ? ((lockout - now) / 1000).ceil() : 0;
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapiLead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Urbanist',
        scaffoldBackgroundColor: AppColors.bgPage,
      ),
      home: const LoginPage(),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────
Widget _backButton(BuildContext context) => InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.textDark),
      ),
    );

Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.labelGrey,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );

InputDecoration _inputDeco({
  required IconData icon,
  String? hint,
  bool focused = false,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.labelGrey, fontSize: 14),
      prefixIcon: Icon(icon,
          color: focused ? AppColors.blue : AppColors.labelGrey, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    );

Widget _primaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
  IconData? icon,
}) =>
    SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          disabledBackgroundColor: AppColors.blue.withAlpha(128),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );

// ─── INSTANCIA GLOBAL DE GOOGLE SIGN IN ───────────────────────────────────────
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

// ─── LoginPage ────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _loading = false;
  bool _emailFocus = false;
  bool _passFocus = false;
  String? _errorMsg;
  int _lockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _checkLockout();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user?.email != null) {
        await SessionManager.saveSession(userCredential.user!.email!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Bienvenido, ${userCredential.user!.displayName ?? "Usuario"}')),
          );
          _navigateHome();
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Error con Firebase: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Error al conectar con Google.';
      });
      debugPrint("Google Auth Error: $e");
    }
  }

  Future<void> _checkExistingSession() async {
    final email = await SessionManager.getActiveSession();
    if (email != null && mounted) _navigateHome();
  }

  Future<void> _checkLockout() async {
    final secs = await SessionManager.getLockoutSeconds();
    if (secs > 0 && mounted) {
      setState(() => _lockoutSeconds = secs);
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_lockoutSeconds > 0) _lockoutSeconds--;
      });
      if (_lockoutSeconds > 0) _startLockoutTimer();
    });
  }

  Future<void> _login() async {
    if (_lockoutSeconds > 0) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text,
      );

      await SessionManager.saveSession(credential.user!.email!);

      if (mounted) _navigateHome();
    } on FirebaseAuthException catch (e) {
      final blocked = await SessionManager.registerFailedAttempt();
      final lockSecs = await SessionManager.getLockoutSeconds();

      setState(() {
        _loading = false;
        if (blocked || lockSecs > 0) {
          _lockoutSeconds = lockSecs;
          _errorMsg = 'Demasiados intentos. Cuenta bloqueada.';
          _startLockoutTimer();
        } else {
          _errorMsg = switch (e.code) {
            'user-not-found' => 'No existe una cuenta con ese correo.',
            'wrong-password' => 'Contraseña incorrecta.',
            'invalid-email' => 'Correo inválido.',
            'user-disabled' => 'Esta cuenta está deshabilitada.',
            _ => 'Error al iniciar sesión.',
          };
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Error inesperado.';
      });
    }
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Dashboardp(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,

                    // Aquí va el logo de rapilead
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido de vuelta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ingresa tus credenciales para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 20,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _fieldLabel('Correo electrónico'),
                      Focus(
                        onFocusChange: (v) => setState(() => _emailFocus = v),
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDeco(
                              icon: Icons.mail_outline_rounded,
                              hint: 'correo@empresa.com',
                              focused: _emailFocus),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Ingresa tu correo';
                            if (!SecurityHelper.isValidEmail(v))
                              return 'Formato inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Contraseña'),
                      Focus(
                        onFocusChange: (v) => setState(() => _passFocus = v),
                        child: TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: _inputDeco(
                            icon: Icons.lock_outline_rounded,
                            hint: 'Mínimo 6 caracteres',
                            focused: _passFocus,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.labelGrey,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecuperarAccesoPage()),
                          ),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36)),
                          child: const Text('¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.errorBorder)),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 13))),
                          ]),
                        ),
                      ],
                      if (_lockoutSeconds > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange.withAlpha(76))),
                          child: Row(children: [
                            const Icon(Icons.timer_outlined,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text('Reintenta en $_lockoutSeconds segundos',
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12)),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _primaryButton(
                        label: _lockoutSeconds > 0
                            ? 'Bloqueado ($_lockoutSeconds s)'
                            : 'Ingresar',
                        onPressed:
                            (_loading || _lockoutSeconds > 0) ? null : _login,
                        loading: _loading,
                        icon: _loading ? null : Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Botón de Google ───
                const Row(children: [
                  Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1)),
                  SizedBox(width: 12),
                  Text('O CONTINÚA CON',
                      style: TextStyle(
                          color: AppColors.labelGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  SizedBox(width: 12),
                  Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1)),
                ]),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.bgCard,
                        side: const BorderSide(
                            color: AppColors.inputBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.blue),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('¿No tienes acceso? ',
                      style:
                          TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CrearCuentaPage())),
                    child: const Text('Crear cuenta',
                        style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CrearCuentaPage ──────────────────────────────────────────────────────────
class CrearCuentaPage extends StatefulWidget {
  const CrearCuentaPage({super.key});

  @override
  State<CrearCuentaPage> createState() => _CrearCuentaPageState();
}

class _CrearCuentaPageState extends State<CrearCuentaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  int _rolIndex = 0;
  String? _errorMsg;

  double _passStrength = 0;

  final List<String> _roles = ['Vendedor', 'Administrador'];
  final List<IconData> _roleIcons = [
    Icons.person_outline,
    Icons.shield_outlined
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarCuenta() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passCtrl.text;

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(_nombreCtrl.text.trim());
      await SessionManager.saveSession(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Dashboardp()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = switch (e.code) {
          'email-already-in-use' => 'Este correo ya está registrado.',
          'invalid-email' => 'El formato del correo es inválido.',
          'operation-not-allowed' =>
            'El registro por correo no está habilitado.',
          'weak-password' => 'La contraseña es demasiado débil.',
          _ => 'Ocurrió un error: ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Error inesperado al crear la cuenta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [_backButton(context)]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crear cuenta',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  SizedBox(height: 4),
                  Text('Seleccione el tipo de cuenta e ingrese sus datos',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: AppColors.divider, height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(_roles.length, (i) {
                          final sel = _rolIndex == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _rolIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? (i == 0
                                          ? AppColors.vendedor.withAlpha(20)
                                          : const Color.fromARGB(255, 245, 35, 35).withAlpha(20))
                                      : AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: sel
                                        ? (i == 0
                                            ? AppColors.vendedor
                                            : const Color.fromARGB(255, 245, 35, 35))
                                        : AppColors.inputBorder,
                                    width: sel ? 2 : 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _roleIcons[i],
                                      size: 28,
                                      color: sel
                                          ? (i == 0
                                              ? AppColors.vendedor
                                              : const Color.fromARGB(255, 245, 35, 35))
                                          : AppColors.labelGrey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _roles[i],
                                      style: TextStyle(
                                        color: sel
                                            ? (i == 0
                                                ? AppColors.vendedor
                                                : const Color.fromARGB(255, 245, 35, 35))
                                            : AppColors.textMedium,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      _fieldLabel('Nombre Completo'),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: _inputDeco(
                            icon: Icons.person_outline, hint: 'Ej. Juan Pérez'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Correo electrónico'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco(
                            icon: Icons.mail_outline,
                            hint: 'correo@empresa.com'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Ingresa un correo';
                          if (!SecurityHelper.isValidEmail(v))
                            return 'Formato inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Contraseña'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        onChanged: (v) => setState(() =>
                            _passStrength = SecurityHelper.passwordStrength(v)),
                        decoration: _inputDeco(
                          icon: Icons.lock_outline,
                          hint: 'Mínimo 8 caracteres',
                          suffix: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.labelGrey,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 8
                            ? 'Mínimo 8 caracteres'
                            : null,
                      ),
                      
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              height: 4,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _passStrength >= 0.01
                                    ? AppColors.error
                                    : AppColors.inputBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              height: 4,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _passStrength >= 0.4
                                    ? AppColors.orange
                                    : AppColors.inputBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _passStrength >= 0.75
                                    ? Colors.green
                                    : AppColors.inputBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 50,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                              child: Text(
                                _passStrength == 0
                                    ? ''
                                    : _passStrength < 0.4
                                        ? 'Débil'
                                        : _passStrength < 0.75
                                            ? 'Media'
                                            : 'Fuerte',
                                key: ValueKey(_passStrength == 0
                                    ? 'vacio'
                                    : _passStrength < 0.4
                                        ? 'debil'
                                        : _passStrength < 0.75
                                            ? 'media'
                                            : 'fuerte'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _passStrength == 0
                                      ? Colors.transparent
                                      : _passStrength < 0.4
                                          ? AppColors.error
                                          : _passStrength < 0.75
                                              ? AppColors.orange
                                              : Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_errorMsg != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _primaryButton(
                        label: 'Registrar Cuenta',
                        loading: _loading,
                        onPressed: _loading ? null : _registrarCuenta,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STUBS DE PÁGINAS FALTANTES PARA ELIMINAR ERRORES DE NAVEGACIÓN ──────────
class RecuperarAccesoPage extends StatefulWidget {
  const RecuperarAccesoPage({super.key});

  @override
  State<RecuperarAccesoPage> createState() => _RecuperarAccesoPageState();
}

class _RecuperarAccesoPageState extends State<RecuperarAccesoPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _enviado = false;
  String? _errorMsg;
  bool _emailFocus = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCorreo() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim().toLowerCase(),
      );
      setState(() {
        _loading = false;
        _enviado = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = switch (e.code) {
          'user-not-found' => 'No existe una cuenta con ese correo.',
          'invalid-email' => 'Formato de correo inválido.',
          _ => 'Error al enviar el correo.',
        };
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Error inesperado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [_backButton(context)]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _enviado ? _buildConfirmacion() : _buildFormulario(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.blue,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recuperar acceso',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Te enviaremos un enlace a tu correo\npara restablecer tu contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Correo electrónico'),
                Focus(
                  onFocusChange: (v) => setState(() => _emailFocus = v),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _enviarCorreo(),
                    decoration: _inputDeco(
                      icon: Icons.mail_outline_rounded,
                      hint: 'correo@empresa.com',
                      focused: _emailFocus,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Ingresa tu correo';
                      if (!SecurityHelper.isValidEmail(v))
                        return 'Formato inválido';
                      return null;
                    },
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                _primaryButton(
                  label: 'Enviar enlace',
                  loading: _loading,
                  onPressed: _loading ? null : _enviarCorreo,
                  icon: _loading ? null : Icons.send_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.green,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Correo enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Revisa tu bandeja de entrada en\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        const Text(
          'Haz click en el enlace del correo para\nrestablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        const SizedBox(height: 40),
        _primaryButton(
          label: 'Volver al inicio',
          onPressed: () => Navigator.pop(context),
          icon: Icons.arrow_back_rounded,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _enviado = false;
                    _emailCtrl.clear();
                  }),
          child: const Text(
            'Usar otro correo',
            style: TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
