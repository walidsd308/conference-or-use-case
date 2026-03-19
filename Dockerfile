# Use texlive as base image with LaTeX tools pre-installed
FROM texlive/texlive:latest

# Set working directory inside container
WORKDIR /project

# Ensure latexmk is available
RUN apt-get update && \
    apt-get install -y --no-install-recommends latexmk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Note: Project files are mounted as volumes via docker run -v, not copied
# This allows instant reflection of local file changes without rebuilding
