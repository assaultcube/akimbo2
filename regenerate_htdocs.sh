#!/bin/bash

function maxquality { # maxquality val filename
  if [ -r $2 ] ; then
    curq=$(identify -format "%Q" $2)
    if [ $curq -gt $1 ] ; then
      mogrify -quality $1 $2
    fi
  fi
}

targets="htdocs htdocs/q60 htdocs/q80"

# set working directory to the location of the script
cd $(dirname "$(readlink -f "${0}")")

# cleanup
rm -Rf temp htdocs

# create map zip files
mkdir -p temp/packages/maps
for t in $targets ; do mkdir -p $t/packages/maps ; done
cd unpacked/packages/maps
for file in *.cgz ; do 
  echo creating packages/maps/$file.zip
  t=${file%.cgz}.cfg
  if [ -r $t ] ; then 
    zip -9 ../../../temp/packages/maps/$file.zip $file $t
  else
    zip -9 ../../../temp/packages/maps/$file.zip $file
  fi
done
cd ../../..
for t in $targets ; do cp temp/packages/maps/* $t/packages/maps ; done

# copy map sounds
for t in $targets ; do mkdir -p $t/packages/audio/ambience ; done
for t in $targets ; do cp -r unpacked/packages/audio/ambience/* $t/packages/audio/ambience ; done

# create skymap zips
for t in $targets ; do mkdir -p $t/packages/textures/skymaps ; done
mkdir -p temp/packages/textures
mkdir -p temp/tmp
cp -r unpacked/packages/textures/* temp/packages/textures
cd temp
skymapparts="lf rt ft bk dn up"
for file in $(find packages/textures/skymaps -name "*_ft.jpg" -type f) ; do
  echo creating ${file%_ft.jpg}.zip
  for t in $targets ; do mkdir -p ../$t/$(dirname $file) ; done

  # full quality (if it fits in one megabyte, otherwise reduce to 95%)
  touch tmp/dummy
  rm tmp/*
  for t in $skymapparts ; do cp ${file%ft.jpg}$t.jpg tmp ; done
  if [ -r ${file%ft.jpg}_license.txt ] ; then
    cp ${file%ft.jpg}_license.txt tmp
  fi
  zip -9 -j tz.zip tmp/*
  if [ $(cat tz.zip | wc -c) -ge 1024000 ] ; then
    for t in tmp/*.jpg ; do maxquality 95 $t ; done
  fi
  rm tz.zip
  zip -9 -j ../htdocs/${file%_ft.jpg}.zip tmp/*

  # q80
  for t in $skymapparts ; do cp ${file%ft.jpg}$t.jpg tmp ; done
  for t in tmp/*.jpg ; do maxquality 80 $t ; done
  zip -9 -j ../htdocs/q80/${file%_ft.jpg}.zip tmp/*

  # q60
  for t in $skymapparts ; do cp ${file%ft.jpg}$t.jpg tmp ; done
  for t in tmp/*.jpg ; do maxquality 60 $t ; done
  zip -9 -j ../htdocs/q60/${file%_ft.jpg}.zip tmp/*
done
cd ..
rm -Rf temp/packages/textures/skymaps

# copy full quality textures
echo copy full quality textures
mkdir -p htdocs/packages/textures
cp -r temp/packages/textures/* htdocs/packages/textures

# create q60 textures
echo create q60 textures
mkdir -p htdocs/q60/packages/textures
cp -r temp/packages/textures/* htdocs/q60/packages/textures
for file in $(find htdocs/q60/packages/textures -name "*.jpg" -type f) ; do
  maxquality 60 $file
done

# create q80 textures
echo create q80 textures
mkdir -p htdocs/q60/packages/textures
cp -r temp/packages/textures/* htdocs/q80/packages/textures
for file in $(find htdocs/q80/packages/textures -name "*.jpg" -type f) ; do
  maxquality 80 $file
done

# create mapmodel zips
for t in temp $targets ; do mkdir -p $t/packages/models/mapmodels ; done
cp -r unpacked/packages/models/* temp/packages/models
cd temp
for file in $(find packages/models/mapmodels -name "*.cfg" -type f) ; do
  p=$(dirname $(dirname $file))
  fn=$(basename $(dirname $file))
  echo creating $p/$fn.zip
  for t in $targets ; do mkdir -p ../$t/$p ; done

  # get all appropriate files
  touch tmp/dummy
  rm tmp/*
  for t in $(dirname $file)/* ; do
    case $t in
      *.md2|*.md3|*.cfg|*.txt|*.jpg|*.png)
        cp $t tmp
        ;;
      *)
        echo ignore $t
        ;;
    esac
  done

  # full quality (if it fits in one megabyte, otherwise reduce jpegs to 95%)
  zip -9 -j tz.zip tmp/*
  if [ $(cat tz.zip | wc -c) -ge 1024000 ] ; then
    for t in tmp/*.jpg ; do maxquality 95 $t ; done
  fi
  zip -9 -j ../htdocs/$p/$fn.zip tmp/*

  # q80
  rm tmp/*
  unzip tz.zip -d tmp
  for t in tmp/*.jpg ; do maxquality 80 $t ; done
  zip -9 -j ../htdocs/q80/$p/$fn.zip tmp/*

  # q60
  rm tmp/*
  unzip tz.zip -d tmp
  for t in tmp/*.jpg ; do maxquality 60 $t ; done
  zip -9 -j ../htdocs/q60/$p/$fn.zip tmp/*

  rm tz.zip
done
cd ..


