#!/bin/sh
## xbootimg.sh 0.01 jbgg ##



# bcxx 'operation'
bcxx()
{
	echo "$*" | awk '{print "obase=16;ibase=16;" toupper($0)}' | bc | awk 'NR==1{print tolower($0)}'
}

# bcdd 'operation'
bcdd()
{
	echo "$*" | bc
}

# bcxd 'operation'
bcxd()
{
	echo "$*" | awk '{print "obase=10;ibase=16;" toupper($0)}' | bc
}

# bcdx 'operation'
bcdx()
{
	echo "obase=16;ibase=10; $*" | bc | awk 'NR==1{print tolower($0)}'
}

# read8 file [-j offset]
read8()
{
	od -t x1 -N 1 $* | awk 'NR==1{print $2}'
}

# read16 file [-j offset]
read16()
{
	od --endian=little -t x2 -N 2 $* | awk 'NR==1{print $2}'
}

# read32 file [-j offset]
read32()
{
	od --endian=little -t x4 -N 4 $* | awk 'NR==1{print $2}'
}

# print32 hex
print32()
{
	n="0${1}"
	n1=`bcxx "${n} % 100"`
	n2=`bcxx "(${n} / 100) % 100"`
	n3=`bcxx "(${n} / 10000) % 100"`
	n4=`bcxx "(${n} / 1000000) % 100"`
	/bin/printf "\x${n1}\x${n2}\x${n3}\x${n4}"
}



# programexit number
programexit()
{
	case $1 in
		1) # usage
			echo "usage: `basename $0` boot.img";;
		2) # bootimg is not a regular file
			echo "${bootimg} is not a regular file" >&2;;
		3) # error magic
			echo "error magic" >&2;;
		4) # error dd
			echo "error dd" >&2;;
		5) # error id
			echo "error id" >&2;;
	esac

	exit
}


bootimg=${1}

if [ -z ${bootimg} ]; then
	programexit 1
fi

if [ ! -f ${bootimg} ]; then
	programexit 2
fi

magic=`dd if=${bootimg} bs=1 count=8 2>/dev/null | awk '{print $0}'`
# debug
echo " ** magic=${magic}" >&2
if [ ${magic} != 'ANDROID!' ]; then
	programexit 3
fi


outputfiles="kernel kernel-size kernel-addr \
	ramdisk ramdisk-size ramdisk-addr \
	second second-size second-addr \
	dt dt-size\
	tags-addr page-size os-version \
	name cmdline id extra-cmdline"



# remove to output...
rm -f ${outputfiles}


# getting page size
pagesize=`read32 -j 0x24 ${bootimg}`
#debug
echo " ** pagesize=${pagesize}" >&2

print32 ${pagesize} | dd of=page-size 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

## kernel kernel-size kernel-addr
kernelsize=`read32 -j 0x08 ${bootimg}`
kerneladdr=`read32 -j 0x0c ${bootimg}`
# debug
echo " ** kernelsize=${kernelsize}" >&2
echo " ** kerneladdr=${kerneladdr}" >&2
print32 ${kernelsize} | dd of=kernel-size 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
print32 ${kerneladdr} | dd of=kernel-addr 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

s=1
n=`bcxd "(${kernelsize} + ${pagesize} - 1) / ${pagesize}"`

dd if=${bootimg} of=kernel bs=$((0x${pagesize})) skip=${s} count=${n} 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s `bcxd "${kernelsize}"` kernel



## ramdisk ramdisk-size ramdisk-addr
ramdisksize=`read32 -j 0x10 ${bootimg}`
ramdiskaddr=`read32 -j 0x14 ${bootimg}`
# debug
echo " ** ramdisksize=${ramdisksize}" >&2
echo " ** ramdiskaddr=${ramdiskaddr}" >&2
print32 ${ramdisksize} | dd of=ramdisk-size 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
print32 ${ramdiskaddr} | dd of=ramdisk-addr 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

s=`bcdd "${s} + ${n}"`
n=`bcxd "(${ramdisksize} + ${pagesize} - 1) / ${pagesize}"`

dd if=${bootimg} of=ramdisk bs=$((0x${pagesize})) skip=${s} count=${n} 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s `bcxd "${ramdisksize}"` ramdisk



## second second-size second-addr
secondsize=`read32 -j 0x18 ${bootimg}`
secondaddr=`read32 -j 0x1c ${bootimg}`
# debug
echo " ** secondsize=${secondsize}" >&2
echo " ** secondaddr=${secondaddr}" >&2
print32 ${secondsize} | dd of=second-size 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
print32 ${secondaddr} | dd of=second-addr 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

s=`bcdd "${s} + ${n}"`
n=`bcxd "(${secondsize} + ${pagesize} - 1) / ${pagesize}"`

dd if=${bootimg} of=second bs=$((0x${pagesize})) skip=${s} count=${n} 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s `bcxd "${secondsize}"` second




## dt dt-size dt-addr
dtsize=`read32 -j 0x28 ${bootimg}`
# debug
echo " ** dtsize=${dtsize}" >&2
print32 ${dtsize} | dd of=dt-size 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

s=`bcdd "${s} + ${n}"`
n=`bcxd "(${dtsize} + ${pagesize} - 1) / ${pagesize}"`

dd if=${bootimg} of=dt bs=$((0x${pagesize})) skip=${s} count=${n} 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s `bcxd "${dtsize}"` dt


## tags-addr
tagsaddr=`read32 -j 0x20 ${bootimg}`
# debug
echo " ** tagsaddr=${tagsaddr}" >&2
print32 ${tagsaddr} | dd of=tags-addr 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

## os-version
osversion=`read32 -j 0x2c ${bootimg}`
# debug
echo " ** osversion=${osversion}" >&2
print32 ${osversion} | dd of=os-version 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi

## name
name=`dd if=${bootimg} bs=1 count=16 skip=$((0x30)) 2>/dev/null | awk '{print $0}'`
# debug
echo " ** name=${name}"
echo -n ${name} | dd of=name 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s 16 name

## cmdline extra-cmdline
cmdline=`dd if=${bootimg} bs=1 count=$((0x200)) skip=$((0x40)) 2>/dev/null | awk '{print $0}'`
# debug
echo " ** cmdline=${cmdline}"
echo -n ${cmdline} | dd of=cmdline 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s $((0x200)) cmdline

extracmdline=`dd if=${bootimg} bs=1 count=$((0x400)) skip=$((0x260)) 2>/dev/null | awk '{print $0}'`
# debug
echo " ** extracmdline=${extracmdline}"
echo -n ${extracmdline} | dd of=extra-cmdline 2>/dev/null
if [ $? -ne 0 ]; then
	programexit 4
fi
truncate -s $((0x400)) extra-cmdline




## id
id=
k=8
off=$((0x240))
while [ ${k} -ne 0 ]; do
	id=${id}`od -t x4 --endian=big -N 4 -j ${off} ${bootimg} | awk 'NR==1{print $2}'`
	off=`expr ${off} + 4`
	k=`expr ${k} - 1`
done
# debug
echo " ** id=${id}" >&2

# calculate id by ourself
id2=`cat kernel kernel-size ramdisk ramdisk-size second second-size dt dt-size | sha1sum | dd bs=8 count=5 2>/dev/null`000000000000000000000000
# debug
echo " ** id2=${id2}" >&2

if [ ${id} != ${id2} ]; then
	programexit 5
fi


