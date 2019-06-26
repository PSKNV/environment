#!/usr/bin/env bash
#
################################################################################
#
# Of the theme that I have declared to you, I will now that ye make in harmony
# together a Great Music. And since I have kindled you with the Flame
# Imperishable, ye shall show forth your powers in adorning this theme, each
# with his own thoughts and devices, if he will. But I win sit and hearken, and
# be glad that through you great beauty has been wakened into song.
#
#   John Ronald Reuel Tolkien (c)
#
################################################################################
#
# Run this script to install all dependencies and configurations. If you wish to
# perform only specific task or tasks pass them as arguments, space-separated.
#
#   ./eru.sh [theme] [theme] ...
#
# For example,
#
#   ./eru.sh linking repositories packages
#

#
# Hi, my name is
#

fellow="d12frosted"

#
# Fast failure
#

set -e

#
# Get the OS info
#

KERNEL_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
KERNEL_RELEASE=$(uname -r | tr '[:upper:]' '[:lower:]')
OS_NAME="unknown"
case $KERNEL_NAME in
  darwin)
    OS_NAME=macos
    ;;
  linux)
    case $KERNEL_RELEASE in
      *arch*|*coreos*)
        OS_NAME="arch"
        ;;
    esac
    ;;
  *)
    ;;
esac

#
# Setup USER
#

if [ -z "$USER" ]; then
  USER=$(whoami)
fi

#
# Setup PATH
#

export PATH=$HOME/.local/bin:$PATH

#
# Logging
#

function error() {
  echo -e "\033[0;31m$*\033[0m"
}

function intro() {
  echo -e "\033[0;34m$*\033[0m"
}

function log() {
  echo -e "$*"
}

function section() {
  echo -e "\033[0;34m=> $*\033[0m"
}

function theme() {
  echo -e "\033[1;32m=> $1 Theme :: ${*:2}\033[0m"
}

function optional_theme() {
  echo -e "\033[1;32m-> $1 Theme :: ${*:2}\033[0m"
}

function inactive_theme() {
  echo -e "\033[1;37m-> $1 Theme :: ${*:2}\033[0m"
}

#
# Greetings
#

intro "Of the theme that I have declared to you, I will now that ye make in harmony
together a Great Music. And since I have kindled you with the Flame
Imperishable, ye shall show forth your powers in adorning this theme, each with
his own thoughts and devices, if he will. But I win sit and hearken, and be glad
that through you great beauty has been wakened into song."
intro

log "Kernel name:      $KERNEL_NAME"
log "Kernel release:   $KERNEL_RELEASE"
log "Operating system: $OS_NAME"
log "User:             $USER"
log

#
# Helpers
#

theme "Supporting" "Defining helpers"

function theme_guard() {
  key=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local guard_ref="guard_$key"
  local ignore_guard_ref="guard_ignore_$key"
  guard="${!guard_ref}"
  ignore_guard="${!ignore_guard_ref}"
  if [[ ("$ALL" = "true" || "$guard" = "true") && "$ignore_guard" = "" ]]; then
    optional_theme "$1" "${@:2}"
    return 0
  else
    inactive_theme "$1" "${@:2}"
    return 1
  fi
}

function macos_guard() {
  [[ "$OS_NAME" == "macos" ]]
  return
}

function arch_guard() {
  [[ "$OS_NAME" == "arch" ]]
  return
}

function qualify_repo_url() {
  if [[ "$1" = "https://"* || "$1" = "git@"* ]]; then
    echo "$1"
  elif [[ "$2" = "github" ]]; then
    if [[ "$USE_HTTPS" = "true" ]]; then
      echo  "https://github.com/$1.git"
    else
      echo "git@github.com:$1.git"
    fi
  elif [[ "$2" = "gitlab" ]]; then
    if [[ "$USE_HTTPS" = "true" ]]; then
      echo  "https://gitlab.com/$1.git"
    else
      echo "git@gitlab.com:$1.git"
    fi
  fi
}

function git_lg() {
  git --no-pager \
      log \
      --graph \
      --pretty=format:'%Cred%h%Creset %C(bold blue)<%an> -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' \
      "$*"
}

