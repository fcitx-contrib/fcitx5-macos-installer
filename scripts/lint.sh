set -e

swift-format lint -rs im src
ruff check package.py
pyright package.py
