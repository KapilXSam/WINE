# FINAL DOCKERFILE FOR RENDER (Robust 64-bit Mode)
# Base Image: Use the modern, stable, and lightweight Debian 12 "Bookworm"
FROM debian:bookworm-slim

# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------------#
# STAGE 1: SYSTEM SETUP (as root user)
#----------------------------------------------------------------#

# Enable 32-bit architecture, as 64-bit Wine still needs 32-bit libraries
RUN dpkg --add-architecture i386

# Update package lists and install all system prerequisites.
# This is an expanded list to ensure both 64-bit (amd64) and 32-bit (i386)
# versions of critical libraries are present.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    xvfb \
    xauth \
    cabextract \
    # Explicitly install critical C runtime and graphics libraries for both architectures
    libc6:amd64 \
    libc6:i386 \
    libgl1:amd64 \
    libgl1:i386 \
    libx11-6:amd64 \
    libx11-6:i386 \
    && rm -rf /var/lib/apt/lists/*

# Add the official WineHQ repository key securely
RUN mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

# Add the WineHQ software source for Debian Bookworm
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# Update package lists again, install Wine, and download the Winetricks helper script
RUN apt-get update && \
    # Explicitly install wine64 and wine32 packages to ensure all components are present
    apt-get install -y --install-recommends winehq-stable wine64 wine32 && \
    wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    rm -rf /var/lib/apt/lists/*

#----------------------------------------------------------------#
# STAGE 2: APPLICATION SETUP (as non-root user)
#----------------------------------------------------------------#

# Create a dedicated, non-privileged user to run the application
RUN useradd -m appuser

# Switch to the non-root user
USER appuser

# Set the working directory to the user's home directory
WORKDIR /home/appuser

# Copy your application files into the container
COPY --chown=appuser:appuser your_app/ .

# Set environment variables for the Wine prefix, correctly targeting 64-bit.
ENV WINEARCH win64
ENV WINEPREFIX /home/appuser/.wine
ENV WINEDEBUG=-all

# Initialize the 64-bit Wine environment for the user.
RUN xvfb-run --auto-servernum winetricks -q corefonts
RUN xvfb-run --auto-servernum wineboot -u

# Set the final command to execute when the container starts.
# IMPORTANT: Replace 'your_windows_app.exe' with the actual name of your executable.
CMD ["xvfb-run", "--auto-servernum", "wine", "your_windows_app.exe"]
