# How to use venv (In Windows)

## Creating
```bash
python -m venv .venv
```

## Accessing
```bash
.venv\Scripts\activate
```

## Install Package
```bash
pip install <name>
```

## Save package list
```bash
pip freeze > requirements.txt
```

## Install package from list
```bash
pip install -r requirements.txt
```

## Exit venv environment
```bash
deactivate
```

## VS Code Integration
1. Press `Ctrl + Shift + P`
2. Select `"Python: Select Interpreter"`
3. Choose the one inside your `.venv` folder (`python.exe`)
