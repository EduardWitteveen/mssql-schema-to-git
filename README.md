# Export SQL Server Schema to Git

## Overview

This project automates the export of SQL Server database schemas to a structured folder layout and integrates with Git for version control. It was built to be **repeatable, consistent**, and **language model-friendly**, enabling even AI agents to maintain the repository independently over time.

## Purpose

The goal is to:

- Track and version-control database structures
- Enable reproducible exports from multiple environments
- Allow collaboration between humans and AI agents in maintaining schema definitions

## Requirements

- Windows with PowerShell 5.0 or higher  
- SQL Server Management Objects (SMO) (automatically installed if missing)  
- [dbatools](https://dbatools.io/) PowerShell module (automatically installed if needed)  
- Access to SQL Server databases with appropriate rights (e.g., `VIEW DEFINITION`)  
- Git (for version control)

## Installation

1. Copy and adjust the `ExportConfig.json` file with the desired server and database combinations.
2. Run `RunExport.bat` (this will invoke `InitializeEnvironment.ps1` and then `ExportData.ps1`). ℹ️ Tip: The exported schema files are stored outside this project directory (e.g., `../mssql-schema-to-git-export`) to allow using a separate Git repository for version tracking. This keeps the main tooling clean and maintainable.
3. If required, initialize Git: `git init`  
4. Track the exported SQL files: `git add .`  
5. Commit: `git commit -m "Initial schema export"`  
6. Push to your remote repository.

## Configuration (`ExportConfig.json`)
> ℹ️ Achtung: don't commit your configfile!

1. First copy the sample-configfile:
 ```powershell
   Copy-Item ExportConfig.sample.json ExportConfig.json
```

The configuration file has the following structure:

```json
{
  "MinPSVersion": 5,
  "InstallDbatoolsInBin": true,
  "BinFolder": "bin",
  "ExportRoot": "metadata",
  "Servers": [
    {
      "Name": "localhost",
      "Databases": [ "master", "tempdb" ]
    },
    {
      "Name": "(localdb)\MSSQLLocalDB",
      "Databases": [ "model", "msdb" ]
    }
  ]
}
```

- `MinPSVersion`: Minimum PowerShell version  
- `InstallDbatoolsInBin`: Whether to install dbatools in a local folder  
- `BinFolder`: Folder where `dbatools` should be installed (if above is true)  
- `ExportRoot`: Output root for SQL scripts  
- `Servers`: List of servers and databases to export

## Script Overview

| Script                    | Version | Purpose                                                      |
|---------------------------|---------|--------------------------------------------------------------|
| `ExportData.ps1`          | 1.11    | Exports all database objects (tables, views, etc.) to `.sql` |
| `InitializeEnvironment.ps1` | 1.7    | Sets up dbatools, policies, and SSL overrides                |
| `RunExport.bat`           | 1.1     | Orchestrates the environment setup and export process        |
| `ExportConfig.json`       | 1.0     | JSON-based configuration                                     |
| `llm-prompt.txt`          | 1.6     | Instructions for maintaining the repo with a language model  |
| `LICENSE`                 | -       | European Union Public Licence (EUPL)                         |
| `.gitignore`              | -       | Ignores logs, temp files, and exports in Git                 |

## Usage

1. Configure `ExportConfig.json`
2. Run `RunExport.bat`
3. Use Git to manage and track changes

## Known Issues

1. **Elevated rights not always required**  
   Administrator privileges are only needed the first time (e.g., to install modules). This could be skipped if everything is already installed.

2. **System tables are exported**  
   The script currently exports all tables, including SQL Server system tables. Future improvements will filter only user-defined objects (e.g., `dbo`).

3. **Warnings on SQL Server internal objects**  
   Exporting built-in procedures like `sys.sp_FuzzyLookupTableMaintenanceInstall` may generate errors due to missing metadata (e.g., `AssemblyName`). These can be ignored.

4. **Invalid path characters in view/procedure names**  
   Some database object names (especially in reporting/datawarehouse views) may contain characters not valid for filenames (like `>` or `<`). These objects currently cause warnings or fail to export.

## AI-Friendly Design

This project is intentionally designed to work seamlessly with **AI agents**, such as ChatGPT. The file `llm-prompt.txt` documents:

- All expected files and versions  
- Conventions for collaboration  
- How to validate outputs  
- The workflow between Eduard and AI  

This makes it possible to maintain, extend, and iterate on the project in a consistent and traceable way — even in a human-AI co-creation scenario.

## Credits

This project is the result of an iterative collaboration between Eduard and an AI language model. In addition to building a functioning export tool, the collaboration produced a **repeatable and transparent working method** that allows versioned tooling and AI-driven maintenance to coexist. It demonstrates how tooling and work agreements can be structured so that language models can actively contribute to open source development alongside human developers.

## License

This project is licensed under the [European Union Public Licence (EUPL)](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12).
