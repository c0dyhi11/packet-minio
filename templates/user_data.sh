#!/bin/bash
yum install -y xfsprogs parted
# Find the largest unused disk and format it with xfs and mount it to /srv/
root_disk=`df -h | sort -k 6 | head -1 | cut -c1-8`
data_disk=`fdisk -l | grep -v $root_disk | grep "Disk /dev/sd" | sort -rk 5 | head -1 | awk -F'/' '{print $3}' | awk -F':' '{print $1}'`
parted --script /dev/$data_disk mklabel gpt mkpart primary 0% 100%
mkfs.xfs -f "/dev/$${data_disk}1"
disk_uuid=`blkid /dev/$${data_disk}1 -o export | grep "^UUID="`
printf "$disk_uuid\t/srv\txfs\tdefaults\t0\t0\n" >> /etc/fstab
mount -a
useradd -m -d /srv/minio -s /sbin/nologin minio-user
curl -LO https://dl.min.io/server/minio/release/linux-amd64/minio
mv minio /usr/local/bin/minio
chmod +x /usr/local/bin/minio
mkdir -p /srv/minio/data

cat <<-"EOF" > /etc/systemd/system/minio.service
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local/

User=minio-user
Group=minio-user

EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"$${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target

# Built for $${project.name}-$${project.version} ($${project.name})

EOF

cat <<EOT > /etc/default/minio
MINIO_VOLUMES="/srv/minio/data/"
MINIO_ACCESS_KEY="${minio_access_key}"
MINIO_SECRET_KEY="${minio_secret_key}"
MINIO_REGION_NAME="us-east-1"

EOT

chown minio-user:minio-user /usr/local/bin/minio
chown minio-user:minio-user /etc/default/minio
chown -R minio-user:minio-user /srv/minio

systemctl daemon-reload
systemctl enable minio.service
systemctl start minio.service

sleep 10
curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/
mc config host add minio http://127.0.0.1:9000 ${minio_access_key} ${minio_secret_key}
mc mb minio/public
mc policy set public minio/public
