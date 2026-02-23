#!/bin/bash

bundle install

npm install

git clone https://github.com/ShadowCrafter011/RailsTranslator.git /RailsTranslator

cd /RailsTranslator
python3 -m venv venv
source venv/bin/activate
pip3 install -r /RailsTranslator/requirements.txt
deactivate
