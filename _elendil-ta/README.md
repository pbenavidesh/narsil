# Elendil TA — Time Series Forecasting Skill for Claude

This folder contains the **Elendil TA** skill for [Claude.ai](https://claude.ai),
the AI teaching assistant for the Time Series Forecasting course at ITESO.

## Contents

```
_elendil-ta/
├── SKILL.md                        # Main skill instructions
├── references/
│   └── course_structure.txt        # Module structure and datasets reference
└── elendil-ta.zip                  # Packaged skill ready for upload to Claude
```

## For students

See the [installation page](https://pbenavidesh.github.io/narsil/docs/more/elendil-ta/)
on the course site for step-by-step instructions.

**Direct download:**
[elendil-ta.zip](https://github.com/pbenavidesh/narsil/raw/main/_elendil-ta/elendil-ta.zip)

## For the instructor — updating the skill

When you modify `SKILL.md` or `references/course_structure.txt`, regenerate the ZIP:

```bash
# From the repo root
cd _elendil-ta
zip -r elendil-ta.zip SKILL.md references/
```

Then commit both the updated source files and the new ZIP. Students who
re-download will automatically get the latest version.

## Version history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05 | Initial release |
| 1.1 | 2026-08-19 | Course structure resynced with the site (all 17 lessons, module/lesson numbering instead of weeks); URL table completed (Module 4 lessons, course intro, all supplementary pages); setup and packages guidance added (`pak::pak()`, Prophet installed separately); Positron replaces RStudio as the course IDE |
