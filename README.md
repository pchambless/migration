# WhatsFresh Migration System

A structured database migration system for moving data from production to test servers with individual step control and error handling.

## Directory Structure

```
a-wf-migration/
├── session/
│   ├── start.sh          # Start tunnels (prodServer|testServer|both)
│   └── stop.sh           # Stop tunnels (prodServer|testServer|both)
├── migration/
│   ├── run.sh            # Main orchestrator - runs all steps
│   ├── 01_drop_tables.sh # Drop tables in dependency order
│   ├── 02_convertIngrBtch.sh        # Convert ingredient batches
│   ├── 03_convertProd.sh            # Convert products
│   ├── 04_convertProdBtch.sh        # Convert product batches
│   ├── 05_convertRcpeBtch.sh        # Convert recipe batches
│   ├── 06_convertTaskBtch.sh        # Convert task batches
│   ├── 07_convertProdIngr_Map.sh    # Convert product ingredient mapping
│   ├── 08_createShopEvent.sh        # Create shop events
│   ├── 09_ConvertMeasureUnits.sh    # Convert measure units
│   ├── 10_convertIndices.sh         # Convert indices
│   └── common.sh         # Shared functions and logging
├── config.json           # Server and database configuration
└── tunnel_manager_v2.sh  # Low-level tunnel management
```

## Usage Workflow

### 1. Session Management

**Start both servers:**
```bash
./session/start.sh
```

**Start individual servers:**
```bash
./session/start.sh prodServer    # Production only
./session/start.sh testServer    # Test server only
```

**Stop all sessions:**
```bash
./session/stop.sh
```

### 2. Run Complete Migration

```bash
./migration/run.sh
```

This runs all steps in sequence, stopping on first failure.

### 3. Run Individual Steps

If migration fails at any step, you can run individual steps:

```bash
./migration/02_convertIngrBtch.sh    # Run specific step
./migration/03_convertProd.sh        # Continue from here
# ... etc
```

## Configuration

**Servers configured in `config.json`:**
- **Production**: `paul@whatsfresh.app` (password auth)
- **Test**: `root@159.223.104.19` (SSH key auth)

**Port assignments:**
- **Production**: `localhost:13306` → `prod:3306`
- **Test**: `localhost:13307` → `test:3306`

## Migration Steps

1. **Drop Tables** - Removes existing tables in dependency order
2. **Convert Ingredient Batches** - `wf_meta.convertIngrBtch()`
3. **Convert Products** - `wf_meta.convertProd`
4. **Convert Product Batches** - `wf_meta.convertProdBtch()`
5. **Convert Recipe Batches** - `wf_meta.convertRcpeBtch()`
6. **Convert Task Batches** - `wf_meta.convertTaskBtch()`
7. **Convert Product Ingredient Mapping** - `wf_meta.convertProdIngr_Map()`
8. **Create Shop Events** - `wf_meta.createShopEvent()`
9. **Convert Measure Units** - `wf_meta.ConvertMeasureUnits()`
10. **Convert Indices** - `wf_meta.convertIndices()`

## Troubleshooting

**If tunnels fail to start:**
```bash
./tunnel_manager_v2.sh status    # Check tunnel status
./session/start.sh prodServer    # Test production only
./session/start.sh testServer    # Test staging only
```

**If migration step fails:**
- Check logs in `./logs/migration_TIMESTAMP.log`
- Fix the issue manually
- Run the failed step individually: `./migration/XX_step_name.sh`
- Continue with remaining steps

**Manual connections for testing:**
```bash
# Production
mysql -h localhost -P 13306 -u paul -p

# Test server  
mysql -h localhost -P 13307 -u root -p
```

## Key Features

✅ **Individual step control** - Run any step independently  
✅ **Stop on failure** - Migration halts if any step fails  
✅ **Comprehensive logging** - All actions logged with timestamps  
✅ **Tunnel management** - Independent server connection control  
✅ **Error handling** - Graceful failure handling and recovery  
✅ **Progress tracking** - Clear step-by-step progress indication
=======
# migration
Migration orchestration and DB views validation functions
>>>>>>> master
