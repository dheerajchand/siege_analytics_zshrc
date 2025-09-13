#!/usr/bin/env zsh

# =====================================================
# PYTHON PROJECT UTILITIES
# =====================================================
#
# Python project initialization and data science workflow functions.
# These functions help set up and manage Python projects efficiently.
# =====================================================

ds_project_init() {
    # Initialize a data science project with UV
    #
    # Usage:
    #   ds_project_init myproject        # Basic data science project
    #   ds_project_init myproject spark  # With Spark dependencies
    local project_name="$1"
    local project_type="${2:-basic}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: ds_project_init <project_name> [basic|spark|geo]"
        return 1
    fi

    echo "🔬 Creating data science project: $project_name"
    mkdir -p "$project_name" && cd "$project_name"

    # Initialize UV project
    uv init --name "$project_name" --python 3.11

    # Add common data science dependencies
    echo "📦 Adding data science dependencies..."
    uv add pandas numpy matplotlib seaborn jupyter ipykernel

    case "$project_type" in
        "spark")
            echo "⚡ Adding Spark dependencies..."
            uv add pyspark findspark
            ;;
        "geo")
            echo "🌍 Adding geospatial dependencies..."
            uv add geopandas folium contextily
            ;;
    esac

    # Create project structure
    mkdir -p {notebooks,data/{raw,processed},src,tests}

    echo "✅ Data science project '$project_name' created!"
    echo "🚀 Next steps:"
    echo "  source .venv/bin/activate"
    echo "  jupyter lab"
}

# Data science project aliases
alias ds-init='ds_project_init'
alias ds-basic='ds_project_init'
alias ds-spark='ds_project_init'
alias ds-geo='ds_project_init'

# Python projects module loaded indicator
export PYTHON_PROJECTS_LOADED=true