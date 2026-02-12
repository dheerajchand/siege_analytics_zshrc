#!/usr/bin/env bash
# =================================================================
# Software Stack Installer for ZSH Configuration
# =================================================================
# Installs and configures all software managed by the zsh config:
# - SDKMAN (Java, Hadoop, Spark)
# - Zeppelin (tarball)
# - pyenv (Python environments)
# - Docker Desktop
# - PostgreSQL
# - Optional tools
# =================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PYTHON_VERSION="3.11.11"
DEFAULT_VENV="default_${PYTHON_VERSION//./}"
HADOOP_VERSION="3.3.6"
SPARK_VERSION="4.1.1"
JAVA_VERSION="17.0.15-tem"  # Temurin (Eclipse Adoptium)
ZEPPELIN_VERSION="0.12.0"

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

check_os() {
    print_header "Detecting Operating System"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "macOS detected"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_success "Linux detected"
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi

    if [[ "$OS" == "linux" && -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO="${ID:-unknown}"
        print_info "Linux distro: $DISTRO"
    fi
    
    export OS
    export DISTRO
}

install_homebrew() {
    print_header "Installing Homebrew (macOS Package Manager)"
    
    if command -v brew >/dev/null 2>&1; then
        print_success "Homebrew already installed: $(brew --version | head -1)"
        return
    fi
    
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed"
}

install_system_packages() {
    print_header "Installing System Packages (Linux)"

    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        print_error "Don't run as root. Use sudo for individual commands."
        return 1
    fi
    if ! command -v apt-get >/dev/null 2>&1; then
        print_error "apt-get not found. This step supports Ubuntu/Debian."
        return 1
    fi

    print_step "Updating package lists..."
    sudo apt-get update

    print_step "Installing build essentials and dependencies..."
    sudo apt-get install -y \
        build-essential \
        curl \
        git \
        wget \
        unzip \
        libssl-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        python3-openssl

    print_success "System packages installed"
}

install_1password_cli() {
    print_header "Installing 1Password CLI"

    if command -v op >/dev/null 2>&1; then
        local op_version
        op_version="$(op --version 2>/dev/null | head -1)"
        if echo "$op_version" | grep -qE "1Password CLI 1\\.|^1\\.\\d+\\."; then
            print_warning "Detected legacy 1Password CLI: $op_version"
        else
            print_success "1Password CLI already installed: $op_version"
            return
        fi
    fi

    if [[ "$OS" == "macos" ]]; then
        if command -v brew >/dev/null 2>&1; then
            print_step "Installing 1Password CLI via Homebrew..."
            brew install 1password-cli || brew upgrade 1password-cli
            print_success "1Password CLI installed: $(op --version 2>/dev/null | head -1)"
        else
            print_warning "Homebrew not found; install 1Password CLI from https://developer.1password.com/docs/cli/"
        fi
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        printf "Install/upgrade 1Password CLI via apt (adds 1Password repo if needed)? [y/N]: "
        read -r op_install
        if [[ "$op_install" != [Yy]* ]]; then
            print_info "Skipping 1Password CLI install"
            return
        fi
        if [[ ! -f /etc/apt/sources.list.d/1password.list ]]; then
            print_step "Adding 1Password apt repository..."
            curl -sS https://downloads.1password.com/linux/keys/1password.asc \
                | gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
                | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
            sudo apt-get update
        fi
        print_step "Installing 1Password CLI via apt..."
        sudo apt-get install -y 1password-cli
        print_success "1Password CLI installed: $(op --version 2>/dev/null | head -1)"
        return
    fi

    print_warning "Unsupported package manager for 1Password CLI"
    echo "Install manually: https://developer.1password.com/docs/cli/get-started/#install"
}

install_sdkman() {
    print_header "Installing SDKMAN (Java, Hadoop, Spark Manager)"
    
    if [[ -d "$HOME/.sdkman" ]]; then
        print_success "SDKMAN already installed"
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        return
    fi
    
    print_step "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    
    # Source SDKMAN for this session
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    print_success "SDKMAN installed"
}

install_java() {
    print_header "Installing Java (via SDKMAN)"
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    if sdk list java | grep -q "installed.*$JAVA_VERSION"; then
        print_success "Java $JAVA_VERSION already installed"
        return
    fi
    
    print_step "Installing Java $JAVA_VERSION (Temurin)..."
    sdk install java "$JAVA_VERSION" || true
    sdk default java "$JAVA_VERSION"
    
    print_success "Java installed: $(java -version 2>&1 | head -1)"

    if command -v java >/dev/null 2>&1; then
        local java_home
        java_home="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
        echo "JAVA_HOME=$java_home"
    fi
}

ensure_java_home_in_zshenv() {
    if ! command -v java >/dev/null 2>&1; then
        print_warning "java not found; skipping JAVA_HOME setup"
        return 1
    fi
    local java_home line
    java_home="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
    line="export JAVA_HOME=\"$java_home\""
    if [[ -f "$HOME/.zshenv" ]]; then
        if grep -q "^export JAVA_HOME=" "$HOME/.zshenv"; then
            if command -v sed >/dev/null 2>&1; then
                sed -i.bak "s|^export JAVA_HOME=.*|$line|" "$HOME/.zshenv"
                rm -f "$HOME/.zshenv.bak" 2>/dev/null || true
            else
                print_warning "sed not found; skipping JAVA_HOME update"
            fi
        else
            echo "" >> "$HOME/.zshenv"
            echo "$line" >> "$HOME/.zshenv"
        fi
    else
        echo "$line" >> "$HOME/.zshenv"
    fi
    print_success "JAVA_HOME set in ~/.zshenv"
}

ensure_localhost_ssh_known_host() {
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        print_warning "ssh-keygen not found; skipping localhost host key check"
        return 1
    fi
    local kh="$HOME/.ssh/known_hosts"
    if [[ -f "$kh" ]] && grep -q "localhost" "$kh"; then
        printf "Reset localhost SSH host key? [y/N]: "
        read -r fix_host
        if [[ "$fix_host" == [Yy]* ]]; then
            ssh-keygen -f "$kh" -R localhost >/dev/null 2>&1 || true
            ssh-keygen -f "$kh" -R 127.0.0.1 >/dev/null 2>&1 || true
            print_info "Removed localhost host keys from known_hosts"
        else
            print_info "Skipping localhost host key reset"
        fi
    fi
    return 0
}

install_hadoop() {
    print_header "Installing Hadoop (via SDKMAN)"
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    if sdk list hadoop 2>/dev/null | grep -q "installed.*$HADOOP_VERSION"; then
        print_success "Hadoop $HADOOP_VERSION already installed"
    else
        print_step "Installing Hadoop $HADOOP_VERSION..."
        sdk install hadoop "$HADOOP_VERSION" || true
        sdk default hadoop "$HADOOP_VERSION"
        print_success "Hadoop installed"
    fi
    
    local hadoop_data_dir="$HOME/hadoop-data"

    # Create Hadoop data directories
    print_step "Creating Hadoop data directories..."
    mkdir -p "$hadoop_data_dir/namenode"
    mkdir -p "$hadoop_data_dir/datanode"
    mkdir -p "$hadoop_data_dir/tmp"
    print_success "Hadoop directories created"
    
    # Configure Hadoop
    print_step "Configuring Hadoop..."
    local hadoop_home="$HOME/.sdkman/candidates/hadoop/current"
    
    if [[ -d "$hadoop_home/etc/hadoop" ]]; then
        # Backup existing configs
        [[ -f "$hadoop_home/etc/hadoop/core-site.xml" ]] && \
            cp "$hadoop_home/etc/hadoop/core-site.xml" "$hadoop_home/etc/hadoop/core-site.xml.bak"
        
        # Create core-site.xml
        cat > "$hadoop_home/etc/hadoop/core-site.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file://${hadoop_data_dir}/tmp</value>
    </property>
</configuration>
EOF
        
        # Create hdfs-site.xml
        cat > "$hadoop_home/etc/hadoop/hdfs-site.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${hadoop_data_dir}/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${hadoop_data_dir}/datanode</value>
    </property>
</configuration>
EOF
        
        # Create yarn-site.xml
        cat > "$hadoop_home/etc/hadoop/yarn-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
</configuration>
EOF
        
        print_success "Hadoop configured"
    else
        print_warning "Hadoop config directory not found, skipping configuration"
    fi
}

install_spark() {
    print_header "Installing Spark (via SDKMAN)"
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    if sdk list spark 2>/dev/null | grep -q "installed.*$SPARK_VERSION"; then
        print_success "Spark $SPARK_VERSION already installed"
    else
        print_step "Installing Spark $SPARK_VERSION..."
        sdk install spark "$SPARK_VERSION" || true
        sdk default spark "$SPARK_VERSION"
        print_success "Spark installed"
    fi
    
    # Create Spark directories
    print_step "Creating Spark directories..."
    mkdir -p ~/spark-events
    mkdir -p ~/spark-jars
    print_success "Spark directories created"
    
    # Configure Spark
    print_step "Configuring Spark..."
    local spark_home="$HOME/.sdkman/candidates/spark/current"
    
    if [[ -d "$spark_home/conf" ]]; then
        # Create spark-defaults.conf
        cat > "$spark_home/conf/spark-defaults.conf" << EOF
# Spark Configuration
spark.master                     spark://localhost:7077
spark.eventLog.enabled           true
spark.eventLog.dir               file://$HOME/spark-events
spark.history.fs.logDirectory    file://$HOME/spark-events
spark.driver.memory              2g
spark.executor.memory            2g
EOF
        
        print_success "Spark configured"
    else
        print_warning "Spark config directory not found, skipping configuration"
    fi
}

install_zeppelin() {
    print_header "Installing Zeppelin (tarball)"

    local zeppelin_root="$HOME/opt/zeppelin"
    local zeppelin_dir="${zeppelin_root}/zeppelin-${ZEPPELIN_VERSION}-bin-all"
    local zeppelin_current="${zeppelin_root}/current"
    local tarball="/tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"
    local url="https://downloads.apache.org/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"
    local archive_url="https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"

    if [[ -d "$zeppelin_dir" ]]; then
        print_success "Zeppelin ${ZEPPELIN_VERSION} already installed at ${zeppelin_dir}"
        ln -sfn "$zeppelin_dir" "$zeppelin_current"
        return
    fi

    print_step "Creating Zeppelin install directory..."
    mkdir -p "$zeppelin_root"

    print_step "Downloading Zeppelin ${ZEPPELIN_VERSION}..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$tarball" || curl -fL "$archive_url" -o "$tarball"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$tarball" "$url" || wget -O "$tarball" "$archive_url"
    else
        print_error "Neither curl nor wget found; cannot download Zeppelin"
        return 1
    fi

    print_step "Extracting Zeppelin..."
    tar -xzf "$tarball" -C "$zeppelin_root"
    ln -sfn "$zeppelin_dir" "$zeppelin_current"
    print_success "Zeppelin installed: ${zeppelin_current}"
}

install_pyenv() {
    print_header "Installing pyenv (Python Version Manager)"
    
    if [[ -d "$HOME/.pyenv" ]] && ! command -v pyenv >/dev/null 2>&1; then
        print_warning "Found existing ~/.pyenv but pyenv is not on PATH"
        printf "Remove existing ~/.pyenv and reinstall? [y/N]: "
        read -r pyenv_action
        if [[ "$pyenv_action" == [Yy]* ]]; then
            rm -rf "$HOME/.pyenv"
            print_info "Removed ~/.pyenv"
        else
            print_info "Skipping pyenv install. Ensure PATH is set for ~/.pyenv/bin"
            return 0
        fi
    fi

    if command -v pyenv >/dev/null 2>&1; then
        print_success "pyenv already installed: $(pyenv --version)"
        return
    fi
    
    if [[ "$OS" == "macos" ]]; then
        print_step "Installing pyenv via Homebrew..."
        brew install pyenv pyenv-virtualenv
    else
        print_step "Installing pyenv via git..."
        curl https://pyenv.run | bash
        ensure_pyenv_shell_init
    fi
    
    # Add to current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    
    print_success "pyenv installed"
}

ensure_pyenv_shell_init() {
    local zshenv="$HOME/.zshenv"
    local zshrc="$HOME/.zshrc"
    local bashrc="$HOME/.bashrc"

    if [[ -f "$zshenv" ]] && ! grep -q "PYENV_ROOT" "$zshenv" 2>/dev/null; then
        cat >> "$zshenv" << 'PYENV_ZSHENV'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
PYENV_ZSHENV
        print_info "Added pyenv PATH to ~/.zshenv"
    elif [[ ! -f "$zshenv" ]]; then
        cat >> "$zshenv" << 'PYENV_ZSHENV'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
PYENV_ZSHENV
        print_info "Created ~/.zshenv with pyenv PATH"
    fi

    if [[ -f "$zshrc" ]] && ! grep -q "pyenv init" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" << 'PYENV_ZSHRC'
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
PYENV_ZSHRC
        print_info "Added pyenv init to ~/.zshrc"
    elif [[ ! -f "$zshrc" ]]; then
        cat >> "$zshrc" << 'PYENV_ZSHRC'
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
PYENV_ZSHRC
        print_info "Created ~/.zshrc with pyenv init"
    fi

    if [[ -f "$bashrc" ]] && ! grep -q "pyenv init" "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" << 'PYENV_BASHRC'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
PYENV_BASHRC
        print_info "Added pyenv init to ~/.bashrc"
    fi
}

ensure_screen_login_shell() {
    local screenrc="$HOME/.screenrc"
    local line="defshell -$SHELL"
    if [[ -f "$screenrc" ]]; then
        if ! grep -q "defshell -$SHELL" "$screenrc" 2>/dev/null; then
            echo "" >> "$screenrc"
            echo "# Ensure screen starts login shell" >> "$screenrc"
            echo "$line" >> "$screenrc"
            print_info "Updated ~/.screenrc to use login shell"
        fi
    else
        echo "# Ensure screen starts login shell" >> "$screenrc"
        echo "$line" >> "$screenrc"
        print_info "Created ~/.screenrc with login shell"
    fi
}

ensure_screen_pyenv_setup() {
    if [[ -f "$HOME/.config/zsh/modules/screen.zsh" ]]; then
        zsh -fc 'source "$HOME/.config/zsh/modules/screen.zsh"; screen_ensure_pyenv' >/dev/null 2>&1 || true
    fi
}

install_python() {
    print_header "Installing Python $PYTHON_VERSION"
    
    # Ensure pyenv is in PATH for this session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)" 2>/dev/null || true
    eval "$(pyenv init -)" 2>/dev/null || true
    
    if pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
        print_success "Python $PYTHON_VERSION already installed"
    else
        print_step "Installing Python $PYTHON_VERSION..."
        pyenv install "$PYTHON_VERSION"
        print_success "Python $PYTHON_VERSION installed"
    fi
    
    # Create virtual environment
    print_step "Creating virtual environment: $DEFAULT_VENV..."
    if pyenv versions --bare | grep -q "^${DEFAULT_VENV}$"; then
        print_success "Virtual environment $DEFAULT_VENV already exists"
    else
        pyenv virtualenv "$PYTHON_VERSION" "$DEFAULT_VENV"
        print_success "Virtual environment $DEFAULT_VENV created"
    fi
    
    # Set as global default
    pyenv global "$DEFAULT_VENV"
    print_success "Python environment configured"
}

install_python_packages() {
    print_header "Installing Essential Python Packages"
    
    # Ensure we're in the right environment
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)" 2>/dev/null || true
    eval "$(pyenv init -)" 2>/dev/null || true
    pyenv shell "$DEFAULT_VENV" 2>/dev/null || true
    
    print_step "Installing packages..."
    
    # Upgrade pip first
    python -m pip install --upgrade pip
    
    # Essential packages
    pip install -q \
        ipython \
        jupyter \
        pandas \
        numpy \
        matplotlib \
        seaborn \
        requests \
        pyspark \
        pyarrow \
        pytest
    
    print_success "Python packages installed"
}

check_docker() {
    print_header "Checking Docker"
    
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker is installed and running"
        else
            print_warning "Docker is installed but not running"
            echo ""
            echo "Start Docker Desktop to use Docker features"
        fi
    else
        print_warning "Docker not installed"
        echo ""
        echo "To install Docker:"
        echo "  1. Download Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo "  2. Install and start Docker Desktop"
        echo "  3. Run this script again or just use Docker"
    fi
}

check_postgresql() {
    print_header "Checking PostgreSQL"
    
    if command -v psql >/dev/null 2>&1; then
        print_success "PostgreSQL client installed: $(psql --version)"
    else
        print_warning "PostgreSQL not installed"
        echo ""
        read -r "install_pg?Install PostgreSQL now? [y/N]: "
        if [[ "$install_pg" == [Yy]* ]]; then
            if [[ "$OS" == "macos" ]]; then
                brew install postgresql@15
                brew services start postgresql@15
            elif command -v apt-get >/dev/null 2>&1; then
                sudo apt-get install -y postgresql postgresql-contrib
                sudo systemctl start postgresql
                sudo systemctl enable postgresql
            else
                print_warning "Unsupported package manager for PostgreSQL install"
            fi
        else
            print_info "Skipping PostgreSQL installation"
        fi
    fi
}

format_namenode() {
    print_header "Formatting Hadoop NameNode"
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    local hadoop_home="$HOME/.sdkman/candidates/hadoop/current"
    local namenode_dir="$HOME/hadoop-data/namenode"
    
    if [[ ! -d "$hadoop_home" ]]; then
        print_error "Hadoop not installed"
        return 1
    fi

    if jps | grep -q NameNode; then
        printf "NameNode is running. Stop and reformat? [y/N]: "
        read -r stop_fmt
        if [[ "$stop_fmt" != [Yy]* ]]; then
            print_info "Skipping NameNode format"
            return 0
        fi
        "$hadoop_home/bin/hdfs" --daemon stop datanode 2>/dev/null || true
        "$hadoop_home/bin/hdfs" --daemon stop namenode 2>/dev/null || true
        if command -v yarn >/dev/null 2>&1; then
            yarn --daemon stop nodemanager 2>/dev/null || true
            yarn --daemon stop resourcemanager 2>/dev/null || true
        fi
        sleep 2
    fi

    if [[ -d "$namenode_dir/current" ]]; then
        printf "NameNode already formatted. Reformat? [y/N]: "
        read -r fmt_again
        if [[ "$fmt_again" != [Yy]* ]]; then
            print_info "Skipping NameNode format"
            return 0
        fi
    fi

    print_step "Formatting NameNode..."
    "$hadoop_home/bin/hdfs" namenode -format -force
    print_success "NameNode formatted"
}

verify_installation() {
    print_header "Verifying Installation"
    
    local all_good=true
    
    # Check SDKMAN
    if [[ -d "$HOME/.sdkman" ]]; then
        print_success "SDKMAN: Installed"
    else
        print_error "SDKMAN: Not found"
        all_good=false
    fi
    
    # Check Java
    if command -v java >/dev/null 2>&1; then
        print_success "Java: $(java -version 2>&1 | head -1)"
    else
        print_error "Java: Not found"
        all_good=false
    fi
    
    # Check Hadoop
    if [[ -d "$HOME/.sdkman/candidates/hadoop/current" ]]; then
        print_success "Hadoop: Installed at ~/.sdkman/candidates/hadoop/current"
    else
        print_error "Hadoop: Not found"
        all_good=false
    fi
    
    # Check Spark
    if [[ -d "$HOME/.sdkman/candidates/spark/current" ]]; then
        print_success "Spark: Installed at ~/.sdkman/candidates/spark/current"
    else
        print_error "Spark: Not found"
        all_good=false
    fi

    # Check Zeppelin
    if [[ -d "$HOME/opt/zeppelin/current" ]]; then
        print_success "Zeppelin: Installed at ~/opt/zeppelin/current"
    else
        print_warning "Zeppelin: Not found (optional)"
    fi
    
    # Check pyenv
    if command -v pyenv >/dev/null 2>&1; then
        print_success "pyenv: $(pyenv --version)"
    else
        print_error "pyenv: Not found"
        all_good=false
    fi
    
    # Check Python
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v python >/dev/null 2>&1; then
        print_success "Python: $(python --version)"
    else
        print_error "Python: Not found"
        all_good=false
    fi
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker: Installed"
    else
        print_warning "Docker: Not installed (optional)"
    fi
    
    echo ""
    if $all_good; then
        print_success "All core components verified!"
    else
        print_error "Some components failed verification"
        return 1
    fi
}

print_next_steps() {
    print_header "Installation Complete! 🎉"
    
    echo "Next steps:"
    echo ""
    printf "1. %b\n" "${GREEN}Restart your terminal${NC} or run:"
    printf "   %b\n" "${CYAN}exec zsh${NC}"
    echo ""
    echo "2. Verify everything works:"
    printf "   %b\n" "${CYAN}python --version${NC}"
    printf "   %b\n" "${CYAN}java -version${NC}"
    printf "   %b\n" "${CYAN}hadoop version${NC}"
    printf "   %b\n" "${CYAN}spark-submit --version${NC}"
    echo ""
    echo "3. Start Hadoop (first time):"
    printf "   %b\n" "${CYAN}start_hadoop${NC}"
    echo ""
    echo "4. Start Spark cluster:"
    printf "   %b\n" "${CYAN}spark_start${NC}"
    echo ""
    echo "5. Start Zeppelin (optional):"
    printf "   %b\n" "${CYAN}zeppelin_start${NC}"
    echo ""
    echo "6. Check status:"
    printf "   %b\n" "${CYAN}hadoop_status${NC}"
    printf "   %b\n" "${CYAN}spark_status${NC}"
    echo ""
    echo "7. Web UIs will be available at:"
    printf "   Hadoop NameNode: %b\n" "${BLUE}http://localhost:9870${NC}"
    printf "   YARN ResourceManager: %b\n" "${BLUE}http://localhost:8088${NC}"
    printf "   Spark Master: %b\n" "${BLUE}http://localhost:8080${NC}"
    printf "   Spark History: %b\n" "${BLUE}http://localhost:18080${NC}"
    printf "   Zeppelin: %b\n" "${BLUE}http://localhost:8081${NC}"
    echo ""
    
    if [[ ! $(command -v docker) ]]; then
        echo "📦 Optional: Install Docker Desktop for container features"
        echo "   https://www.docker.com/products/docker-desktop"
        echo ""
    fi
    
    print_success "Ready to use your data science environment!"
}

# Main installation flow
main() {
    clear
    print_header "Software Stack Installer"
    
    echo "This script will install:"
    echo "  • SDKMAN (Java, Hadoop, Spark manager)"
    echo "  • Java $JAVA_VERSION"
    echo "  • Hadoop $HADOOP_VERSION"
    echo "  • Spark $SPARK_VERSION"
    echo "  • Zeppelin $ZEPPELIN_VERSION"
    echo "  • pyenv (Python version manager)"
    echo "  • Python $PYTHON_VERSION"
    echo "  • Python virtual environment: $DEFAULT_VENV"
    echo "  • 1Password CLI (v2)"
    echo "  • Essential Python packages (pandas, numpy, jupyter, pyspark, etc.)"
    echo ""
    echo "Installation time: ~15-30 minutes"
    echo ""
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    check_os
    
    if [[ "$OS" == "macos" ]]; then
        install_homebrew
    else
        install_system_packages
    fi
    
    install_1password_cli
    install_sdkman
    install_java
    ensure_localhost_ssh_known_host
    ensure_java_home_in_zshenv
    install_hadoop
    install_spark
    install_zeppelin
    install_pyenv
    ensure_screen_login_shell
    ensure_screen_pyenv_setup
    install_python
    install_python_packages
    
    # Optional components
    check_docker
    check_postgresql
    
    # Format namenode for first use
    format_namenode
    
    if verify_installation; then
        print_next_steps
    else
        print_error "Installation verification failed"
        echo ""
        echo "Please check the errors above and try again"
        exit 1
    fi
}

# Run the installer
main "$@"
