#!/bin/bash

echo `date`

msg="update blog"
if [ $# -lt 1 ]; then
    msg=$1
fi


qrsync qiniu-images.conf

cd _posts

grep '/style/images' */* |sed  's/\/style\/images/http:\/\/jc\-resource\.qiniudn\.com\/images/g'
cd ..

rm -rf _site/*
jekyll build

git add --all ./*
git commit -m "$msg"
git push origin master

rm -rf ../javachen.gitcafe.com/{20*,page*,*.html,*.xml,*.txt,*.sh}
cp -r _site/* ../javachen.gitcafe.com/

cd ../javachen.gitcafe.com
git add --all ./*
git commit -m "$msg"
git push origin gitcafe-pages

echo `date`
exit 0