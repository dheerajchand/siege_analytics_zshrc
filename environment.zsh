# =====================================================
# ENVIRONMENT & PATH SETUP
# =====================================================

# Python/Pyenv setup - COMMENTED OUT - Now using modular Python management
# if command -v pyenv &>/dev/null; then
#     eval "$(pyenv init -)"
#     eval "$(pyenv virtualenv-init -)"
#     eval "$(pyenv init --path)"
#     export PREFERRED_VENV="geo31111"
#     pyenv activate $PREFERRED_VENV 2>/dev/null || true
# fi

# Node/NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use &> /dev/null
  else
    nvm use stable 2>/dev/null || true
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Java setup (conditional)
if [[ -d "/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current" ]]; then
    export JAVA_HOME="/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current"
    export PATH="$JAVA_HOME/bin:$PATH"
    # REMOVED: LD_LIBRARY_PATH can interfere with macOS GUI applications
    # export LD_LIBRARY_PATH="$JAVA_HOME/lib:$LD_LIBRARY_PATH"
fi

# SDKMAN Setup
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec 2>/dev/null || export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# Useful path shortcuts
export SIEGE="/Users/dheerajchand/Documents/Professional/Siege_Analytics"
export UTILITIES="${SIEGE}/Code/siege_utilities"
export GEOCODE="/Users/dheerajchand/Documents/Professional/Siege_Analytics/Clients/TAN/Projects/tan_geocoding_test"
export MASAI="/Users/dheerajchand/Documents/Professional/Siege_Analytics/Clients/MI"
export RESUME_GENERATOR="/Users/dheerajchand/Documents/Professional/resume_generator"

# JetBrains settings
export JETBRAINS_TOOLS_PATH="$HOME/.jetbrains/bin"
mkdir -p "$JETBRAINS_TOOLS_PATH"
export PATH="$JETBRAINS_TOOLS_PATH:$PATH"
