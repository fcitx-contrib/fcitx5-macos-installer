swift-format format --in-place $(find im src -name '*.swift')
ruff check --fix package.py
