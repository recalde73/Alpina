FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar paquetes necesarios
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip \
    git \
    curl

# Instalar Java 17
RUN apt-get update && apt-get install -y openjdk-17-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Instalar Android SDK
RUN mkdir -p /sdk
WORKDIR /sdk

# Descargar y configurar Android Command Line Tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip commandlinetools-linux-9477386_latest.zip \
    && mkdir -p cmdline-tools/latest \
    && mv cmdline-tools/* cmdline-tools/latest/ || true \
    && rm -f commandlinetools-linux-9477386_latest.zip

ENV ANDROID_HOME=/sdk
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Aceptar licencias
RUN yes | sdkmanager --licenses || true

# Instalar paquetes SDK necesarios
RUN sdkmanager "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# Instalar NDK
RUN sdkmanager "ndk;26.3.11579264"

# Instalar Gradle
RUN wget https://services.gradle.org/distributions/gradle-7.6-bin.zip \
    && unzip gradle-7.6-bin.zip -d /opt/gradle \
    && rm gradle-7.6-bin.zip
ENV PATH="/opt/gradle/gradle-7.6/bin:$PATH"

# Instalar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
ENV FLUTTER_SUPPRESS_ANALYTICS=true

# Configurar Flutter
RUN flutter doctor

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY ./android /app

# Permisos gradlew
RUN chmod +x /app/gradlew

# Comando por defecto
CMD ["./gradlew", "assembleDebug"]