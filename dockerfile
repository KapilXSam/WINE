# Use a modern, stable, and lightweight base image (Debian 12 "Bookworm")
FROM debian:bookworm-slim

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture, which is required by Wine
RUN dpkg --add-architecture i386

# Update package lists and install prerequisite packages,
# including xvfb for a virtual display.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    xvfb \
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

# --- The rest of your Dockerfile remains the same ---

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
CMD ["xvfb-run", "--auto-servernum", "wine", "your_windows_app.exe"]```

### **Summary of Changes**

1.  **Install `xvfb`**: In the first `apt-get install` command, we've added `xvfb` to the list of packages to be installed.
2.  **Suppress Wine Debug Messages**: The line `ENV WINEDEBUG=-all` is added to hide the numerous `fixme:` and `err:` messages from Wine that aren't critical to your app's function, cleaning up your logs.
3.  **Initialize Wine with `xvfb-run`**: We now run `wineboot -u` inside `xvfb-run` to prevent any potential GUI pop-ups during initialization from causing an error.
4.  **Modified `CMD`**: The final command is now wrapped with `xvfb-run --auto-servernum`. This tells the container to start a virtual display server with an automatic server number and then run your `wine your_windows_app.exe` command within it.

### **Next Steps**

1.  **Replace** the code in your `Dockerfile` with the new version above.
2.  **Commit and push** the changes to your GitHub repository.
3.  Render will start a new build. This time, your application should launch successfully without the display driver errors.
