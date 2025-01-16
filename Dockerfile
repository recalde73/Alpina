FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias esenciales
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
RUN mkdir /sdk
WORKDIR /sdk
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O commandlinetools.zip \
    && unzip commandlinetools.zip -d /sdk/cmdline-tools \
    && rm commandlinetools.zip

RUN mkdir -p /sdk/cmdline-tools/latest && \
    unzip commandlinetools.zip -d /sdk/cmdline-tools/latest && \
    mv /sdk/cmdline-tools/latest/cmdline-tools/* /sdk/cmdline-tools/latest/ && \
    rm -rf /sdk/cmdline-tools/latest/cmdline-tools




ENV ANDROID_HOME=/sdk
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Aceptar todas las licencias del SDK
# RUN yes | /sdk/cmdline-tools/latest/bin/sdkmanager --licenses

# Instalar el NDK requerido
# RUN /sdk/cmdline-tools/latest/bin/sdkmanager "ndk;26.3.11579264"

# Instalar Gradle
RUN wget https://services.gradle.org/distributions/gradle-7.6-bin.zip -O gradle.zip \
    && unzip gradle.zip -d /opt/gradle \
    && rm gradle.zip
ENV PATH="/opt/gradle/gradle-7.6/bin:$PATH"

# Instalar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
ENV FLUTTER_SUPPRESS_ANALYTICS=true

# Configurar Flutter y generar el archivo `engine.version`
RUN flutter doctor

# Establecer el directorio de trabajo para el proyecto Android
WORKDIR /app

# Copiar únicamente la carpeta 'android'
COPY ./android /app

# Dar permisos de ejecución al archivo gradlew
RUN chmod +x /app/gradlew

# Construir la aplicación
CMD ["./gradlew", "assembleDebug"]
