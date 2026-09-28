# How to use venv (In Windows)

## Server Setup Workflow
**To avoid installing libraries globally, follow these steps:**

```bash
# 1. Navigate to the server directory
cd ./Server

# 2. Create a virtual environment
python -m venv .venv

# 3. Activate the environment
.venv\Scripts\activate
# Your terminal should look like this:
# (.venv) [path]/Server

# 4. Install dependencies
pip install -r requirements.txt

# 5. Run the server
python ./Main.py

# 6. Test the APIs at:
# http://127.0.0.1:8000/docs#/

# 7. Exit the environment
deactivate
```

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
