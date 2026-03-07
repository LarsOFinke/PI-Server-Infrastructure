#!/usr/bin/env bash

configure_tmpfs_mounts() {
  backup_file /etc/fstab
  append_fstab_entry_if_missing "tmpfs /tmp tmpfs defaults,noatime,nosuid 0 0"
  append_fstab_entry_if_missing "tmpfs /var/tmp tmpfs defaults,noatime,nosuid 0 0"
}

create_standard_directories() {
  ensure_user_directory "$HOST_USER_HOME/bin"
  ensure_user_directory "$HOST_USER_HOME/repositories"
  mkdir -p /srv/backups
  chown "$HOST_USERNAME:$HOST_USERNAME" /srv/backups
  chmod 770 /srv/backups
}

create_hushlogin_file() {
  sudo -u "$HOST_USERNAME" touch "$HOST_USER_HOME/.hushlogin"
}
