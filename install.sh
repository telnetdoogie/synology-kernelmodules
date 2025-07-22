#!/bin/sh

# Check for platform ENV variable
if [ -z "$PLATFORM" ]; then
  echo "Error: PLATFORM is not set!"
  echo "Use one of the following platforms:"
  echo
  jq -r 'keys[]' platforms.json
  exit 1
fi

# Check for platforms file
if [ ! -f "platforms.json" ]; then
  echo "Error: platforms.json not found!"
  exit 1
fi

echo "PLATFORM is set to: $PLATFORM"

# read all the values from the platforms file.
export $(jq -r --arg PLATFORM "$PLATFORM" '.[$PLATFORM] | to_entries | map("SYNO_\(.key)=\(.value)") | .[]' platforms.json)

#------------------------------------------------------

echo
echo "Setup toolkit..."
echo
git clone https://github.com/SynologyOpenSource/pkgscripts-ng
cd pkgscripts-ng
git checkout DSM7.2
./EnvDeploy -v 7.2 -p $PLATFORM
cd ..

#------------------------------------------------------

echo
echo "Downloads..."
echo
#download toolkit
echo "Downloading toolchain for $PLATFORM"
toolchain_fn=$(basename "$SYNO_toolchain")
curl --progress-bar -L -o "$toolchain_fn" "$SYNO_toolchain"
toolchain_folder=$(tar -Jtf "${toolchain_fn}" | cut -d/ -f1 | uniq | head -n 1)
echo "Downloaded toolchain: $toolchain_fn"
echo "Archive top-level folder name: $toolchain_folder"

#------------------------------------------------------

echo
echo "Installs..."
echo
# install toolchain
tar -Jxvf ./${toolchain_fn} -C /usr/local/
echo "/usr/local/$toolchain_folder" > /toolchain_folder