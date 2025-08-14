# Use a modern, stable, and lightweight base image (Debian 12 "Bookworm")
FROM debian:bookworm-slim

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture, which is required by Wine
RUN dpkg --add-architecture i386

# Update package lists and install prerequisite packages.
# Added cabextract for winetricks.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    xvfb \
    xauth \
    cabextract \
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
ENV WINEDEBUG=-all

# --- NEW ROBUST INITIALIZATION ---
# 1. Download winetricks, a helper script for Wine
RUN wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

# 2. Force creation of the Wine prefix and install core fonts silently
#    The '-q' flag is for quiet/unattended installation.
RUN xvfb-run --auto-servernum winetricks -q corefonts

# 3. Explicitly update the prefix to ensure it's properly configured
RUN xvfb-run --auto-servernum wineboot -u

# The command to run your application inside the virtual display
# Replace 'your_windows_app.exe' with the actual name of your executable
CMD ["xvfb-run", "--auto-servernum", "wine", "your_windows_app.exe"]
