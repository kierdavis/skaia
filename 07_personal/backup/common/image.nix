{ bash
, dumb-init
, lib
, openssh
, python3
, restic
, shadow
, stamp
, writeShellScriptBin
, writeText
}:

let
  passwd = writeText "passwd" ''
    root:x:0:0:System administrator:/root:${bash}/bin/bash
    sshd:x:1:1:SSH privilege separation user:/var/empty:${shadow}/bin/nologin
  '';
  shadow = writeText "shadow" ''
    root:*:1::::::
    sshd:!:1::::::
  '';
  group = writeText "group" ''
    root:x:0:
    sshd:x:0:
  '';
  sshConfig = writeText "ssh_config" ''
    AddKeysToAgent no
    AddressFamily any
    BatchMode yes
    ConnectionAttempts 1
    ConnectTimeout 10
    ForwardAgent no
    ForwardX11 no
    GlobalKnownHostsFile /keys/known_hosts
    IdentityFile /keys/id_ed25519
    KbdInteractiveAuthentication no
    LogLevel INFO
    PasswordAuthentication no
    Port 2222
    PreferredAuthentications publickey
    PubkeyAuthentication yes
    RequestTTY no
    StdinNull yes
    StrictHostKeyChecking yes
    User root
  '';
  sshdConfig = writeText "sshd_config" ''
    AddressFamily any
    AllowAgentForwarding no
    AllowGroups root
    AllowStreamLocalForwarding no
    AllowTcpForwarding no
    AllowUsers root
    AuthenticationMethods publickey
    AuthorizedKeysFile /keys/authorized_keys
    AuthorizedPrincipalsFile none
    Banner none
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    DisableForwarding yes
    ForceCommand exec ${scripts.backup}/bin/backup
    GatewayPorts no
    HostbasedAuthentication no
    HostKey /keys/ssh_host_ed25519_key
    KbdInteractiveAuthentication no
    KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512,sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    LogLevel INFO
    Macs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
    ModuliFile ${openssh}/etc/ssh/moduli
    PasswordAuthentication no
    PermitRootLogin prohibit-password
    PermitTTY no
    PermitTunnel no
    PermitUserEnvironment yes
    PermitUserRC no
    PidFile none
    Port 2222
    PrintMotd no
    PubkeyAuthentication yes
    StrictModes no
    UseDns no
    UsePAM no
    X11Forwarding no
  '';
  scripts = {
    ageout = writeShellScriptBin "ageout" ''
      exec ${python3}/bin/python ${./ageout.py} "$@"
    '';
    backup = writeShellScriptBin "backup" ''
      exec ${restic}/bin/restic backup \
        --exclude=lost+found \
        --exclude=.nobackup \
        --exclude='.Trash-*' \
        --host=generic \
        --one-file-system \
        --read-concurrency=4 \
        --tag=auto \
        "$DATA_PATH"
    '';
    sidecar = writeShellScriptBin "sidecar" ''
      env > /root/.ssh/environment
      exec ${openssh}/bin/sshd -D -e
    '';
    sidecarClient = writeShellScriptBin "sidecar-client" ''
      exec ${openssh}/bin/ssh "$1"
    '';
  };
in stamp.fromNix {
  name = "stamp-img-skaia-backup";
  runOnHost = ''
    mkdir -p etc/ssh root/.ssh var/empty
    ln -sfT ${passwd} etc/passwd
    ln -sfT ${shadow} etc/shadow
    ln -sfT ${group} etc/group
    ln -sfT ${sshConfig} etc/ssh/ssh_config
    ln -sfT ${sshdConfig} etc/ssh/sshd_config
  '';
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  env.PATH = lib.makeBinPath (lib.attrValues scripts ++ [ restic ]);
}
