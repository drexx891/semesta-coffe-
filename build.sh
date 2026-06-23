#!/bin/bash
echo "Cloning Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"
echo "Building Flutter Web..."
flutter build web --release
echo "Copying output to public..."
mkdir -p public
cp -r build/web/* public/
