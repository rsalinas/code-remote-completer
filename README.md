# code-remote

Eina xicoteta per a obrir projectes remots en VS Code via SSH de forma ràpida:

```bash
code-remote <ssh_host> [ruta_remota]
```

Internament executa:

```bash
code --remote ssh-remote+<SSH_HOST> <FULL_REMOTE_PATH>
```

on `<FULL_REMOTE_PATH>` es resol en el servidor remot amb `realpath` (o `readlink -m` com a alternativa).

## Què fa

- Resol rutes relatives respecte a `$HOME` del host remot.
- Accepta rutes absolutes (`/opt/app`) i amb `~` (`~/repos/app`).
- Inclou autocompletat Bash:
  - 1r argument: hosts SSH (des de `~/.ssh/config` i `~/.ssh/known_hosts`).
  - 2n argument: rutes del host remot (carpetes i fitxers), similar al flux d'`rsync`.

## Instal·lació

### Opció 1: instal·lació local (recomanada)

Des de este repositori:

```bash
chmod +x code-remote
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/bash-completion/completions"
cp code-remote "$HOME/.local/bin/code-remote"
cp completions/code-remote.bash "$HOME/.local/share/bash-completion/completions/code-remote"
```

Assegura't que `$HOME/.local/bin` està en el teu `PATH`.

### Opció 2: ús directe des del repositori

```bash
chmod +x ./code-remote
source ./completions/code-remote.bash
```

## Activar completació en Bash

Si no tens carregat `bash-completion`, afig al teu `~/.bashrc`:

```bash
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi
```

I per carregar la completació local de l'eina:

```bash
if [ -f "$HOME/.local/share/bash-completion/completions/code-remote" ]; then
  . "$HOME/.local/share/bash-completion/completions/code-remote"
fi
```

Recarrega shell:

```bash
source ~/.bashrc
```

## Exemples

```bash
code-remote raspi4 repos/ElMeuProjecte
code-remote raspi4 ~/repos/ElMeuProjecte
code-remote user@server /srv/project
```

## Notes

- L'autocompletat de rutes remotes fa consultes SSH ràpides al host mentre pulses `TAB`.
- Si un host no és accessible o necessita interacció, la completació de rutes pot no mostrar resultats fins que l'accés SSH estiga preparat (clau, agent, etc.).
