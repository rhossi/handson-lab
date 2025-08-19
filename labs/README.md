Here’s a ready-to-copy block for your `README.md`:

````markdown
## Getting Started with uv

Follow these steps to download the project and set it up using [uv](https://github.com/astral-sh/uv):

### 1. Install `uv`
```bash
pipx install uv
# or
pip install uv
````

Verify installation:

```bash
uv --version
```

### 2. Clone the repository

```bash
git clone https://github.com/rhossi/handson-lab.git
cd handson-lab
```

### 3. Create a virtual environment

```bash
uv venv
```

### 4. Activate the environment

* **Linux/macOS**

  ```bash
  source .venv/bin/activate
  ```

* **Windows (Powershell)**

  ```powershell
  .venv\Scripts\Activate.ps1
  ```

### 5. Install dependencies

```bash
uv pip install -e .
```

### 6. Run the labs

To execute Lab 1: Open Lab 1 [README.md](./lab-1/README.md)

To execute Lab 2: Open Lab 2 [README.md](./lab-2/README.md)

```
