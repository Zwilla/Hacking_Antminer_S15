#set -x
file=/tmp/$$
if [ -f /etc/bitmain-pub.pem ]; then
	if [ ! -f fileinfo.sig ]; then
		echo "RUNME: Cannot Find Signature!!!" >> /tmp/upgrade_result
		exit 1
	fi
	openssl dgst -sha256 -verify /etc/bitmain-pub.pem -signature  fileinfo.sig  fileinfo >/dev/null  2>&1
	vres=$?
	if [ $vres -eq 1 ]; then
		echo "FileList Not Signtured!!!" >> /tmp/upgrade_result
		exit 2
	fi	
	md5sum -s -c fileinfo 
	vres=$?
	if [ $vres -eq 1 ]; then
		echo "FileList Check Failed!!!" >> /tmp/upgrade_result
		exit 3
	fi	
fi

if [ -e BOOT.bin ]; then
	flash_erase /dev/mtd0 0x0 0x40 >/dev/null 2>&1
	nandwrite -p -s 0x0 /dev/mtd0 BOOT.bin >/dev/null 2>&1
fi

if [ -e devicetree.dtb ]; then
	flash_erase /dev/mtd0 0x1A00000 0x1 >/dev/null 2>&1
	nandwrite -p -s 0x1A00000 /dev/mtd0 devicetree.dtb >/dev/null 2>&1
fi

if [ -e uImage ]; then
	flash_erase /dev/mtd0 0x2000000 0x40 >/dev/null 2>&1
	nandwrite -p -s 0x2000000 /dev/mtd0 uImage >/dev/null 2>&1
fi

if [ -e uramdisk.image.gz ]; then
    md5=`md5sum uramdisk.image.gz | awk {'print $1'}`
    md5_r=`cat md5_info`
    if [ $md5 == $md5_r ];then
		flash_erase /dev/mtd1 0x0 0x100 >/dev/null 2>&1
		nandwrite -p -s 0x0 /dev/mtd1 uramdisk.image.gz >/dev/null 2>&1
		if [ -e /dev/mtd4 ]; then
			flash_erase /dev/mtd4 0x0 0x100 >/dev/null 2>&1
			nandwrite -p -s 0x0 /dev/mtd4 uramdisk.image.gz >/dev/null 2>&1
		fi
	else
		echo $md5 > /config/md5_error
		echo $md5_r >> /config/md5_error
		echo "Error md5! $md5 $md5_r" >> /tmp/upgrade_result
	fi
fi

if [ -e /log ]; then
    umount -l /log
    rm -rf /log
    mkdir /nvdata
    mount -t jffs2 /dev/mtdblock5 /nvdata
fi

rm -rf /config/scanfreqdone 2>/dev/null

sync >/dev/null 2>&1
