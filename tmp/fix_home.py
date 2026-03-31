import sys

path = r'c:\Siren-Zero\lib\views\siren_zero_home_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Add Import
import_in = "import 'tactical_map_view.dart';\n"
if import_in not in lines:
    for i, line in enumerate(lines):
        if "import 'mesh_device_discovery_view.dart';" in line:
            lines.insert(i + 1, import_in)
            break

# 2. Add Card Call
card_call = "                      const SizedBox(height: 12),\n                      _buildMissionMapCard(),\n"
found_mesh = False
for i, line in enumerate(lines):
    if "_buildMeshCard()," in line:
        # Look for the next SizedBox
        for j in range(i + 1, i + 5):
            if "const SizedBox(height: 28)" in lines[j] or "const SizedBox(height: 20)" in lines[j]:
                lines.insert(j, card_call)
                found_mesh = True
                break
    if found_mesh: break

# 3. Add Helper Method
# Find the last closing brace of the class
last_brace = -1
for i in range(len(lines) - 1, -1, -1):
    if lines[i].strip() == "}":
        last_brace = i
        break

if last_brace != -1:
    helper = """
  // ================= MISSION MAP CARD =================

  Widget _buildMissionMapCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TacticalMapView()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B).withOpacity(0.9)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF38BDF8).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // 🗺 MINI MAP ICON / PREVIEW
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: Color(0xFF38BDF8),
                    size: 30,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 3)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "MISSION MAP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "GPS LIVE",
                            style: TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tactical navigation & unit coordination",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
"""
    lines.insert(last_brace, helper)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("SUCCESS")
