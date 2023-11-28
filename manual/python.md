# Pyenv
## installation
### Windows
- https://github.com/pyenv-win/pyenv-win
```powershell
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
```

### Linux
```bash
curl https://pyenv.run | bash
# or
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv && src/configure && make -C src
```
or
```bash
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
​
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
```

## Usage
### Commands
```bash
pyenv --version
pyenv install -l
pyenv install <version>
pyenv global <version>
pyenv local <version>
pyenv shell <version>
pyenv version
```

# pipx
## installation (requires pip 19.0 or later)
### Windows & Linux 
```bash
python.exe -m pip install --upgrade pip
pip --version

python -m pip install pipx
python -m pipx list

python -m pip install --upgrade pipx
```

# Poetry
## installation (Python 3.8+)
### Windows & Linux 
```bash
python -m pipx install poetry
python -m pipx upgrade poetry
poetry init
```