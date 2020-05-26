#!/bin/sh

#标志变量
tag=1

function analysis_file(){

log_name=$*

for name in $*
do

if [ -e $name ];then
	echo "$name文件存在"
else
	echo "$name文件有误,请确认日志文件存在" 
	exit -1
fi

done

f_length=$(cat key_word.ini |wc -l)
f_num=$((f_length/2))


#循环开始初始化key_word,err_name,all等变量
key_word=
err_name=
all=0

for(( m=1;m<=$f_num;m++)) 
do
key_word=$key_word","$(cat key_word.ini|sed -n ''$((2*m))'p') 
err_name=$err_name" "$(cat key_word.ini|sed -n ''$((2*m-1))'p')
done


#去除第一个多余字符
key_word=${key_word:1}
err_name=${err_name:1}


#key_word和err_name的类型数量需要保持一致,keyword在配置文件config.ini中修改,同类型不通的配置文件用|隔开

num=$(echo $key_word | awk -F '[,|]' '{print NF}')
echo "目标文件为"$log_name
echo "分析生成文件为当前目录下"${log_name%.*}"_analysis.log"

if [ $tag == 1 ];then
echo "关键词数量为"$num
echo "关键词为"$key_word
tag=0
fi


#保存旧的分隔符
OLD_IFS="$IFS"
IFS=","
array=(${key_word}) 
#恢复旧的分隔符
IFS=$OLD_IFS
err_name=(${err_name})


for(( i=0;i<${#array[@]};i++)) 
do
	OLD_IFS="$IFS"
	IFS="|"
	key=(${array[i]})
	IFS=$OLD_IFS
	
	echo "${err_name[$i]}" >> ${log_name%.*}"_analysis".log
	error_time=0
	tmp=0
		#for key_name in ${key[@]}
		for(( j=0;j<${#key[@]};j++)) 
		do
			
			if [ "$j" -eq "1" ];then
			echo "-----" >> ${log_name%.*}"_analysis".log
			fi
			
			tmp=$error_time
			
			error_data=$(cat $log_name | grep -i -C 1 -E "${key[j]}" )
			error_line=$(echo "${error_data}" | grep -E "${key[j]}" | head -1)
			error_time=$(cat $log_name | grep -c -E "${key[j]}" )
			
			if [ $error_time != 0 ];then
			echo "${key[j]}  关键字匹配次数" >> ${log_name%.*}"_analysis".log
			echo $error_time >> ${log_name%.*}"_analysis".log	
			echo "第一次关键字行" >> ${log_name%.*}"_analysis".log
			echo $error_line >> ${log_name%.*}"_analysis".log
			echo "所有关键字行及上下文" >> ${log_name%.*}"_analysis".log
			cat $log_name | grep -i -C 1 -E "${key[j]}" >> ${log_name%.*}"_analysis".log	
			fi
			
			sum=$[tmp+error_time]
			
			
			#各关键词次数打印
			#printf "%-20s\t %-1s %3s \n" "${key[j]}"  :  $error_time
			
		done
		#各问题种类次数打印
		all=$[all+sum]
		
		
		printf "%-20s\t %-1s %3s \n" "${err_name[$i]}"  :  $sum
		if [ $error_time != 0 ];then
		echo "${err_name[$i]}所有关键词匹配次数:$sum" >> ${log_name%.*}"_analysis".log
		echo "*********************************************************************************************" >> ${log_name%.*}"_analysis".log
		fi
		
done

printf "%-20s\t %-1s %3s \n" "All"  :  $all

if [ $all == 0 ];then
	return 0
else
	return 1
fi

}

function read_dir(){
for file in `ls $1` #注意此处这是两个反引号，表示运行系统命令
do
 if [ -d $1"/"$file ];then
 read_dir $1"/"$file
 else
 echo $1"/"$file #在此处处理文件即可
 
 logfile=$1"/"$file
 
 analysis_file $logfile
 
 fi
done
} 

#读取第一个参数
function usage()
{
echo "usage:"
echo "1 sh analysis.sh 目录名"
echo "2 sh analysis.sh 文件名"
echo "2 sh analysis.sh 文件名1 文件名2 ..."
}

#判断参数为非空
if [ $# == 0 ];then
    echo "参数为空,请重新输入"
	usage
	exit -1
fi

#判断参数为真实文件
if [ -d $1 ]
then
    echo "分析$1目录下所有的日志文件"
	read_dir $1
elif [ -f $1 ]
then
    echo "分析$1单个文件"
	analysis_file $*
else
    echo "输入文件或目录有误,请重新输入"
	usage
	exit -1
fi
