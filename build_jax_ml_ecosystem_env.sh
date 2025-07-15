#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <input_jax_lockfile_url> <output_file_name>"
    exit 1
fi

# Assign arguments to descriptive variables based on your request
input_jax_lockfile="$1"
output_file_name="$2"
python_version="$3"

SEED_LOCK_FILE=$(basename "$input_jax_lockfile")

cat <<EOF > pyproject.toml
[project]
name = "jax_ml_ecosystem"
version = "0.1.0"
requires-python = "==${python_version}.*"
dependencies = [
]
EOF

curl -L --fail "$input_jax_lockfile" -o "$SEED_LOCK_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the seed lock file. Please check the URL."
    exit 1
fi

uv add --python ${python_version} --no-build --no-sync --resolution=highest -r "$SEED_LOCK_FILE"

uv add --python ${python_version} --no-sync --resolution=highest -r requirements.txt

uv export --python ${python_version} --locked --no-hashes --no-annotate --resolution=highest --output-file="$output_file_name"

python3 lock_to_lower_bound_project.py "$output_file_name" pyproject.toml

rm uv.lock

sed -i 's/^requires-python = .*/requires-python = ">=3.11, <4.0"/' pyproject.toml