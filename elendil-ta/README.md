# Elendil TA — Time Series Forecasting Skill for Claude

This folder contains the **Elendil TA** skill for [Claude.ai](https://claude.ai),
the AI teaching assistant for the Time Series Forecasting course at ITESO.

## Contents

```
elendil-ta/
├── SKILL.md                        # Main skill instructions
├── references/
│   └── course_structure.md         # Module structure and datasets reference
└── elendil-ta.zip                  # Packaged skill ready for upload to Claude
```

## For students

See the [installation page](https://pbenavidesh.github.io/narsil/docs/more/elendil-ta/)
on the course site for step-by-step instructions.

**Direct download:**
[elendil-ta.zip](https://github.com/pbenavidesh/narsil/raw/main/elendil-ta/elendil-ta.zip)

## For the instructor — updating the skill

When you modify `SKILL.md` or `references/course_structure.md`, regenerate the ZIP:

```bash
# From the repo root
cd elendil-ta
zip -r elendil-ta.zip SKILL.md references/
```

Then commit both the updated source files and the new ZIP. Students who
re-download will automatically get the latest version.

## Version history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05 | Initial release |
