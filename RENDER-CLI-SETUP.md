# Render CLI Installation & Authentication Guide

## Option 1: Manual Download (Recommended for Windows)

1. **Download the latest Render CLI for Windows:**
   - Visit: https://github.com/renderinc/cli/releases
   - Download `render-cli-windows-x86_64.exe` (latest version)

2. **Add to PATH:**
   - Move the downloaded `.exe` to a folder in your PATH, e.g., `C:\Program Files\render\`
   - Or add the folder to your PATH environment variable

3. **Verify installation:**
   ```powershell
   render --version
   ```

## Option 2: Install via Scoop (if available)

```powershell
scoop bucket add extras
scoop install render
```

## Option 3: Use Node.js global script (Alternative)

If the npm package becomes available:
```powershell
npm install -g render
```

---

## Authentication

Once installed, authenticate with Render:

```powershell
render login
```

This will:
1. Open your browser automatically
2. Prompt you to authorize the CLI on Render.com
3. Generate an authentication token
4. Save credentials locally for future use

---

## Verify Authentication

```powershell
render whoami
```

---

## Common Commands

```powershell
# List all services
render services

# View service details
render services info --id <service-id>

# View logs
render logs --id <service-id>

# Deploy manually
render deploy --id <service-id>
```

---

## Troubleshooting

- **"render: command not found"** → Ensure the CLI is in your PATH
- **Authentication issues** → Try `render logout` then `render login` again
- **On Windows** → Use PowerShell as Administrator for best compatibility
