#!/bin/bash

set -eo

# Update Github Config.
git config --global user.email "githubactionbot+wp@gmail.com" && git config --global user.name "WP Plugin Assets Updater"

WORDPRESS_USERNAME="$INPUT_WORDPRESS_USERNAME"
WORDPRESS_PASSWORD="$INPUT_WORDPRESS_PASSWORD"
SLUG="$INPUT_SLUG"
ASSETS_DIR="$INPUT_ASSETS_DIR"
IGNORE_FILE="$INPUT_IGNORE_FILE"
ASSETS_IGNORE_FILE="$INPUT_ASSETS_IGNORE_FILE"


# Ensure SVN username and password are set
# IMPORTANT: secrets are accessible by anyone with write access to the repository!
if [[ -z "$WORDPRESS_USERNAME" ]]; then
    echo "Set the WORDPRESS_USERNAME secret"
    exit 1
fi

if [[ -z "$WORDPRESS_PASSWORD" ]]; then
    echo "Set the WORDPRESS_PASSWORD secret"
    exit 1
fi

# Allow some ENV variables to be customized
if [[ -z "$SLUG" ]]; then
    SLUG=${GITHUB_REPOSITORY#*/}
fi

if [[ -z "$ASSETS_DIR" ]]; then
	ASSETS_DIR=".wordpress-org"
fi

if [[ -z "$IGNORE_FILE" ]]; then
	IGNORE_FILE=".wporgignore"
fi

if [[ -z "$ASSETS_IGNORE_FILE" ]]; then
	ASSETS_IGNORE_FILE=".wporgassetsignore"
fi

echo '----------------'
# Echo Plugin Slug
echo "ℹ︎ SLUG is $SLUG"
# Echo Assets DIR
echo "ℹ︎ ASSETS_DIR is $ASSETS_DIR"
echo '----------------'

SVN_URL="http://plugins.svn.wordpress.org/${SLUG}/"
SVN_DIR="/github/svn-${SLUG}"

# Checkout just trunk and assets for efficiency
# Tagging will be handled on the SVN level
echo "➤ Checking out .org repository..."
svn checkout --depth immediates "$SVN_URL" "$SVN_DIR"
cd "$SVN_DIR"
svn update --set-depth infinity assets
svn update --set-depth infinity trunk


echo "➤ Copying files..."
cd "$GITHUB_WORKSPACE"

# "Export" a cleaned copy to a temp directory
TMP_DIR="/github/archivetmp"
ASSET_TMP_DIR="/github/assettmp"
mkdir "$TMP_DIR"
mkdir "$ASSET_TMP_DIR"

echo ".git .github .gitignore .gitattributes ${ASSETS_DIR} ${IGNORE_FILE} ${ASSETS_IGNORE_FILE} node_modules" | tr " " "\n" >> "$GITHUB_WORKSPACE/$IGNORE_FILE"
echo "*.psd .DS_Store Thumbs.db ehthumbs.db ehthumbs_vista.db .git .github .gitignore .gitattributes ${ASSETS_DIR} ${IGNORE_FILE} ${ASSETS_IGNORE_FILE} node_modules" | tr " " "\n" >> "$GITHUB_WORKSPACE/$ASSETS_IGNORE_FILE"

#cat "$GITHUB_WORKSPACE/$IGNORE_FILE"

# If there's no .gitattributes file, write a default one into place
if [[ ! -e "$GITHUB_WORKSPACE/$IGNORE_FILE" ]]; then
	# Ensure we are in the $GITHUB_WORKSPACE directory, just in case
	# The .gitattributes file has to be committed to be used
	# Just don't push it to the origin repo :)
	git add "$IGNORE_FILE" && git commit -m "Add $IGNORE_FILE file"
fi
# If there's no .gitattributes file, write a default one into place
if [[ ! -e "$GITHUB_WORKSPACE/$ASSETS_IGNORE_FILE" ]]; then
	# Ensure we are in the $GITHUB_WORKSPACE directory, just in case
	# The .gitattributes file has to be committed to be used
	# Just don't push it to the origin repo :)
	git add "$ASSETS_IGNORE_FILE" && git commit -m "Add $ASSETS_IGNORE_FILE file"
fi

# This will exclude everything in the $IGNORE_FILE file
echo "➤ Removing Exlucded Files From Plugin Source"
rsync -r --delete --exclude-from="$GITHUB_WORKSPACE/$IGNORE_FILE" "./" "$TMP_DIR"

# This will exclude everything in the $ASSETS_IGNORE_FILE file
cd "$ASSETS_DIR"
echo "➤ Removing Exlucded Files From Assets Folder"
rsync -r --delete --exclude-from="$GITHUB_WORKSPACE/$ASSETS_IGNORE_FILE" "./" "$ASSET_TMP_DIR"

cd "$SVN_DIR"

# Copy from clean copy to /trunk, excluding dotorg assets
rsync -c "$TMP_DIR/readme.txt" "trunk/"

# Copy dotorg assets to /assets
rsync -rc "$ASSET_TMP_DIR/" assets/ --delete

# Add everything and commit to SVN
# The force flag ensures we recurse into subdirectories even if they are already added
# Suppress stdout in favor of svn status later for readability
echo "➤ Preparing files..."

svn status

if [[ -z $(svn stat) ]]; then
	echo "🛑 Nothing to deploy!"
	exit 0
fi

# Readme also has to be updated in the .org tag
echo "➤ Preparing stable tag..."
STABLE_TAG=$(grep -m 1 "^Stable tag:" "$TMP_DIR/readme.txt" | tr -d '\r\n' | awk -F ' ' '{print $NF}')

if [ -z "$STABLE_TAG" ]; then
    echo "ℹ︎ Could not get stable tag from readme.txt";
	HAS_STABLE=1
else
	echo "ℹ︎ STABLE_TAG is $STABLE_TAG"

	if svn info "^/$SLUG/tags/$STABLE_TAG" > /dev/null 2>&1; then
		svn update --set-depth infinity "tags/$STABLE_TAG"

		# Not doing the copying in SVN for the sake of easy history
		rsync -c "$TMP_DIR/readme.txt" "tags/$STABLE_TAG/"
	else
		echo "ℹ︎ Tag $STABLE_TAG not found"
	fi
fi

# Add everything and commit to SVN
# The force flag ensures we recurse into subdirectories even if they are already added
# Suppress stdout in favor of svn status later for readability
svn add . --force > /dev/null

# SVN delete all deleted files
# Also suppress stdout here
svn status | grep '^\!' | sed 's/! *//' | xargs -I% svn rm % > /dev/null

# Now show full SVN status
svn status

echo "➤ Committing files..."
svn commit -m "Updating readme/assets from GitHub" --no-auth-cache --non-interactive  --username "$WORDPRESS_USERNAME" --password "$WORDPRESS_PASSWORD"

echo "✓ Plugin deployed!"