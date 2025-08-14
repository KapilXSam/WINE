# Use a modern, stable, and lightweight base image (Debian 12 "Bookworm")
FROM debian:bookworm-slim

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture, which is required by Wine (CORRECTED)
RUN dpkg --add-architecture i386

# Update package lists and install prerequisite packages,
# including xvfb and its dependency xauth.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    xvfb \
    xauth \
    && rm -rf /var/lib/apt/lists/*

# Download the official WineHQ repository key and add it securely
RUN mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

# Add the official WineHQ repository for Debian Bookworm
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# Update package lists again to include the new repository and install Wine
RUN apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    # Clean up apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN useradd -m appuser
USER appuser

# Set the working directory
WORKDIR /home/appuser

# Copy your application files into the container
# Make sure you have a folder named 'your_app' in your repo,
# or change the name here to match your folder.
COPY --chown=appuser:appuser your_app/ .

# Set up a clean Wine environment
ENV WINEPREFIX /home/appuser/.wine
ENV WINEARCH win64
# Suppress some of the graphics-related error messages
ENV WINEDEBUG=-all

# Initialize the Wine prefix (this will run the first time the container starts)
# We run this inside xvfb-run as well, as some installers show a GUI
RUN xvfb-run --auto-servernum wineboot -u

# The command to run your application inside the virtual display
# Replace 'your_windows_app.exe' with the actual name of your executable
CMD ["xvfb-run", "--auto-servernum", "wine", "your_windows_app.exe"]
