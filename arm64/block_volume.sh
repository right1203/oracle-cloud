# iSCSI 명령 및 정보의 연결 명령을 먼저 실행해야 함.

sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/sdb
sudo mount -o discard,defaults /dev/sdb /mnt/disks/sdb
sudo chmod a+w /mnt/disks/sdb
sudo sh -c 'echo UUID="$(sudo blkid /dev/sdb | cut -d " " -f 2 | cut -d "=" -f 2)" /mnt/disks/sdb ext4 discard,defaults,noatime,_netdev 0 2 >> /etc/fstab'
sudo mount -all