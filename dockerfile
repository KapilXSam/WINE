# FINAL DOCKERFILE FOR RENDER (32-bit Compatibility Mode)
# Base Image: Use the modern, stable, and lightweight Debian 12 "Bookworm"
FROM debian:bookworm-slim

# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------------#
# STAGE 1: SYSTEM SETUP (as root user)
#----------------------------------------------------------------#

# Enable 32-bit architecture, which is the core of this setup
RUN dpkg --add-architecture i386

# Update package lists and install all system prerequisites.
# Added libgl1 to satisfy potential graphics library dependencies.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    xvfb \
    xauth \
    cabextract \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Add the official WineHQ repository key securely
RUN mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

# Add the WineHQ software source for Debian Bookworm
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# Update package lists again, install Wine, and download the Winetricks helper script
RUN apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    # Download Winetricks to a system-wide location and make it executable
    wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    # Clean up apt cache to keep the image small
    rm -rf /var/lib/apt/lists/*

#----------------------------------------------------------------#
# STAGE 2: APPLICATION SETUP (as non-root user)
#----------------------------------------------------------------#

# Create a dedicated, non-privileged user to run the application for security
RUN useradd -m appuser

# Switch to the non-root user. All subsequent commands will run as 'appuser'.
USER appuser

# Set the working directory to the user's home directory
WORKDIR /home/appuser

# Copy your application files from your GitHub repo into the container.
COPY --chown=appuser:appuser your_app/ .

# Set environment variables for the Wine prefix.
# CRITICAL FIX: Force a 32-bit Wine architecture for maximum compatibility.
ENV WINEARCH win32
ENV WINEPREFIX /home/appuser/.wine
ENV WINEDEBUG=-all

# Initialize the 32-bit Wine environment for the user.
RUN xvfb-run --auto-servernum winetricks -q corefonts
RUN xvfb-run --auto-servernum wineboot -u

# Set the final command to execute when the container starts.
# IMPORTANT: Replace 'your_windows_app.exe' with the actual name of your executable.
CMD ["xvfb-run", "--auto-servernum", "wine", "your_windows_app.exe"]
