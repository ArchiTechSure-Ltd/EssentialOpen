#!/bin/bash
set -e


# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------

IMPORT_CONFIG="/usr/local/tomcat/webapps/essential_import_utility/config"
DEFAULT_IMPORT_CONFIG="/opt/essential-import-defaults"

VIEWER_WEBAPP="/usr/local/tomcat/webapps/essential_viewer"
DEFAULT_VIEWER="/opt/essential-viewer-defaults"

REPOSITORY_CACHE="/usr/local/tomcat/webapps/essential_import_utility/repository_cache"
DEFAULT_REPOSITORY="/opt/essential-repository-defaults/source"


# -------------------------------------------------------------------
# Essential Import Utility configuration
# -------------------------------------------------------------------

echo "Initialising Essential Import Utility configuration..."

mkdir -p "${IMPORT_CONFIG}"

# Populate any files supplied by the Import Utility that do not
# already exist in persistent storage.
#
# Existing instance configuration is never overwritten.
cp -an \
    "${DEFAULT_IMPORT_CONFIG}/." \
    "${IMPORT_CONFIG}/"

echo "Import Utility configuration files:"

find "${IMPORT_CONFIG}" \
    -maxdepth 1 \
    -type f \
    -printf '  %f\n' \
    | sort

echo "Essential Import Utility configuration ready."


# -------------------------------------------------------------------
# Essential Viewer
# -------------------------------------------------------------------

echo "Initialising Essential Viewer..."

mkdir -p "${VIEWER_WEBAPP}"

if [ ! -f "${VIEWER_WEBAPP}/WEB-INF/web.xml" ]; then

    echo "Seeding Viewer from image defaults..."

    cp -a \
        "${DEFAULT_VIEWER}/." \
        "${VIEWER_WEBAPP}/"

else

    echo "Using existing persistent Viewer"

fi

echo "Essential Viewer ready."


# -------------------------------------------------------------------
# Essential repositories
# -------------------------------------------------------------------

echo "Initialising Essential repositories..."

mkdir -p "${REPOSITORY_CACHE}"

seed_repository() {

    REPOSITORY_NAME="$1"
    TARGET="${REPOSITORY_CACHE}/${REPOSITORY_NAME}"

    mkdir -p "${TARGET}"

    if ! find "${TARGET}" -maxdepth 1 -name '*.pprj' | grep -q .; then

        echo "Seeding ${REPOSITORY_NAME} from clean Essential baseline..."

        cp -a \
            "${DEFAULT_REPOSITORY}/." \
            "${TARGET}/"

    else

        echo "Using existing ${REPOSITORY_NAME}"

    fi
}

seed_repository "repository_live"
seed_repository "repository_qa"

echo "Essential repositories ready."


# -------------------------------------------------------------------
# SSH
# -------------------------------------------------------------------

echo "Starting SSH..."

mkdir -p /var/run/sshd
/usr/sbin/sshd


# -------------------------------------------------------------------
# Tomcat
# -------------------------------------------------------------------

echo "Starting Tomcat..."

exec catalina.sh run