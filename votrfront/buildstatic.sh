#!/bin/bash

set -e

if [ "${1:0:6}" == "--env=" ]; then
  source "${1:6}/bin/activate"
  shift
fi

cd "$(dirname "$0")"

! [ -w "$HOME" ] && echo "HOME is not writable" && exit 1

if [ "$1" == "build" ] || [ "$1" == "" ]; then

  mkdir -p static/libs/ static/cache/
  rm -f static/ok

  yarn --cwd=.. install

  cp -p ../node_modules/jquery/dist/jquery.* static/libs/
  cp -p ../node_modules/lodash/lodash.{min.,}js static/libs/
  cp -p ../node_modules/react/umd/react.development.js static/libs/react.js
  cp -p ../node_modules/react/umd/react.production.min.js static/libs/react.min.js
  cp -p ../node_modules/react-dom/umd/react-dom.development.js static/libs/react-dom.js
  cp -p ../node_modules/react-dom/umd/react-dom.production.min.js static/libs/react-dom.min.js
  cp -p ../node_modules/prop-types/prop-types*.js static/libs/
  cp ../node_modules/file-saver/FileSaver*.* static/libs/

  bs=../node_modules/bootstrap-sass/assets
  if ! [ -f static/libs/modal.js ]; then
    cp $bs/javascripts/bootstrap/*.js static/libs/
  fi

  if ! [ -f static/_spinner.scss ]; then
    node -e 'console.log("$spinner: url(data:image/svg+xml," + escape(require("fs").readFileSync("css/spinner.svg", "ascii")) + ");")' > static/_spinner.scss
  fi

  sed -i "
    # Don't use pointer cursor on buttons.
    # http://lists.w3.org/Archives/Public/public-css-testsuite/2010Jul/0024.html
    s@cursor: pointer; // 3@@
    # Don't inherit color and font on inputs and selects.
    s@color: inherit; // 1@@
    s@font: inherit; // 2@@
    " $bs/stylesheets/bootstrap/_normalize.scss

  compressed='-s compressed'
  sassc $compressed -I $bs/stylesheets -I static css/main.scss static/style.css

  rm -f static/votr.min.js.*.map
  yarn webpack --mode=production --progress --display=minimal

  libs='libs/jquery.min.js libs/react.min.js libs/react-dom.min.js libs/prop-types.min.js libs/lodash.min.js libs/transition.js libs/modal.js libs/FileSaver.min.js'
  echo prologue.min.js ${libs//.min} votr.min.js > static/jsdeps-dev
  echo prologue.min.js $libs votr.min.js > static/jsdeps-prod

  touch static/ok

elif [ "$1" == "clean" ]; then

  rm -rf node_modules ../node_modules static

else
  echo "usage: $0 [--env=path/to/venv] [build|clean]"
  exit 1
fi
