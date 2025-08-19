# SonarQube API Enum (simple)

Tiny bash script to check which SonarQube `/api/*` endpoints are accessible **without** authentication.  
It reads endpoints from a file, hits each one, and writes a small CSV summary.

No fuss. Just `curl`.

## Why
SonarQube exposes a big API surface. Some endpoints are publicly readable depending on config/version.  
This script helps you quickly see what's open (HTTP 200) vs requires auth (401/403).

## Usage

```bash
git clone https://github.com/<you>/sonarqube-api-enum.git
cd sonarqube-api-enum
chmod +x sonarqube_api_enum_simple.sh

# endpoints file: one endpoint per line, e.g.
# /api/system/status
# /api/server/version
# /api/projects/search

./sonarqube_api_enum_simple.sh https://sonar.example.com endpoints.txt
```
## Output:

* Per-endpoint body/headers under sonarqube_api_enum_results/
* summary.csv with: endpoint,status,http_code,bytes

Example console output:
```bash
[*] /api/system/status               -> OPEN          (code=200, bytes=42)
[*] /api/users/search                -> AUTH_REQUIRED (code=401, bytes=0)

[*] Summary:
    OPEN (200):        1
    AUTH_REQUIRED:     1
    OTHER:             0
```