function sync_repo() {
  section "sync_repo $*"

  wd=$(eval echo "$1")
  remote="$2"
  url=$(qualify_repo_url "$3" "$remote")
  branch="$4"
  if [[ $branch = "" ]]; then
    branch="master"
  fi

  if [[ -d "$wd/.git" ]]; then
    log "$wd already exists"
  else
    git clone "$url" "$wd" -b "$branch"
  fi

  cd "$wd" && {
    git diff-index --quiet HEAD -- || {
      error "Your working directory is not clean."
      error "Please commit or stash all changes before proceeding."
      return 1
    }

    current_branch=$(git symbolic-ref --short HEAD)
    if [[ $branch != "$current_branch" ]]; then
      log "Switching from $current_branch to $branch"
      git checkout "$branch"
    fi

    if [[ -d .git/refs/remotes/$remote ]]; then
      current_url=$(git remote get-url $remote)
      if [[ $current_url != "$url" ]]; then
        log "Remote '$remote' has wrong url, so updating it"
        log "  $current_url -> $url"
        git remote set-url $remote "$url"
      fi
    else
      log "Could not find remote '$remote', so adding it"
      git remote add $remote "$url"
    fi

    log "fetch $remote"
    git fetch $remote
    if [[ $(git rev-parse HEAD) == $(git rev-parse $remote/$branch) ]]; then
      log "Everything up-to-date"
      return 0
    fi

    if [ "$(git rev-list HEAD..$remote/$branch --count)" != 0 ]; then
      log "Fetched changes:"
      git_lg HEAD..$remote/$branch
      log
    fi

    log "rebase onto $remote/$branch"
    git rebase $remote/$branch

    if [[ "$url" = *"$fellow"* ]]; then
      if [ "$(git rev-list $remote/$branch..HEAD --count)" != 0 ]; then
        log "Changes to push:"
        git_lg $remote/$branch..HEAD
        log
      fi

      log "pushing changes"
      git push $remote $branch
    fi
  }
}

function ensure_dir() {
  if [[ ! -d "$1" ]]; then
    log "create $1"
    mkdir -p "$1"
  fi
}

function check() {
  command -v "$1" >/dev/null 2>&1
}

function linkfile() {
  local file="$1"
  if [ -f "$file" ]; then
    (
      cd "$(dirname "$file")"
      map_lines safe_link "$file"
    )
  fi
}

function safe_link() {
  local f
  local s
  local t
  local d
  local owner

  # shellcheck disable=SC2086
  f=$(eval echo $1)
  s="$(pwd)/$f"
  shift
  t="${*/#\~/$HOME}"
  d=$(dirname "$t")

  if [[ -d "$d" ]]; then
    owner=$(stat -c '%U' "$d")
    if [[ "$owner" != "root" && "$owner" != "$USER" ]]; then
      error "can not link '$s' to '$t'"
      error "owner of '$d' is $owner"
      error "allowed owners: root or $USER"
      exit 1
    fi
  fi


  if [[ ! -f "$s" && ! -d "$s" ]]; then
    error "can not link '$s' as it does not exist"
    exit 1
  fi

  if [[ ! -d $d ]]; then
    log "create $d"
    mkdir -p "$d"
  fi

  if [[ -L "$t" ]]; then
    log "relink $s -> $t"
    if [[ "$owner" = "root" ]]; then
      sudo rm "$t"
    else
      rm "$t"
    fi
  else
    log "link $s -> $t"
  fi

  if [[ "$owner" = "root" ]]; then
    sudo ln -s "$s" "$t"
  else
    ln -s "$s" "$t"
  fi
}

function map_lines() {
  if [[ -f "$2" ]]; then
    while IFS='' read -r line || [[ -n "$line" ]]; do
      if [[ "$line" != "#"* ]]; then
        # shellcheck disable=SC2086
        $1 $line
      fi
    done < "$2"
  fi
}

function download_bin() {
  fp="$HOME/.local/bin/$1"
  curl --silent -o "$fp" "$2"
  chmod a+x "$HOME/.local/bin/$1"
  hash -r
}

#
# Setup variables
#

theme "Supporting" "Defining variables"

target=$XDG_CONFIG_HOME
if [[ "$target" = "" ]]; then
  target="$HOME/.config"
fi
export XDG_CONFIG_HOME=$target

if [[ "$XDG_CONFIG_CACHE" = "" ]]; then
  export XDG_CONFIG_CACHE="$HOME/.cache"
fi

if [[ "$XDG_DATA_HOME" = "" ]]; then
  export XDG_DATA_HOME="$HOME/.local/share"
fi

if [[ "$XDG_CACHE_HOME" = "" ]]; then
  export XDG_CACHE_HOME="$HOME/.cache"
fi

