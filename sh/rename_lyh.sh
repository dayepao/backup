#!/bin/bash
listchange(){
    while read oldmd51 oldmd52
    do
        while read newmd51 newmd52
        do
            if [ ${oldmd51} == ${newmd51} ];then
                echo -e "${oldmd52} \033[32;1m >>> \033[0m ${newmd52}"
                break 1
            fi
        done < ${rootpath}/${videoname}_${season:0-2}_new.txt
    done < ${rootpath}/${videoname}_${season:0-2}_old.txt
}

checkmd5(){
    stopkeys=$(sed -n '$=' ${rootpath}/${videoname}_${season:0-2}_new.txt)
    losekey=0
    IFS=$'  '
    while read oldmd51 oldmd52
    do
        stopkey=0
        while read newmd51 newmd52
        do
            if [ ${oldmd51} == ${newmd51} ];then
                break 1
            else
                stopkey=$(($stopkey+1))
            fi
            if [ ${stopkey} -ge ${stopkeys} ];then
                echo -e "\033[31;1m [警告] \033[0m ${oldmd52} 可能已经丢失"
                losekey=1
            fi
        done < ${rootpath}/${videoname}_${season:0-2}_new.txt
    done < ${rootpath}/${videoname}_${season:0-2}_old.txt
    if [ ${losekey} == 1 ] || [ ${failurekey} == 1 ];then
        listchange
    fi
    IFS=$'\r\n'
}

deleteuseless(){
    rm -rf *.torrent
    rm -rf *.txt
    rm -rf *.srt
    rm -rf *.ass
    rm -rf *.ssa
    rm -rf *.nfo
    rm -rf *.jpg
    rm -rf *.png
}

filerename(){
    oldfiles=$(ls $folder)
    for oldfile in $oldfiles
    do
        newfile=$(echo $oldfile | sed "s/BDE4//g")
        newfile=$(echo $newfile | sed "s/(//g")
        newfile=$(echo $newfile | sed "s/)//g")
        newfile=$(echo $newfile | sed "s/\ //g")
        newfile=$(echo $newfile | sed "s/M/m/g")
        newfile=$(echo $newfile | sed "s/E/e/g")
        newfile=$(echo $newfile | sed "s/P/p/g")
        newfile=$(echo $newfile | sed "s/ep/e/g")
        newfile=$(echo $newfile | sed "s/S/s/g")
        newfile=$(echo $newfile | sed "s/sp/e/g")
        newfile=$(echo $newfile | sed "s/e/e0/g")
        newfile=$(echo $newfile | sed "s/00/0/g")
        newfilekey=10
        while [ ${newfilekey} -lt '100' ]
        do
            newfile=$(echo $newfile | sed "s/0${newfilekey}/${newfilekey}/g")
            newfilekey=$((${newfilekey}+1))
        done
        if [ "${oldfile}" != "${newfile}" ] && [ "${oldfile}" != "$0" ] && [ "${oldfile}" != "rename_lyh" ];then
            mv "${oldfile}" "${newfile}"
        fi
    done
}

file_rename_2_0(){
    oldfiles=$(ls $folder)
    for oldfile in $oldfiles
    do
        echo $oldfile
    done
}


rename_1_0(){
    filerename
    filenames=$(ls $folder)
    for filename in $filenames
    do
        j=1
        while :
        do
            if [ $j -lt '10' ];then
                jj="0${j}"
                if [[ ${filename} =~ "e${jj}" ]];then
                mv "${filename}" "${jj}.mp4"
                break 1
                fi
            elif [ $j -lt '100' ];then
                if [[ ${filename} =~ "e${j}" ]];then
                mv "${filename}" "${j}.mp4"
                break 1
                fi
            else
                echo -e "\033[31;1m [失败] \033[0m${filename}"
                break 1
            fi
            j=$(($j+1))
        done
    done
}


