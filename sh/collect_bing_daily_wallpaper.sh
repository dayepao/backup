#!/bin/bash
sudo python3 /root/bingHD.py
rsync -avzhP --update /onedrive/resource/photo/bing/ /www/wwwroot/img.dayepao.com/img/bing/
rsync -avzhP --update /onedrive/resource/photo/bingHD/ /www/wwwroot/img.dayepao.com/img/bingHD/