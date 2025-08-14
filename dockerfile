# Use a stable and lightweight base image
FROM debian:buster-slim

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages, including wine
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gpg-agent \
    dirmngr \
    && \
    # Add the WineHQ repository key
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 76F1A20FF987672F && \
    # Add the WineHQ repository
    apt-add-repository 'deb https://dl.winehq.org/wine-builds/debian/ buster main' && \
    # Update package lists again and install wine-stable
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    # Clean up apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN useradd -m appuser
USER appuser

# Set the working directory
WORKDIR /home/appuser

# Copy your application files into the container
COPY --chown=appuser:appuser your_app/ .

# Set up a clean Wine environment
ENV WINEPREFIX /home/appuser/.wine
ENV WINEARCH win64

# Initialize the Wine prefix (this will run the first time the container starts)
RUN wineboot -u

# The command to run your application
# Replace 'your_windows_app.exe' with the actual name of your executable
CMD ["wine", "your_windows_app.exe"]