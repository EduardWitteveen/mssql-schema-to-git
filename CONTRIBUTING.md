# Contributing to mssql-schema-to-git

Thank you for considering contributing to this project! Whether you're fixing a bug, improving documentation, or proposing a feature — your help is welcome.

This project is a collaboration between human developers and a language model (LLM) and is designed to be **re-entrant**, meaning changes should remain understandable by both humans and AI models for future iterations.

---

## 🚀 Getting Started

1. **Clone this repository**  
   ```bash
   git clone https://github.com/EduardWitteveen/mssql-schema-to-git.git
   ```

2. **Install prerequisites**
   - PowerShell 5.0 or higher (Windows)
   - Git
   - Internet access to install PowerShell modules (`dbatools`, `SqlServer`)

3. **Configure your environment**
   - Adjust the `ExportConfig.json` to fit your own SQL Server environment.
   - By default, export files are stored in a separate directory: `../mssql-schema-to-git-export`

---

## 🧠 AI Collaboration Philosophy

This project is maintained collaboratively by Eduard and a language model (ChatGPT). This means:

- Code should be **deterministic** — avoid unnecessary randomness or unstable output.
- Prompts, logs, and outputs are structured to be AI-readable.
- Comments and commit messages should clearly explain **why** changes were made.

If you're using a language model yourself to contribute, that's welcome — just include a note in your PR if applicable.

---

## 📁 Folder & File Guidelines

| Folder/File         | Purpose                                  |
|---------------------|------------------------------------------|
| `ExportConfig.json` | Config file to define export settings    |
| `ExportData.ps1`    | Main script that performs the export     |
| `RunExport.bat`     | Simple runner to start export            |
| `InitializeEnvironment.ps1` | Script to install tools and prepare environment |
| `llm-prompt.txt`    | Instructions for LLM collaboration       |
| `README.md`         | Project overview                         |
| `LICENSE`           | EUPL license for reuse                   |

Exported schema files live in a **separate repo/folder**, such as: `../mssql-schema-to-git-export`

---

## ✅ Contribution Types

- Fixing bugs or improving compatibility (e.g., with dbatools updates)
- Improving documentation or prompts
- Enhancing error handling or logging
- Refactoring to improve readability or structure
- Adding helper scripts or automation (e.g., Git hooks, test runners)

---

## 🧪 Testing Guidelines

Before submitting:
- Run `RunExport.bat` on a local test database
- Verify that exported files are correct, contain no unstable headers, and match expectations
- Make sure `ExportData.ps1` logs the right version and handles all configured databases

---

## 🔀 Pull Request Process

1. Fork the repository and make your changes in a new branch.
2. Follow versioning in script headers (e.g. `.ps1` files) — bump minor version when changing logic.
3. Update `llm-prompt.txt` if the collaboration model or file structure changes.
4. Open a pull request with a clear explanation of your changes.

---

## 🧾 License

By contributing, you agree that your changes will be licensed under the **European Union Public License (EUPL)** as specified in the `LICENSE` file.

---

Thanks again for helping improve this project!
