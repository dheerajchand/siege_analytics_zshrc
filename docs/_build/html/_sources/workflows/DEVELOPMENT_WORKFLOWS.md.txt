# 💻 Development Workflows

## 🌐 Modern Web Development

### FastAPI Project
```bash
# Setup modern Python
setup_uv
mkdir my_api && cd my_api
uv init --python 3.12
uv add fastapi uvicorn sqlalchemy

# Development
uv run uvicorn main:app --reload
```

### Full-Stack Development  
```bash
# Backend (Python)
setup_pyenv
pyenv activate web_backend

# Frontend (Node.js) - automatic via NVM
nvm use 18
npm install

# Containerization
# Docker functions available via docker.zsh
```

## 🐳 Docker Integration

Load Docker module on-demand:
```bash
# Docker functions from docker.zsh (4.8K lines)
# Container management, development workflows
```

## 🔄 Multi-Environment Development

```bash
# Terminal 1: Data Science
setup_pyenv && pyenv activate geo31111
load_big_data && jupyter_spark 8889

# Terminal 2: Web API
setup_uv && cd ~/projects/api  
uv run uvicorn main:app

# Terminal 3: DevOps
# Docker and utilities available
```