export DEVELOPER=$HOME/Developer
if [[ "$USER" != "$fellow" ]]; then
  export DEVELOPER=$HOME/Developer/personal
fi

ALL="true"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  if [[ "$1" != "" ]]; then
    if [[ "$1" = -* ]]; then
      key=$(echo "${1#-}" | tr '[:upper:]' '[:lower:]')
      declare -r "guard_ignore_$key=true"
    else
      key=$(echo "$1" | tr '[:upper:]' '[:lower:]')
      declare -r "guard_$key=true"
      ALL="false"
    fi
  fi
  shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ "$INTERACTIVE" = "" ]]; then
  INTERACTIVE=true
fi

#
# Lock
#

LOCK_FILE=$XDG_CACHE_HOME/eru/eru.lock
if [ -f "$LOCK_FILE" ]; then
  error "
Yet another world is being shaped by Eru

One must either wait patiently or embrace the horrors of the unknown and
manually delete the $LOCK_FILE"
  exit 1
fi
mkdir -p "$(dirname "$LOCK_FILE")"
touch "$LOCK_FILE"

function unlock() {
  rm -rf "$LOCK_FILE"
}

trap unlock INT TERM EXIT

#
# Actual bootstrap
#

theme "Guardian" "Ensure all directories exists"
ensure_dir "$HOME/.local/bin"
ensure_dir "$DEVELOPER"
ensure_dir "$HOME/Dropbox/Apps/Emacs"

# TODO: make it working on Linux from command line
macos_guard && theme_guard "SSH" "Checking SSH keys" && {
  if [[ "$INTERACTIVE" = "true" ]]; then
    ssh_key_add_url="https://github.com/settings/ssh/new"
    ssh_key_path="$HOME/.ssh/id_rsa"
    ssh_key_pub_path="${ssh_key_path}.pub"
    ssh_config_path="$HOME/.ssh/config"

    if [[ -f "$ssh_key_path" ]]; then
      log "SSH key found at $ssh_key_path."
    else
      log "No SSH key found."
      mkdir -p "$(dirname "$ssh_key_path")"
      ssh-keygen -t rsa -b 4096 -C "$USER" -f "$ssh_key_path"
      log "SSH key was generated."
    fi

    log "Starting ssh-agent"
    eval "$(ssh-agent -s)"

    macos_guard && {
      log "Automatically load SSH key and use Keychain"
      echo "Host *
 AddKeysToAgent yes
 UseKeychain yes
 IdentityFile $ssh_key_path" > "$ssh_config_path"
    }

    log "Add SSH key to ssh-agent"
    ssh-add -K ~/.ssh/id_rsa

    log "Make sure to add SSH key to GitHub"
    pbcopy < "$ssh_key_pub_path"
    open "$ssh_key_add_url"
    read -rp "Press enter to continue"
  fi
}

theme_guard "Repositories" "Sync environment repository" && {
  sync_repo "$XDG_CONFIG_HOME" "github" "d12frosted/environment" || true
}

theme_guard "Repositories" "Sync repositories from Repofiles" && {
  map_lines sync_repo "$target/Repofile" || true
  map_lines sync_repo "$XDG_CONFIG_CACHE/eru/Repofile" || true
}

theme_guard "Linking" "Link all files as defined in Linkfiles" && {
  linkfile "$target/Linkfile"
  linkfile "$XDG_CONFIG_CACHE/eru/Linkfile"
  linkfile "$XDG_CONFIG_CACHE/eru/Linkfile_${KERNEL_NAME}"
  for f in "$target"/**/Linkfile; do
    linkfile "$f"
  done
  for f in "$target"/**/Linkfile_"${KERNEL_NAME}"; do
    linkfile "$f"
  done
}

