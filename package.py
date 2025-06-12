import os
import subprocess
import sys
import requests


ARCHES = ('x86_64', 'arm64')
CONTENTS_DIR = 'build/src/Fcitx5Installer.app/Contents'
RESOURCES_DIR = f'{CONTENTS_DIR}/Resources'
EXECUTABLE_DIR = f'{CONTENTS_DIR}/MacOS'
EXECUTABLE = f'{EXECUTABLE_DIR}/Fcitx5Installer'
REGISTER_IM = 'build/im/register_im'
ENABLE_IM = 'build/im/enable_im'
PLUGINS_DIR = f'{RESOURCES_DIR}/plugins'
CONFIG_DIR = f'{RESOURCES_DIR}/config'


def sh(command: str):
    print(command)
    assert os.system(command) == 0


def dollar(command: str):
    return subprocess.check_output(command, shell=True, text=True).strip()


def download(url: str, key: str, path: str):
    cache_path = f'cache/{key}'
    if os.path.exists(cache_path):
        print(f'Using cached {key}')
    else:
        print(f'Downloading {key}')
        sh(f'curl -L -o {cache_path} {url}')
    sh(f'cp {cache_path} {path}')

def write_meta(tag: str):
    edition = sys.argv[2] if len(sys.argv) >= 3 else ''

    api_prefix = 'https://api.github.com/repos/fcitx-contrib/fcitx5-macos'

    headers = {}
    token = os.getenv('GITHUB_TOKEN')
    if token:
        headers['Authorization'] = f'token {token}'

    if tag == 'latest':
        # latest_commit = {'object': {'sha': '47ee7b4367198da8bc2e09bee183e846d68ca3e6'}}
        latest_commit = requests.get(f'{api_prefix}/git/ref/tags/latest', headers=headers).json()
        commit = latest_commit['object']['sha']
    else:
        commit = ''

    # latest_release = {'published_at': '2024-03-14T11:42:45Z'}
    latest_release = requests.get(f'{api_prefix}/releases/tags/{tag}', headers=headers).json()
    date = latest_release['published_at']

    with open('src/meta.swift', 'w') as f:
        f.write(f'let edition = "{edition}"\n')
        f.write(f'let releaseTag = "{tag}"\n')
        f.write(f'let commit = "{commit}"\n')
        f.write(f'let date = "{date}"\n')


def build():
    sh(f'mkdir -p "{RESOURCES_DIR}"')
    for arch in ARCHES:
        print(f'Building {arch}')
        sh(f'cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES={arch}')
        sh('cmake --build build')
        for exe in (EXECUTABLE, REGISTER_IM, ENABLE_IM):
            sh(f'mv {exe} {exe}-{arch}')
    print('Generating universal')
    sh(f'lipo -create {EXECUTABLE}-x86_64 {EXECUTABLE}-arm64 -output {EXECUTABLE}')
    sh(f'lipo -create {REGISTER_IM}-x86_64 {REGISTER_IM}-arm64 -output {RESOURCES_DIR}/register_im')
    sh(f'lipo -create {ENABLE_IM}-x86_64 {ENABLE_IM}-arm64 -output {RESOURCES_DIR}/enable_im')
    for arch in ARCHES:
        sh(f'rm {EXECUTABLE}-{arch}')

    sh(f'cp assets/fcitx.icns "{RESOURCES_DIR}"')

    for name in os.listdir('assets'):
        if name.endswith('.lproj'):
            sh(f'cp -r assets/{name} "{RESOURCES_DIR}"')

    sh(f'cp install.sh "{RESOURCES_DIR}"')
    sh(f'rm -f "${EXECUTABLE_DIR}/Fcitx5Installer.d"')


def download_fcitx5(tag: str):
    for arch in ARCHES:
        name = f'Fcitx5-{arch}.tar.bz2'
        url = f'https://github.com/fcitx-contrib/fcitx5-macos/releases/download/{tag}/{name}'
        download(url, name, f'{RESOURCES_DIR}/{name}')


PROFILE_HEADER = '''
[Groups/0]
Name=Default
Default Layout=us
DefaultIM={0}
'''

PROFILE_ITEM = '''
[Groups/0/Items/{0}]
Name={1}
Layout=
'''

PROFILE_TAIL = '''
[GroupOrder]
0=Default
'''


def download_plugins(tag: str):
    if len(sys.argv) < 4:
        return
    plugins = sys.argv[3].split(',')
    sh(f'mkdir -p {PLUGINS_DIR}')
    for plugin in plugins:
        for arch in ARCHES + ('any',):
            name = f'{plugin}-{arch}.tar.bz2'
            url = f'https://github.com/fcitx-contrib/fcitx5-plugins/releases/download/macos-{tag}/{name}'
            download(url, name, f'{PLUGINS_DIR}/{name}')


def generate_profile():
    '''
    Set default input methods
    '''
    if len(sys.argv) < 5:
        return
    sh(f'mkdir -p {CONFIG_DIR}')
    input_methods = sys.argv[4].split(',')
    body = ''.join(PROFILE_ITEM.format(i, im) for i, im in enumerate(['keyboard-us', *input_methods]))
    with open(f'{CONFIG_DIR}/profile', 'w') as f:
        f.write(PROFILE_HEADER.format(input_methods[0]) + body + PROFILE_TAIL)


ACTIVE_BY_DEFAULT = '''
[Behavior]
ActiveByDefault=True
'''


def generate_config():
    '''
    Set "Active by default"
    '''
    if len(sys.argv) < 6:
        return
    if sys.argv[5] != 'true':
        return
    with open(f'{CONFIG_DIR}/config', 'w') as f:
        f.write(ACTIVE_BY_DEFAULT)


def make_zip():
    os.chdir('build/src')
    sh('zip -r -0 Fcitx5Installer.zip Fcitx5Installer.app')


if __name__ == '__main__':
    tag = sys.argv[1]
    write_meta(tag)
    build()
    download_fcitx5(tag)
    download_plugins(tag)
    generate_profile()
    generate_config()
    make_zip()
