import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Form Login',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          surface: Colors.grey[50]!,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _lastRefreshTime = '';
  bool _showCacheNotification = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Memuat data yang tersimpan
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('name') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        _lastRefreshTime = prefs.getString('lastRefreshTime') ?? '';

        // Tampilkan notifikasi jika data diambil dari cache
        final bool hasCachedData =
            _nameController.text.isNotEmpty || _emailController.text.isNotEmpty;
        if (hasCachedData) {
          _showCacheNotification = true;
          // Sembunyikan notifikasi setelah 5 detik
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _showCacheNotification = false;
              });
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading saved data: $e');
    }
  }

  // Menyimpan data ke SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('lastRefreshTime', DateTime.now().toString());
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  // Hapus data yang tersimpan (Clear Cache)
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('lastRefreshTime');

      setState(() {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmController.clear();
        _lastRefreshTime = '';
        _showCacheNotification = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache berhasil dihapus'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus cache: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Refresh data dari cache
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('name') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        _lastRefreshTime = DateTime.now().toString();

        // Simpan waktu refresh terbaru
        prefs.setString('lastRefreshTime', _lastRefreshTime);

        // Tampilkan notifikasi refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil di-refresh'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format timestamp untuk display
  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return 'Belum pernah di-refresh';

    try {
      final dateTime = DateTime.parse(timestamp);
      return 'Terakhir refresh: ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format waktu tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Registrasi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          // Tombol Clear Cache
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearCache,
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Notifikasi Data from Cache
                        if (_showCacheNotification)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cached,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data loaded from cache',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _showCacheNotification = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                        buildNameField(),
                        const SizedBox(height: 16),
                        buildEmailField(),
                        const SizedBox(height: 16),
                        buildPasswordField(),
                        const SizedBox(height: 16),
                        buildConfirmPasswordField(),
                        const SizedBox(height: 24),
                        buildLoginButton(),
                        const SizedBox(height: 16),

                        // Timestamp dan Info Cache
                        Card(
                          color: Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Timestamp
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatTimestamp(_lastRefreshTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Tombol Clear Cache
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Clear Cache'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _clearCache,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Info tambahan
                                const Text(
                                  'Data nama dan email akan disimpan di cache perangkat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildNameField() {
    return TextFormField(
      controller: _nameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        labelText: 'Nama Lengkap',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama lengkap wajib diisi';
        } else if (value.length < 3) {
          return 'Nama minimal 3 karakter';
        } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
          return 'Nama hanya boleh mengandung huruf dan spasi';
        }
        return null;
      },
    );
  }

  Widget buildEmailField() {
    return TextFormField(
      controller: _emailController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email wajib diisi';
        } else if (!isValidEmail(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  Widget buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Password',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password wajib diisi';
        } else if (!isValidPassword(value)) {
          return 'Password minimal 6 karakter dan mengandung angka & huruf';
        }
        return null;
      },
    );
  }

  Widget buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmController,
      obscureText: _obscureConfirmPassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Konfirmasi Password',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Konfirmasi password wajib diisi';
        } else if (!isPasswordMatch(value)) {
          return 'Password tidak cocok';
        }
        return null;
      },
    );
  }

  Widget buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Simpan Data', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await _saveData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil disimpan!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error menyimpan data: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Periksa kembali input Anda'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Data Tersimpan',
          style: TextStyle(color: Colors.green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${_nameController.text}'),
            Text('Email: ${_emailController.text}'),
            const SizedBox(height: 16),
            Text(
              _formatTimestamp(DateTime.now().toString()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6 &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[a-zA-Z]').hasMatch(password);
  }

  bool isPasswordMatch(String confirmPassword) {
    return confirmPassword == _passwordController.text;
  }
}
