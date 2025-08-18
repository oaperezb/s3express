# Build stage
FROM public.ecr.aws/amazonlinux/amazonlinux:latest AS builder

# Install required packages for building
RUN dnf -y install --allowerasing \
    unzip \
    curl \
    util-linux \
    procps-ng \
    fuse \
    fuse-libs \
    && dnf clean all

# Install mountpoint-s3
RUN dnf -y install https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm

# Install AWS CLI using package manager
RUN dnf -y install awscli && dnf clean all

# Runtime stage
FROM public.ecr.aws/amazonlinux/amazonlinux:latest AS runtime

# Install only runtime dependencies
RUN dnf -y install --allowerasing \
    util-linux \
    procps-ng \
    fuse \
    fuse-libs \
    python3 \
    python3-pip \
    awscli \
    && dnf clean all

# Copy mountpoint-s3 from builder stage
COPY --from=builder /usr/bin/mount-s3 /usr/bin/mount-s3



# Create mount directory
RUN mkdir -p /mnt/s3express

# Copy the startup script
COPY start-s3express.sh /usr/local/bin/start-s3express.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start-s3express.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/start-s3express.sh"]
