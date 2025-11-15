# SSSE-Patcher

> **⚠️ ARCHIVED - This repository has been merged into [GalaxyBookEnabler](https://github.com/Bananz0/GalaxyBookEnabler)**
>
> **As of v3.0.0, all SSSE patching functionality is now integrated into the main Galaxy Book Enabler project.**
>
> **Please use the unified installer instead:** https://github.com/Bananz0/GalaxyBookEnabler

---

## Migration Notice

This standalone patcher has been **deprecated** and its functionality has been **fully integrated** into the Galaxy Book Enabler project.

### Why the merge?

- **Better user experience**: One installer handles everything (registry spoof + apps + SSSE)
- **Easier maintenance**: Single codebase, unified updates
- **More features**: Automatic CAB downloads, service management, comprehensive error handling
- **Active development**: All new features will be added to GalaxyBookEnabler

### What to do now?

**If you're a new user:**
1. Head to https://github.com/Bananz0/GalaxyBookEnabler
2. Download the latest release (v3.0.0+)
3. Run the installer - it includes SSSE patching as an optional advanced feature

**If you're an existing SSSE-Patcher user:**
1. Uninstall your current SSSE installation (stop service, delete files)
2. Install GalaxyBookEnabler v3.0.0+ which includes:
   - Registry spoofing (required foundation)
   - Samsung app installation
   - SSSE patching (improved version of this tool)
3. Your custom configurations will be preserved during migration

### What's improved in v3.0.0?

✅ **Automatic CAB downloads** from Microsoft Update Catalog  
✅ **Service conflict resolution** - automatically handles existing services  
✅ **Better error handling** - clearer messages, automatic rollbacks  
✅ **Version selection** - choose from multiple tested SSSE versions  
✅ **Integrated experience** - one tool for complete Samsung ecosystem  
✅ **Active maintenance** - regular updates and bug fixes  

---

## Original Repository Information

**A patch for SSSE using the .cab file provided by yourself**

This repository originally provided standalone binary patching for Samsung System Support Engine to enable Samsung Settings on non-Samsung devices.

### Original Features (now integrated into GalaxyBookEnabler)

- Binary patching of `SamsungSystemSupportEngine.exe`
- Pattern matching for multiple SSSE versions
- Service creation and management
- Driver installation instructions

### Historical Versions Supported

- 7.1.2.0 (Latest)
- 7.0.10.0
- 6.3.3.0 (Most stable)
- Earlier versions (check branches)

---

## For Developers

If you're interested in the technical details or contributing:

- **New home**: https://github.com/Bananz0/GalaxyBookEnabler
- **SSSE implementation**: See `Install-SystemSupportEngine` function in `Install-GalaxyBookEnabler.ps1`
- **Issues/PRs**: Please submit to the main GalaxyBookEnabler repository

The patching logic, byte patterns, and installation procedures have been preserved and improved in the new codebase.

---

## Archive Status

- **Archived on**: 15/11/2025
- **Reason**: Merged into GalaxyBookEnabler v3.0.0
- **Future updates**: All development continues in the main repository

---

## Credits

Original SSSE patching research and implementation by the community.  
Now maintained as part of the Galaxy Book Enabler project.

For continued support and the latest features, visit:  
🔗 https://github.com/Bananz0/GalaxyBookEnabler

---

## Quick Links

| Resource | Link |
|----------|------|
| **GalaxyBookEnabler Main Repo** | https://github.com/Bananz0/GalaxyBookEnabler |
| **Latest Release** | https://github.com/Bananz0/GalaxyBookEnabler/releases/latest |
| **Installation Guide** | https://github.com/Bananz0/GalaxyBookEnabler#readme |
| **Issues/Support** | https://github.com/Bananz0/GalaxyBookEnabler/issues |
| **Discussions** | https://github.com/Bananz0/GalaxyBookEnabler/discussions |

---

**This repository is archived and read-only.**  
**All issues, pull requests, and discussions have been moved to GalaxyBookEnabler.**
