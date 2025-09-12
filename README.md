# Migration Orchestration Tool

Migration orchestration and DB views validation functions designed for seamless operation in WSL (Windows Subsystem for Linux) environments.

## WSL Setup Instructions

### Prerequisites
- WSL 2 installed and configured
- Git installed in WSL
- Database client tools (PostgreSQL, MySQL, or SQL Server tools as needed)

### Initial Setup in WSL

1. **Clone the repository in your WSL environment:**
   ```bash
   git clone https://github.com/pchambless/migration.git
   cd migration
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Configure your database connections:**
   ```bash
   cp config/database.example.conf config/database.conf
   # Edit config/database.conf with your database details
   ```

4. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

### WSL-Specific Considerations

- **File permissions:** WSL handles Linux file permissions, so migration scripts will have proper execute permissions
- **Path handling:** Use Linux-style paths (`/mnt/c/` for Windows C: drive access if needed)
- **Database connections:** 
  - For local Windows databases, use `localhost` or `127.0.0.1`
  - For WSL2, Windows host is accessible via the gateway IP
- **Line endings:** Ensure scripts use LF line endings (handled by .gitattributes)

## Project Structure

```
migration/
├── migrations/          # Migration SQL files
├── config/             # Configuration files
├── scripts/            # Utility and setup scripts
├── docs/              # Documentation
├── db/
│   ├── schemas/       # Database schema definitions
│   └── views/         # Database view definitions
└── README.md
```

## Configuration

Configuration files are stored in the `config/` directory:
- `database.conf` - Database connection settings
- `migration.conf` - Migration execution settings

## Usage

### Running Migrations
```bash
./scripts/migrate.sh up    # Apply pending migrations
./scripts/migrate.sh down  # Rollback last migration
./scripts/migrate.sh status # Check migration status
```

### Validating Database Views
```bash
./scripts/validate-views.sh
```

## Development in WSL

This repository is optimized for WSL development:
- All scripts are compatible with Linux environments
- Configuration supports both local and remote database connections
- File permissions are properly managed for WSL
- Supports integration with Windows-based database servers

## Contributing

1. Ensure all scripts maintain WSL compatibility
2. Test changes in a WSL environment
3. Update documentation for any new WSL-specific considerations
