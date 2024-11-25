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

## pipx {id="pipx_1"}
### pipx 설치 (pip 19.0+) {id="pipx_1_1"}
```bash
python.exe -m pip install --upgrade pip
pip --version

python -m pip install pipx
python -m pipx list

python -m pip install --upgrade pipx
```

## Poetry {id="poetry_1"}
### Poetry 설치 (pipx & Python 3.8+) {id="poetry_1_1"}
```bash
python -m pipx install poetry
python -m pipx upgrade poetry
poetry init
```
#### without pipx {id="poetry_1_1_1"}
```bash
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
```
or 
```Bash
# Recommended (with venv)
pip install poetry
```

### poetry 업데이트 {id="poetry_1_2"}
```bash
poetry self update
```

### poetry 사용법 {id="poetry_1_3"}
```bash
# 프로젝트 생성 (디렉터리 생성)
poetry new <project_name>
# 프로젝트 생성 (현재 디렉터리)
poetry init
# 패키지 추가
poetry add <package_name>
poetry add <package_name>@<version>
# 개발 패키지 추가
poetry add --dev <package_name>
# 패키지 삭제
poetry remove <package_name>
# 패키지 업데이트
poetry update
# 패키지 리스트
poetry show
# 패키지 리스트 (tree)
poetry show --tree
# 패키지 리스트 (최신 버전)
poetry show --latest
# 패키지 리스트 (업데이트 가능)
poetry show --outdated
# 패키지 리스트 (개발용 의존성 제외)
poetry show --no-dev
# 의존성 내보내기
poetry export -f requirements.txt --output requirements.txt
# 의존성 내보내기 (해시 제외)
poetry export -f requirements.txt --output requirements.txt --without-hashes
# 의존성 내보내기 (개발의존성 제외)
poetry export -f requirements.txt --output requirements.txt --without-hashes --without dev
# 패키지 설치
poetry install
# 패키지 빌드
poetry build
# 배포
poetry publish
# 패키지 실행
poetry run <command>
# 가상환경 생성
poetry shell
# 가상환경 삭제
poetry env remove <python_version>
# 가상환경 리스트
poetry env list
# 가상환경 활성화
poetry env use <python_version>
# 가상환경 비활성화 
deactivate
```

### pyproject.toml 예시 {id="poetry_1_4"}
```toml
[tool.poetry]
name = "project_name"
version = "0.1.0"
description = ""
authors = ["author_name <author_email>"]
license = "MIT"
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.12"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```
