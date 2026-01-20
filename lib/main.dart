import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

// --- 1. KONFIGURASI TEMA & DATA MODELS ---

class AppColors {
  static const Color primary = Color(0xFF2c3e50); // Midnight Blue
  static const Color accent = Color(0xFF3498db);  // Bright Blue
  static const Color bg = Color(0xFFecf0f1);      // Cloud White
  static const Color cardBg = Colors.white;
  static const Color text = Color(0xFF2c3e50);
}

class Criteria {
  String name;
  double weight;
  String type;
  Criteria({required this.name, required this.weight, required this.type});
}

class Candidate {
  String name;
  Map<String, double> scores;
  double finalScore;
  Candidate({required this.name, required this.scores, this.finalScore = 0.0});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPK MOORA Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // Enable Material 3 untuk look lebih modern di desktop
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.bg,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          surfaceTintColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 2. SPLASH SCREEN (Sama, dipercepat sedikit) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() => _progress += 0.02);
      if (_progress >= 1.0) {
        timer.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainAppScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SizedBox(
          width: 400, // Limit width for desktop
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.desktop_mac_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text("SPK BEASISWA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const Text("Desktop Edition v2.0", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              LinearProgressIndicator(value: _progress, color: AppColors.accent, backgroundColor: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. MAIN APP (RESPONSIVE LAYOUT) ---
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  List<Criteria> criteriaList = [];
  List<Candidate> candidateList = [];

  // Controllers
  final TextEditingController _critNameCtrl = TextEditingController();
  final TextEditingController _critWeightCtrl = TextEditingController(text: "20");
  final TextEditingController _candNameCtrl = TextEditingController();
  String _selectedType = "Benefit";

  // --- LOGIC (SAMA SEPERTI SEBELUMNYA) ---
  void _addCriteria() {
    if (_critNameCtrl.text.isEmpty || _critWeightCtrl.text.isEmpty) return;
    String cleanWeight = _critWeightCtrl.text.replaceAll(',', '.'); // Fix koma
    setState(() {
      criteriaList.add(Criteria(
        name: _critNameCtrl.text,
        weight: double.tryParse(cleanWeight) ?? 0,
        type: _selectedType,
      ));
      _critNameCtrl.clear();
      _critWeightCtrl.text = "20";
    });
    // Update existing candidates to have this new criteria key (with score 0)
    for (var cand in candidateList) {
      if (!cand.scores.containsKey(_critNameCtrl.text)) {
        cand.scores[_critNameCtrl.text] = 0.0;
      }
    }
  }

  void _addCandidate() {
    if (_candNameCtrl.text.isEmpty) return;
    if (criteriaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Input kriteria dahulu!")));
      return;
    }
    setState(() {
      Map<String, double> initialScores = {};
      for (var c in criteriaList) initialScores[c.name] = 0.0;
      candidateList.add(Candidate(name: _candNameCtrl.text, scores: initialScores));
      _candNameCtrl.clear();
    });
  }

  void _calculateMoora() {
    if (candidateList.isEmpty || criteriaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data belum lengkap!")));
      return;
    }
    Map<String, double> divisors = {};
    for (var crit in criteriaList) {
      double sumSq = 0;
      for (var cand in candidateList) {
        double val = cand.scores[crit.name] ?? 0;
        sumSq += pow(val, 2);
      }
      divisors[crit.name] = sqrt(sumSq);
    }

    for (var cand in candidateList) {
      double yi = 0;
      for (var crit in criteriaList) {
        double rawVal = cand.scores[crit.name] ?? 0;
        double divisor = divisors[crit.name] ?? 1;
        double normalized = (divisor == 0) ? 0 : rawVal / divisor;
        double weightedScore = normalized * (crit.weight / 100.0); // Asumsi bobot input persen
        if (crit.type == "Benefit") yi += weightedScore; else yi -= weightedScore;
      }
      cand.finalScore = yi;
    }
    setState(() {
      candidateList.sort((a, b) => b.finalScore.compareTo(a.finalScore));
      _currentIndex = 2; // Jump to result
    });
  }

  void _showScoreInputDialog(Candidate candidate) {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, TextEditingController> ctrls = {};
        for(var c in criteriaList) ctrls[c.name] = TextEditingController(text: candidate.scores[c.name].toString());
        
        return AlertDialog(
          title: Text("Input Nilai: ${candidate.name}"),
          content: SizedBox(
            width: 400, // Fixed width for desktop dialog
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: criteriaList.map((crit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: ctrls[crit.name],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "${crit.name} (${crit.type})", suffixText: "Poin"),
                  ),
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  for(var c in criteriaList) {
                     String val = ctrls[c.name]!.text.replaceAll(',', '.');
                     candidate.scores[c.name] = double.tryParse(val) ?? 0;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            )
          ],
        );
      },
    );
  }

  void _resetData() {
    setState(() {
      candidateList.clear();
      criteriaList.clear();
      _currentIndex = 0;
    });
  }

  // --- RESPONSIVE WIDGETS ---

  // Container pembungkus agar konten tidak terlalu lebar di layar besar
  Widget _responsiveContainer({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000), // Max lebar 1000px
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }

  Widget _buildTabInput() {
    return _responsiveContainer(
      child: ListView(
        children: [
          _buildHeader("Konfigurasi Data"),
          
          // Row untuk Form Kriteria (Desktop Style)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Tambah Kriteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    // Jika layar lebar, buat input berjejer (Row). Jika sempit, stack (Column).
                    bool isWide = constraints.maxWidth > 600;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(flex: isWide ? 2 : 0, child: TextField(controller: _critNameCtrl, decoration: const InputDecoration(labelText: "Nama Kriteria", prefixIcon: Icon(Icons.label)))),
                        SizedBox(width: 10, height: isWide ? 0 : 10),
                        Flexible(flex: isWide ? 1 : 0, child: TextField(controller: _critWeightCtrl, decoration: const InputDecoration(labelText: "Bobot (%)", prefixIcon: Icon(Icons.percent)))),
                         SizedBox(width: 10, height: isWide ? 0 : 10),
                        Flexible(flex: isWide ? 1 : 0, child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
                            items: ["Benefit", "Cost"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ),
                        SizedBox(width: 10, height: isWide ? 0 : 10),
                        SizedBox(
                          width: isWide ? null : double.infinity,
                          height: 56, // Match height of textfield
                          child: ElevatedButton.icon(onPressed: _addCriteria, icon: const Icon(Icons.add), label: const Text("Tambah")),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: criteriaList.map((c) => Chip(
                      avatar: CircleAvatar(backgroundColor: Colors.white, child: Text(c.name[0])),
                      label: Text("${c.name} (${c.weight}%) - ${c.type}"),
                      backgroundColor: c.type == "Benefit" ? Colors.green.shade100 : Colors.red.shade100,
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => criteriaList.remove(c)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("2. Tambah Kandidat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _candNameCtrl, decoration: const InputDecoration(labelText: "Nama Mahasiswa/Kandidat", prefixIcon: Icon(Icons.person)))),
                      const SizedBox(width: 16),
                      SizedBox(height: 56, child: ElevatedButton.icon(onPressed: _addCandidate, icon: const Icon(Icons.person_add), label: const Text("Simpan Kandidat"))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Total Kandidat Tersimpan: ${candidateList.length}", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabMatrix() {
    if (criteriaList.isEmpty) return const Center(child: Text("Silakan input Kriteria dahulu"));
    if (candidateList.isEmpty) return const Center(child: Text("Belum ada Kandidat"));

    return _responsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader("Input Penilaian Matriks"),
          const SizedBox(height: 10),
          Expanded(
            // GridView lebih bagus di desktop daripada ListView
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300, // Lebar kartu maksimal
                childAspectRatio: 2.5,   // Rasio lebar:tinggi kartu
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: candidateList.length,
              itemBuilder: (context, index) {
                final cand = candidateList[index];
                // Cek apakah data sudah diisi semua (simple check)
                bool isFilled = cand.scores.values.every((v) => v > 0);
                
                return Card(
                  color: isFilled ? Colors.white : Colors.orange.shade50,
                  child: InkWell(
                    onTap: () => _showScoreInputDialog(cand),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppColors.primary, child: Text(cand.name[0], style: const TextStyle(color: Colors.white))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cand.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(isFilled ? "Data Lengkap" : "Belum dinilai", style: TextStyle(fontSize: 12, color: isFilled ? Colors.green : Colors.orange.shade800)),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_note, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _calculateMoora,
              icon: const Icon(Icons.calculate),
              label: const Text("HITUNG RANKING MOORA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabResult() {
     if (candidateList.isEmpty || candidateList[0].finalScore == 0) {
       return Center(child: TextButton.icon(onPressed: ()=> setState(()=> _currentIndex=1), icon: const Icon(Icons.arrow_back), label: const Text("Lakukan Perhitungan Dahulu")));
     }

    return _responsiveContainer(
      child: Column(
        children: [
           _buildHeader("Hasil Rekomendasi"),
           
           // Highlight Winner
           Card(
             color: AppColors.primary,
             child: Padding(
               padding: const EdgeInsets.all(24),
               child: Row(
                 children: [
                   const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                   const SizedBox(width: 24),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("Rekomendasi Terbaik", style: TextStyle(color: Colors.white70)),
                       Text(candidateList[0].name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                       Text("Skor Yi: ${candidateList[0].finalScore.toStringAsFixed(4)}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                     ],
                   )
                 ],
               ),
             ),
           ),
           const SizedBox(height: 24),
           
           // List Sisa Kandidat
           Expanded(
             child: ListView.separated(
               itemCount: candidateList.length,
               separatorBuilder: (c, i) => const Divider(),
               itemBuilder: (context, index) {
                 final cand = candidateList[index];
                 return ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   leading: CircleAvatar(
                     backgroundColor: index == 0 ? Colors.amber : Colors.grey.shade300,
                     foregroundColor: index == 0 ? Colors.white : Colors.black,
                     child: Text("${index + 1}"),
                   ),
                   title: Text(cand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                   subtitle: Text("Skor Akhir: ${cand.finalScore.toStringAsFixed(4)}"),
                   trailing: index == 0 ? const Chip(label: Text("Terbaik"), backgroundColor: Colors.amber) : null,
                 );
               },
             ),
           ),
           
           OutlinedButton.icon(
            onPressed: _resetData,
            icon: const Icon(Icons.refresh),
            label: const Text("Mulai Ulang / Reset"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
           )
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Container(width: 60, height: 4, color: AppColors.accent, margin: const EdgeInsets.only(top: 8))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LAYOUT BUILDER UNTUK RESPONSIVE (Switch between Mobile & Desktop layout)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Anggap layar lebar (Desktop) jika width > 800
        bool isDesktop = constraints.maxWidth > 800;

        // Konten utama berdasarkan tab yang aktif
        Widget content = IndexedStack(
          index: _currentIndex,
          children: [ _buildTabInput(), _buildTabMatrix(), _buildTabResult() ],
        );

        if (isDesktop) {
          // --- DESKTOP LAYOUT (SIDEBAR / RAIL) ---
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) => setState(() => _currentIndex = index),
                  backgroundColor: AppColors.primary,
                  indicatorColor: AppColors.accent,
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: const IconThemeData(color: Colors.white54),
                  selectedLabelTextStyle: const TextStyle(color: Colors.white),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Icon(Icons.school, color: Colors.white, size: 40),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dataset), label: Text('Data')),
                    NavigationRailDestination(icon: Icon(Icons.grid_view), label: Text('Penilaian')),
                    NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Hasil')),
                  ],
                ),
                // Garis pemisah vertikal
                const VerticalDivider(thickness: 1, width: 1),
                // Area Konten Utama
                Expanded(child: Container(color: AppColors.bg, child: content)),
              ],
            ),
          );
        } else {
          // --- MOBILE LAYOUT (BOTTOM BAR) ---
          return Scaffold(
            appBar: AppBar(
              title: const Text("SPK MOORA"),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: content,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dataset), label: "Data"),
                BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Penilaian"),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Hasil"),
              ],
            ),
          );
        }
      },
    );
  }
}