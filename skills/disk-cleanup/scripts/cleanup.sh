#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default options
DRY_RUN=false
CLEAN_ALL=true
CLEAN_LOGS=false
CLEAN_CACHES=false
CLEAN_SNAPS=false
CLEAN_TEMP=false
MIN_SIZE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --logs)
            CLEAN_ALL=false
            CLEAN_LOGS=true
            shift
            ;;
        --caches)
            CLEAN_ALL=false
            CLEAN_CACHES=true
            shift
            ;;
        --snaps)
            CLEAN_ALL=false
            CLEAN_SNAPS=true
            shift
            ;;
        --temp)
            CLEAN_ALL=false
            CLEAN_TEMP=true
            shift
            ;;
        --min-size)
            MIN_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be cleaned without actually cleaning"
            echo "  --logs        Clean system logs only"
            echo "  --caches      Clean package manager caches only"
            echo "  --snaps       Clean old snap versions only"
            echo "  --temp        Clean temporary files only"
            echo "  --min-size N  Only clean items larger than N (e.g., 100M)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Would clean: $1"
}

# Get directory size
get_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

# Clean system logs
clean_logs() {
    log_info "Cleaning system logs..."
    
    # Journal logs
    if command -v journalctl &> /dev/null; then
        local journal_size=$(get_size /var/log/journal 2>/dev/null || echo "0")
        if [ "$DRY_RUN" = true ]; then
            log_dry "journal logs ($journal_size)"
        else
            sudo journalctl --vacuum-time=7d
            log_success "Cleaned journal logs"
        fi
    fi
    
    # btmp files (failed login records)
    for file in /var/log/btmp /var/log/btmp.1; do
        if [ -f "$file" ]; then
            local size=$(get_size "$file")
            if [ "$DRY_RUN" = true ]; then
                log_dry "$file ($size)"
            else
                sudo rm -f "$file"
                log_success "Removed $file ($size)"
            fi
        fi
    done
}

# Clean temporary files
clean_temp() {
    log_info "Cleaning temporary files..."
    
    local tmp_size=$(get_size /tmp 2>/dev/null || echo "0")
    if [ "$DRY_RUN" = true ]; then
        log_dry "/tmp ($tmp_size)"
    else
        sudo rm -rf /tmp/*
        log_success "Cleaned /tmp ($tmp_size)"
    fi
}

# Clean package manager caches
clean_caches() {
    log_info "Cleaning package manager caches..."
    
    # apt cache
    if command -v apt &> /dev/null; then
        local apt_size=$(get_size /var/cache/apt 2>/dev/null || echo "0")
        if [ "$DRY_RUN" = true ]; then
            log_dry "apt cache ($apt_size)"
        else
            sudo apt clean
            log_success "Cleaned apt cache ($apt_size)"
        fi
    fi
    
    # npm cache
    if command -v npm &> /dev/null; then
        local npm_size=$(get_size ~/.npm 2>/dev/null || echo "0")
        if [ "$DRY_RUN" = true ]; then
            log_dry "npm cache ($npm_size)"
        else
            npm cache clean --force
            log_success "Cleaned npm cache ($npm_size)"
        fi
    fi
    
    # cargo cache
    if [ -d ~/.cargo/registry/src ]; then
        local cargo_size=$(get_size ~/.cargo/registry/src 2>/dev/null || echo "0")
        if [ "$DRY_RUN" = true ]; then
            log_dry "cargo registry source ($cargo_size)"
        else
            rm -rf ~/.cargo/registry/src
            log_success "Cleaned cargo registry source ($cargo_size)"
        fi
    fi
    
    # uv cache
    if [ -d ~/.local/share/uv ]; then
        local uv_size=$(get_size ~/.local/share/uv 2>/dev/null || echo "0")
        if [ "$DRY_RUN" = true ]; then
            log_dry "uv cache ($uv_size)"
        else
            rm -rf ~/.local/share/uv
            log_success "Cleaned uv cache ($uv_size)"
        fi
    fi
}

# Clean old snap versions
clean_snaps() {
    log_info "Cleaning old snap versions..."
    
    if command -v snap &> /dev/null; then
        local disabled_snaps=$(snap list --all | awk '/disabled/{print $1, $3}')
        if [ -n "$disabled_snaps" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_dry "old snap versions"
                echo "$disabled_snaps"
            else
                echo "$disabled_snaps" | while read pkg rev; do
                    sudo snap remove "$pkg" --revision="$rev"
                    log_success "Removed snap $pkg revision $rev"
                done
            fi
        else
            log_info "No old snap versions found"
        fi
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "  Disk Cleanup Tool"
    echo "=========================================="
    echo ""
    
    # Show current disk usage
    log_info "Current disk usage:"
    df -h / | tail -1 | awk '{print "  Used: "$3" ("$5")", "Available: "$4}'
    echo ""
    
    # Run cleanup functions
    if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_LOGS" = true ]; then
        clean_logs
        echo ""
    fi
    
    if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_TEMP" = true ]; then
        clean_temp
        echo ""
    fi
    
    if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_CACHES" = true ]; then
        clean_caches
        echo ""
    fi
    
    if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_SNAPS" = true ]; then
        clean_snaps
        echo ""
    fi
    
    # Show final disk usage
    echo "=========================================="
    log_info "Final disk usage:"
    df -h / | tail -1 | awk '{print "  Used: "$3" ("$5")", "Available: "$4}'
    echo "=========================================="
}

main
