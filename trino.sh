#!/bin/bash

# Function to check if Java is installed and its version
check_java_version() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
        echo "Java version detected: $JAVA_VERSION"
    else
        JAVA_VERSION=0
        echo "Java is not installed."
    fi
}

# Install Java 21 if necessary
install_java_21() {
    echo "Installing Java 21..."
    sudo apt update
    sudo apt install -y openjdk-21-jdk
    echo "Java 21 installed."
}

# Set Java 21 as the alternative
set_java_alternative() {
    echo "Setting Java 21 as the default alternative..."
    sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 1
    sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java
}

# Main script logic
check_java_version

if [ "$JAVA_VERSION" -lt 21 ]; then
    install_java_21
    set_java_alternative
fi

# Verify the installed Java version
java -version

# Check if Java version is 21
NEW_JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
if [ "$NEW_JAVA_VERSION" -eq 21 ]; then
    echo "Java 21 is installed and active. Proceeding to next steps..."

    # Add the Helm repo for Trino
    echo "Adding Helm repo for Trino..."
    helm repo add trino https://trinodb.github.io/charts

    # Install Trino cluster
    echo "Installing Trino cluster..."
    helm install trino-cluster trino/trino

    # Port-forward Trino service
    echo "Port-forwarding Trino service..."
    kubectl port-forward svc/trino-cluster-trino 8080:8080 &
    PORT_FORWARD_PID=$!

    # Wait for port-forwarding to stabilize
    sleep 20

    # Download the Trino CLI jar
    echo "Downloading Trino CLI jar..."
    wget https://repo1.maven.org/maven2/io/trino/trino-cli/470/trino-cli-470-executable.jar -O trino

    # Make the jar executable
    chmod +x trino

    # Print Trino CLI version
    echo "Trino CLI version:"
    ./trino --version

    # Kill the port-forwarding process
    kill $PORT_FORWARD_PID
else
    echo "Failed to set Java 21 as the default version."
    exit 1
fi

