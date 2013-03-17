#!/bin/bash

#seg=/usr/local/mmseg3/bin/mmseg
dicpath=/usr/local/mmseg3/etc/

function get_http_txt_encoded () {
  tmp_get_http_txt_encoded=$(mktemp)
	wget -q -O- --header\="Accept-Encoding: gzip" $1 | gunzip > $tmp_get_http_txt_encoded
	cat $tmp_get_http_txt_encoded
	}
	
function get_http_txt_raw () {
	tmp_get_http_txt_raw=$(mktemp)
	wget -q -O- $1 > $tmp_get_http_txt_raw
	cat $tmp_get_http_txt_raw 
	}

function get_http_txt_main () {
	if [[ "$(check_svr_encoding $1)" == "Encoded" ]]
	then
		get_http_txt_encoded $1
	else
		get_http_txt_raw $1
	fi
	}

function check_svr_encoding () {
	wgettmp=$(mktemp)
	wget -o $wgettmp -S $1
	if [[ $(cat $wgettmp |grep -o -i 'Content-Encoding') == "Content-Encoding" ]]
	then
		echo "Encoded"
	else
		echo "Raw"
	fi
	}

function rm_html () {
	grep -o '>[^<>]*<' $1	|sed '/></d;s/>//g;s/<//g;s/ *//g;/^[a-z0-9A-Z]*$/d' 
	}

function check_file_format () {
	check_file_format_f=$(cat $1 |egrep -m 1 -i -o '<meta[^>]*charset[^>]*' |egrep -i -o -m 1 'utf-8|gbk|gb2312')
	check_file_format_fmt=$(echo $check_file_format_f |tr '[:lower:]' '[:upper:]')
	}
	
function tr_file_format () {
	check_file_format $1
	if [[ "$check_file_format_fmt" != "UTF-8" ]];  
		then
			cat $1 |iconv -c -f "$check_file_format_fmt" -t "UTF-8" |tr -d '\015'
		else
			cat $1
	fi
}

function seg_txt () {
	tmp_seg_txt=$(mktemp)	
	mmseg -d $dicpath $1\
	|sed 's=/x =\n=g;s=/s =\n=g'\
	|sed 's/[[:blank:]]//g;s/[[:punct:]]//g;/^$/d'\
	|sed '/^$/d;/^[a-zA-Z0-9]*$/d'\
	|sort|uniq -c |sort -k1n > $tmp_seg_txt
	cat $tmp_seg_txt
	echo "Keyword Variety:"$(cat $tmp_seg_txt|wc -l)
}

function seg_main () {
	tmp_seg_main=$(mktemp)
	tmp2_seg_main=$(mktemp)
	get_http_txt_main $1 > $tmp_seg_main #检测服务器是否加密，采取对应function获取文件
	tr_file_format $tmp_seg_main > $tmp2_seg_main #检测文件编码，如果不是UTF-8，则转换之
	#rm_html $tmp2_seg_main > $tmp_seg_main #移除HTML代码，只保留文本
	seg_txt $tmp2_seg_main
	rm /tmp/tmp.*
	}
	
function check_page_status () {
	t=$(mktemp)
	wget -q -S --spider -o $t $1 
	grep HTTP $t |cut -d" " -f4
}