rename_2_0(){
    cd rename_lyh
    rootpath=$(pwd)
    deleteuseless
    videonames=$(ls $folder)
    for videoname in $videonames
    do
        cd "${videoname}"
        deleteuseless
        seasons=$(ls $folder)
        for season in $seasons
        do
            echo "正在处理 ${videoname}/${season}"
            cd "${season}"
            deleteuseless
            find ./ -type f -print0 | xargs -0 md5sum | sort >${rootpath}/${videoname}_${season:0-2}_old.txt
            filerename
            filenames=$(ls $folder)
            failurekey=0
            if [ ${season} == "Specials" ];then
                SXX="SP"
                for filename in $filenames
                do
                    j=1
                    while :
                    do
                        if [ $j -lt '10' ];then
                            jj="0${j}"
                            if [[ ${filename} =~ "e${jj}" ]];then
                                mv "${filename}" "${videoname} ${SXX}${jj}.mp4"
                                break 1
                            elif [[ ${filename} =~ "${jj}.mp4" ]] || [[ ${filename} =~ "${jj}.mkv" ]];then
                                mv "${filename}" "${videoname} ${SXX}${jj}.mp4"
                                break 1
                            fi
                        elif [ $j -lt '100' ];then
                            if [[ ${filename} =~ "e${j}" ]];then
                                mv "${filename}" "${videoname} ${SXX}${j}.mp4"
                                break 1
                            elif [[ ${filename} =~ "${j}.mp4" ]] || [[ ${filename} =~ "${j}.mkv" ]];then
                                mv "${filename}" "${videoname} ${SXX}${j}.mp4"
                                break 1
                            fi
                        else
                            echo -e "\033[31;1m [失败] \033[0m${videoname}/${season}/${filename}"
                            failurekey=1
                            break 1
                        fi
                        j=$(($j+1))
                    done
                done
            else
                SXX="S${season:0-2}"
                for filename in $filenames
                do
                    j=1
                    while :
                    do
                        if [ $j -lt '10' ];then
                            jj="0${j}"
                            if [[ ${filename} =~ "e${jj}" ]] || [[ ${filename} =~ "[${jj}]" ]];then
                                mv "${filename}" "${videoname} ${SXX}E${jj}.mp4"
                                break 1
                            elif [[ ${filename} =~ "${jj}.mp4" ]] || [[ ${filename} =~ "${jj}.mkv" ]];then
                                mv "${filename}" "${videoname} ${SXX}E${jj}.mp4"
                                break 1
                            fi
                        elif [ $j -lt '100' ];then
                            if [[ ${filename} =~ "e${j}" ]] || [[ ${filename} =~ "[${j}]" ]];then
                                mv "${filename}" "${videoname} ${SXX}E${j}.mp4"
                                break 1
                            elif [[ ${filename} =~ "${j}.mp4" ]] || [[ ${filename} =~ "${j}.mkv" ]];then
                                mv "${filename}" "${videoname} ${SXX}E${j}.mp4"
                                break 1
                            fi
                        else
                            echo -e "\033[31;1m [失败] \033[0m${videoname}/${season}/${filename}"
                            failurekey=1
                            break 1
                        fi
                        j=$(($j+1))
                    done
                done
            fi
            find ./ -type f -print0 | xargs -0 md5sum | sort >${rootpath}/${videoname}_${season:0-2}_new.txt
            checkmd5
            cd ..
        done
        cd ..
        echo -e "\033[32;1m [完成] \033[0m${videoname}"
    done
    deleteuseless
}


startrename(){
    echo "1.在当前目录执行重命名（xx.mp4）"
    echo "2.对 rename_lyh 文件夹中的剧集进行批量重命名。（格式：rename_lyh/剧名/Season 00/剧名 S00E00.mp4）"
    echo "0.退出"
    IFS_OLD=$IFS
    while :
    do
        read -p "请选择：" key
        case ${key} in
            1)
                IFS=$'\r\n'
                rename_1_0
                break 1
                ;;
            2)
                IFS=$'\r\n'
                rename_2_0
                break 1
                ;;
            0)
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
    IFS=$IFS_OLD
}


if [ -d "rename_lyh" ];then
    echo ""
    echo ""
    startrename
else
    mkdir rename_lyh
    chmod 777 rename_lyh
    echo ""
    echo ""
    echo -e "你似乎是第一次运行此脚本，已在当前目录创建\033[32;1m rename_lyh \033[0m文件夹"
    echo -e "请将要重命名的剧集按照\033[32;1m rename_lyh/剧名/Season 00/视频文件 \033[0m的格式放入\033[32;1m rename_lyh \033[0m文件夹中"
    echo ""
    echo ""
    startrename
fi
