#!/bin/sh

bundle install

npm install

git clone https://github.com/ShadowCrafter011/RailsTranslator.git /RailsTranslator

python3 -m venv /RailsTranslator/venv
/RailsTranslator/venv/bin/pip3 install -r /RailsTranslator/requirements.txt
