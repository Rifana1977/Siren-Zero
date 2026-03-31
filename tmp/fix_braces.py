import sys

path = r'c:\Siren-Zero\lib\views\siren_zero_home_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# The issue is we have a closing brace mid-file that closes the state class.
# Let's find:
#    );
#   }
# 
#   // ================= MISSION MAP CARD =================

bad_pattern = """    );
  }

  // ================= MISSION MAP CARD =================
"""

# Let's check if there's a triple-brace or similar at the absolute end.
# If we have a closing brace at 1462 and another at the end, 
# then removing the one at 1462 will rejoin the class.

if bad_pattern in text:
    new_text = text.replace(bad_pattern, """    );
  }

  // ================= MISSION MAP CARD =================
""", 1) # Just one replacement
    # Wait, the bad pattern IS what I want it to look LIKE inside the class.
    # The problem is that a } was ALREADY there.

# Let's try to find the sequence of } } that is at the end of buildModelItem.
# 1459:   }
# 1460: }
# 1464: // ================= MISSION MAP CARD =================

# I'll just look for "  }\n}\n\n  // ================= MISSION MAP CARD"
target = "  }\n}\n\n  // ================= MISSION MAP CARD"
# Note: Whitespace might be different. 

import re
# Look for a closing brace strictly followed by another closing brace on its own line, 
# then some space and our comment.
pattern = r"(\n\s*\}\s*\n)(\s*\}\s*\n)(\s*// =+ MISSION MAP CARD =+)"
match = re.search(pattern, text)

if match:
    # We want to remove the SECOND group (the extra closing brace)
    text = text[:match.start(2)] + text[match.end(2):]
    print("SUCCESS: Removed extra closing brace.")
else:
    print("WARNING: Could not find the pattern exactly. Trying a simpler one.")
    # Alternate check if the file ends in }} but we only want one class-closer.
    # But we have two classes in the file (SirenZeroHomeView and _SirenZeroHomeViewState).
    # So we SHOULD have } then } at the end.
    
    # If the helper is OUTSIDE, then the file ends in:
    # class State { ... }
    # Widget Helper() { ... }
    # } // This is a loose brace!

    # Let's just fix the entire file by joining 1462's brace.
    lines = text.splitlines(keepends=True)
    # Find line 1460 which is the extra }
    if "  }" in lines[1461] and "}" in lines[1462] and "// ==" in lines[1464]:
        # This is a guestimate of line numbers from the tool view
        # Let's use content matching instead.
        pass

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
