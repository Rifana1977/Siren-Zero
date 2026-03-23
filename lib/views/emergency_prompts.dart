class QuickActionProtocol {
  final String title;
  final String category;
  final String icon;
  final List<String> steps;
  final String? warningMessage; // ✅ ADD THIS

  QuickActionProtocol({
    required this.title,
    required this.category,
    required this.icon,
    required this.steps,
    this.warningMessage, // ✅ OPTIONAL
  });
}
// 🔥 MAIN DATA SOURCE
final List<QuickActionProtocol> quickActionProtocols = [

  QuickActionProtocol(
    title: "Adult CPR",
    category: "Cardiac",
    icon: "❤️",
    steps: [
      "Call emergency services immediately",
      "Check responsiveness and breathing",
      "Place heel of hand on center of chest",
      "Place other hand on top, interlock fingers",
      "Push hard and fast (100-120/min)",
      "Give 2 rescue breaths",
      "Repeat until help arrives",
    ],
  ),

  QuickActionProtocol(
    title: "Stop Severe Bleeding",
    category: "Bleeding",
    icon: "🩸",
    steps: [
      "Call emergency services",
      "Wear gloves if available",
      "Apply direct pressure",
      "Press firmly for 10 minutes",
      "Add more cloth if soaked",
      "Elevate injured area",
    ],
  ),

  QuickActionProtocol(
    title: "Choking Adult",
    category: "Breathing",
    icon: "🫁",
    steps: [
      "Ask if person can speak",
      "Encourage coughing if possible",
      "Give 5 back blows",
      "Give 5 abdominal thrusts",
      "Repeat until object is removed",
      "Call emergency if unconscious",
    ],
  ),

  QuickActionProtocol(
    title: "Heart Attack",
    category: "Cardiac",
    icon: "💔",
    steps: [
      "Call emergency services immediately",
      "Help person sit and stay calm",
      "Loosen tight clothing",
      "Give aspirin if available",
      "Monitor breathing",
    ],
  ),

  QuickActionProtocol(
    title: "Earthquake Safety",
    category: "Disaster",
    icon: "🏚️",
    steps: [
      "Drop, Cover, and Hold On",
      "Stay away from windows",
      "Do not use elevators",
      "Move to open area after shaking",
      "Check for injuries",
    ],
  ),

  QuickActionProtocol(
    title: "Severe Allergic Reaction",
    category: "Breathing",
    icon: "💉",
    steps: [
      "Call emergency services",
      "Use epinephrine injector if available",
      "Lay person flat",
      "Monitor breathing",
      "Give CPR if needed",
    ],
  ),

  QuickActionProtocol(
    title: "Burn Treatment",
    category: "Burns",
    icon: "🔥",
    steps: [
      "Cool burn under running water",
      "Remove tight items",
      "Cover with clean cloth",
      "Do NOT apply ice",
      "Seek medical help if severe",
    ],
  ),

  QuickActionProtocol(
    title: "Hypothermia",
    category: "Wilderness",
    icon: "🥶",
    steps: [
      "Move to warm place",
      "Remove wet clothing",
      "Wrap in blankets",
      "Give warm drinks",
      "Seek medical help",
    ],
  ),
];