#!/bin/bash
#/bin/bash
 
next(){
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}
 
 
_blue() {
    printf '\033[0;31;36m%b\033[0m' "$1"
}
 
#磁盘测试，各项均测试一次
fio_test() {
    _blue "测试磁盘\n"
    next   
    rpm -ql fio &> /dev/null
    [[ $? != 0 ]] && yum -y install fio
    target=$1
    [[ $target ]] || target='/dev/sdb'
    if  [[ ! -b $target ]];then
    echo '目标磁盘不存在'
    exit
    fi
 
    _blue "随机读IOPS\n"
    fio -bs=4k -ioengine=libaio -iodepth=32 -direct=1 -rw=randread -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-randread-iops --size=1G -filename=${target} --runtime=30s   
    _blue "随机写IOPS\n"
    fio -bs=4k -ioengine=libaio -iodepth=32 -direct=1 -rw=randwrite -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-randwrite-iops --size=10G -filename=${target} --runtime=30s
 
    _blue "随机读时延\n"
    fio -bs=4k -ioengine=libaio -iodepth=1 -direct=1 -rw=randread -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-randread-lat --size=10G  --runtime=30s  -filename=${target}
 
 
    _blue "随机写时延\n"
    fio -bs=4k -ioengine=libaio -iodepth=1 -direct=1 -rw=randwrite -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-randwrite-lat --size=10G --runtime=30s -filename=${target}
 
    _blue "随机读带宽\n"
    fio -bs=128k -ioengine=libaio -iodepth=32 -direct=1 -rw=read -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-read-throughput --size=10G --runtime=30s -filename=${target}
 
    _blue "随机写带宽\n"
    fio -bs=128k -ioengine=libaio -iodepth=32 -direct=1 -rw=write -time_based -runtime=600  -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-write-throughput --size=10G --runtime=30s -filename=${target}
}
 
#cpu测试，测试3次，关键结果：每秒次数
cpu_test(){
    _blue "测试CPU\n"
    next
    rpm -ql sysbench || yum -y install sysbench
    sysbench cpu --cpu-max-prime=20000 --threads=8 --time=50 run
    sysbench cpu --cpu-max-prime=20000 --threads=8 --time=50 run
    sysbench cpu --cpu-max-prime=20000 --threads=8 --time=50 run
}
 
#内存测试，测试1次，关键结果：内存带宽看表格，内存延迟输出的时间
mem_test(){
    next
    _blue "测试内存\n"
    next
    _blue "测试内存带宽\n"
    rpm -ql gcc || yum -y install gcc
    [ -e stream.c ] || wget http://www.cs.virginia.edu/stream/FTP/Code/stream.c && gcc  -march=native -O3 -mcmodel=medium -fopenmp -DSTREAM_ARRAY_SIZE=100000000 -DNTIMES=30 -DOFFSET=4096 stream.c -o stream.o
    ./stream.o
     _blue "测试内存延迟\n"
    [ -e mlc_v3.9.tgz ] || wget https://software.intel.com/content/dam/develop/external/us/en/protected/mlc_v3.9.tgz
    [ -d Linux ] || tar xzf mlc_v3.9.tgz
    num=$(cat /proc/sys/vm/nr_hugepages 2> /dev/null)   
    echo 4000 > /proc/sys/vm/nr_hugepages
    cd Linux && ./mlc --latency_matrix
    echo $num > /proc/sys/vm/nr_hugepages
}
 
#网速测试
net_test(){
    _blue "测试网络\n"
    rpm -ql speedtest || (yum install wget && wget https://bintray.com/ookla/rhel/rpm -O bintray-ookla-rhel.repo && mv bintray-ookla-rhel.repo /etc/yum.repos.d/ && yum -y install speedtest)
    speedtest
}
 
 
read -p '磁盘测试，请输入要测试的磁盘路径' target
fio_test $target
cpu_test
mem_test
