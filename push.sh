#!/bin/bash
hexo clean;hexo g;hexo s;hexo d;hexo clean;git add .;git commit -m "add article";git push;