arch_guard && {
  theme_guard "packages" "Bootstrap Arch Linux" && {
    section "Install crutial dependenices"
    # sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm --needed base-devel git pacman-contrib

    section "Rank mirrors for pacman"
    mirrorlist="/etc/pacman.d/mirrorlist"
    mirrorlist_bak="${mirrorlist}.bak"
    if [[ -f "$mirrorlist_bak" ]]; then
      log "Not updating mirrors list, because '$mirrorlist_bak' exists"
      log "Delete in order to re-rank mirrors"
    else
      mirrorlist_tmp=$(mktemp)
      curl -s 'https://www.archlinux.org/mirrorlist/?country=all&protocol=https&ip_version=4' \
        | sed -e 's/^#Server/Server/' -e '/^#/d' > "$mirrorlist_tmp"
      sudo cp "$mirrorlist_tmp" "$mirrorlist_bak"
      # shellcheck disable=SC2024
      sudo sh -c "rankmirrors -n 6 '$mirrorlist_bak' > '$mirrorlist'"
    fi

    section "Install yay for simpler AUR access"
    check yay || {
      yay_dir=$(mktemp -d)
      git clone https://aur.archlinux.org/yay.git "$yay_dir"
      cd "$yay_dir" && {
        makepkg -si --noconfirm
      }
    }
  }

  theme_guard "packages" "Install all dependencies" && {
    log "Import known GPG keys"
    gpg --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E # don't remember
    gpg --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 # spotify

    function combine_files {
      local output
      output=$(mktemp)
      for f in "$@"; do
        if [[ -f $f ]]; then
          cat "$f" >> "$output"
        fi
      done
      echo "$output"
    }

    aur_file=$(combine_files "$target/arch/Aurfile" "$target/arch/Aurfile_$USER")
    aur_ignore=$(combine_files "$target/arch/Aurignore" "$target/arch/Aurignore_$USER")

    # shellcheck disable=SC2046
    yay -S --noconfirm --needed $(comm -23 "$aur_file" "$aur_ignore")

    pacman_file=$(combine_files "$target/arch/Pacmanfile" "$target/arch/Pacmanfile_$USER")
    pacman_ignore=$(combine_files "$target/arch/Pacmanignore" "$target/arch/Pacmanignore_$USER")
    # shellcheck disable=SC2046
    sudo pacman -S --noconfirm --needed $(comm -23 "$pacman_file" "$pacman_ignore")
  }

  theme_guard "upgrade" "Upgrade Arch Linux" && {
    sudo pacman -Syu --noconfirm
    yay -Syu --noconfirm
  }

  theme_guard "hardware" "Setup keyboard" && {
    if [[ ! -f /usr/share/X11/xkb/symbols/ua.bak ]]; then
      sudo mv /usr/share/X11/xkb/symbols/ua /usr/share/X11/xkb/symbols/ua.bak
    fi
    sudo cp "$XDG_CONFIG_HOME/xorg/xkb/symbols/ua" "/usr/share/X11/xkb/symbols/ua"
  }

  theme_guard "hardware" "Setup touchpad" && {
    sudo cp "$XDG_CONFIG_HOME/xorg/30-touchpad.conf" "/etc/X11/xorg.conf.d/30-touchpad.conf"
  }

  theme_guard "hardware" "Setup autolock" && {
    sudo cp "$XDG_CONFIG_HOME/arch/lock@.service" /etc/systemd/system/lock@.service
    systemctl enable "lock@${USER}.service" || error "systemd is not working"
  }
}

macos_guard && {
  theme_guard "packages" "Ensure brew exists" && {
    check brew || {
      info "Installing brew"
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      brew update
    }
  }

  theme_guard "packages" "Install all dependencies" && {
    cd "$target/macos" && brew bundle
  }
}

theme "Git" "Create a local git config file"
touch "$target/git/local.config"

macos_guard && {
  theme_guard "OS" "Write all defaults" && {
    cd "$target/macos" && sudo ./defaults.sh
  }

  theme "skhd" "Patch skhd application PATH" && {
    check skhd && {
      "$target/bin/patch_skhd_path"
    }
  }
}

arch_guard && {
  theme_guard "xmonad" "Rebuild Xmonad configurations" && {
    section "Install xmonad"
    (
      cd "$XDG_CONFIG_HOME/xmonad"
      stack --allow-different-user install
    )

    section "Restart xmonad"
    if pgrep d12-xmonad; then
      log "Found running instance of xmonad. Restarting..."
      d12-xmonad --restart
    else
      log "No running instance of xmonad is found. Meh..."
    fi
  }
}

theme "Fish" "Setup fish variables"
check fish && {
  fish -c "set -U XDG_CONFIG_HOME $target"
  fish -c "set -U XDG_CACHE_HOME $HOME/.cache"
  fish -c "set -U XDG_DATA_HOME $HOME/.local/share"
}

theme_guard "Emacs" "Refresh Nucleus" && {
  "$XDG_CONFIG_HOME/emacs/nucleus/bin/nucleus" --yes refresh
}

theme_guard "Guardian" "Check that Emacs runs as expected" && {
  emacs --batch -l "$target/emacs/test.el"
}

true
