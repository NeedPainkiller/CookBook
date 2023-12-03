# Python
## pyenv {id="pyenv_1"}
### pyenv 설치 {id="pyenv_1_1"}
<tabs>
    <tab title="Windows">
        <a href="https://github.com/pyenv-win/pyenv-win">pyenv-win (Github)</a>
        <code-block lang="shell">
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
        </code-block>
    </tab>
    <tab title="Linux (source)">
        <code-block lang="bash">
            curl https://pyenv.run | bash
            # or
            git clone https://github.com/pyenv/pyenv.git ~/.pyenv
            cd ~/.pyenv && src/configure && make -C src
        </code-block>
    </tab>
    <tab title="Linux (apt)">
        <code-block lang="bash">
            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev
            git clone https://github.com/pyenv/pyenv.git ~/.pyenv
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
            echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
            source ~/.bash_profile
        </code-block>
    </tab>
</tabs>

### Usage {id="pyenv_1_2"}
#### Commands
```bash
pyenv --version
pyenv install -l
pyenv install <version>
pyenv global <version>
pyenv local <version>
pyenv shell <version>
pyenv version
```

## pipx {id="pyenv_2"}
### pipx 설치 (pip 19.0+) {id="pyenv_2_1"}
```bash
python.exe -m pip install --upgrade pip
pip --version

python -m pip install pipx
python -m pipx list

python -m pip install --upgrade pipx
```

## Poetry {id="pyenv_3"}
### Poetry 설치 (Python 3.8+) {id="pyenv_3_1"}
```bash
python -m pipx install poetry
python -m pipx upgrade poetry
poetry init
```