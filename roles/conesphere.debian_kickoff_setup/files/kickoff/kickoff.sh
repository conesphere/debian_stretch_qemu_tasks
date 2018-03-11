#!/bin/bash
if [[ ! -e /dev/fd0 ]]
then
	echo Damn we dont have a flopppy 
	exit 23
fi
if [[ -e /etc/machine-id ]]
then
	echo There is a machine id, are we already kicked off? 
	exit 42
fi
mount /media/fd0 || exit $?
cp /media/fd0/kickoff.yml /etc/kickoff/conf.yml || exit $?
umount /media/fd0 || exit $?
KICK="/etc/kickoff/jinja2proc.py -p /etc/kickoff -i /etc/kickoff/conf.yml"
${KICK} -o /etc/hostname etc-hostname.j2 || exit $?
hostname -F /etc/hostname || exit $?
install -m 0700 -d /root/.ssh || exit $?
${KICK} -o /root/.ssh/authorized_keys root-.ssh-authorized_keys.j2 || exit $?
${KICK} -o /etc/network/interfaces etc-network-interfaces.j2 || exit $?
# resizing should now be done automatically by cloud-initramfs-growroot 
# btrfs filesystem resize max / || exit $?
# begin block ssh key generation
if [[ -f "/etc/ssh/sshd_config" ]]
then
	grep -e "^HostKey " "/etc/ssh/sshd_config" | (
		while read hostkey keyfile foo 
		do
			keyname="${keyfile##*/}"
			IFS="_" read t1 t2 keytype t3 <<< "${keyname}"
			if [[ -f "/etc/ssh/${keyname}" ]]
			then
				rm "/etc/ssh/${keyname}"
			fi
			if [[ -f "/etc/ssh/${keyname}.pub" ]]
			then
				rm "/etc/ssh/${keyname}.pub"
			fi
			ssh-keygen -N '' -t "${keytype}" -f "/etc/ssh/${keyname}"
		done
	)
	# end block ssh key generation
	
	# drop root password 
	cp -a /etc/shadow /etc/shadow- || exit $?
	sed -e 's/^root:.*$/root:!:17311:0:99999:7:::/g' < /etc/shadow- > /etc/shadow  || exit $?
else
	echo "WARNING: Can't open sshd_config but I will continue anyway."
	echo "but we are leaving the root password behind so you habe means to login"
fi

# TODO: Inplement stuff to mount additional filesystems or initialize zfs or so 
# - name: Mount up 9p filesystems if any 
#   mount:
#     path: '/{{ kvm_machine_filesystem.mountpoint }}'
#     src: '{{ kvm_machine_filesystem.name }}'
#     fstype: 9p
#     opts: trans=virtio,rw
#     state: mounted
#   with_items: "{{ kvm_machine.filesystems|default([]) }}"
#   loop_control:
#     loop_var: kvm_machine_filesystem

# the last task is to create a new machine-id
dd if=/dev/urandom count=1 2>/dev/null | md5sum | (read foo bar ; echo $foo ) > /etc/machine-id

