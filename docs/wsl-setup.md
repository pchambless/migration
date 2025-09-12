# WSL Development Setup Guide

This document provides detailed instructions for setting up the Migration Tool in a WSL (Windows Subsystem for Linux) environment.

## WSL Version Compatibility

This tool is designed to work with:
- WSL 1 (basic functionality)
- WSL 2 (recommended for better performance)

## Database Connectivity in WSL

### Connecting to Windows Host Databases

When running databases on your Windows host and accessing them from WSL:

#### WSL 1
- Use `localhost` or `127.0.0.1` for database connections
- Windows firewall may need configuration

#### WSL 2
- Windows host is accessible via the gateway IP
- Use this command to get the host IP:
  ```bash
  cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
  ```
- Or use the automatic detection in the configuration

### Firewall Configuration

For Windows databases accessed from WSL:
1. Open Windows Defender Firewall
2. Allow your database port (e.g., 5432 for PostgreSQL, 3306 for MySQL)
3. Allow connections from WSL subnet

## File System Considerations

### Path Handling
- WSL uses Linux paths (`/home/user/...`)
- Windows drives mounted under `/mnt/c/`, `/mnt/d/`, etc.
- Use Linux-style paths in configuration files

### Permissions
- WSL respects Linux file permissions
- Scripts automatically get execute permissions via `chmod +x`
- No need for Windows-style permission handling

### Line Endings
- Repository configured for LF line endings via `.gitattributes`
- Git automatically handles conversion
- Prevents script execution issues in WSL

## Performance Optimization

### WSL 2 Recommendations
- Store code in WSL file system (`/home/user/`) for best performance
- Avoid storing code on Windows drives (`/mnt/c/`) when possible
- Use WSL 2 for better I/O performance with databases

### Database Optimization
- Consider running databases in WSL for development
- Use Docker containers for isolated database environments
- Configure connection pooling appropriately

## Troubleshooting

### Common Issues

#### "Permission denied" on scripts
```bash
chmod +x scripts/*.sh
```

#### Database connection fails
1. Check if database service is running
2. Verify firewall settings
3. Test connection from Windows first
4. Check WSL network configuration

#### Wrong line endings in scripts
```bash
dos2unix scripts/*.sh
```

## Environment Variables

Set these in your WSL shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# Migration tool settings
export MIGRATION_HOME=/path/to/migration
export PATH=$PATH:$MIGRATION_HOME/scripts

# Database settings (optional)
export PGPASSWORD=your_password  # For PostgreSQL
```

## Integration with Windows Tools

### Database Management Tools
- Can use Windows-based database tools (pgAdmin, MySQL Workbench)
- Database accessible from both Windows and WSL
- Consistent data between environments

### IDE Integration
- VS Code with WSL extension recommended
- Can edit files directly in WSL from Windows
- Terminal integration works seamlessly

## Security Considerations

- Store sensitive configuration in `config/database.conf` (gitignored)
- Use environment variables for production credentials
- Consider using SSH tunnels for remote database access
- WSL shares network with Windows host