#!/bin/bash
##################################################################
# versions.sh
# Generate a csv files with alpine-friendly versions
# for RUBY_VERSION and NODE_VERSION, for every released of decidim.
#
# ```
# DOCKERHUB_PERSONAL_TOKEN=<token> version.sh 1>&2
# ```
# Where `DOCKERHUB_PERSONAL_TOKEN` is a dockerhub token to 
# increase access limits.
#
# Requirement
# 
# Output
# ===
# A csv file with: 
# decidim version | decidim major version (ex. 24) | decidim minor version (ex. 3) | node version | ruby version
# 
# Example:
#
# 
# FIXME: this script should run in a github action.
##################################################################
set -e
echo "Running version.sh"
echo "" > ./node_versions.txt
echo "" > ./versions.csv

gemfiles=$(gem list decidim-generators --remote --all --no-details | grep -o -E '[0-9\.0-9\.0-9]+')
major_version=""
minor_version=""
node_versions=()
decidim_versions=()
i=1

# Get all the alpine node images.
echo -n "Retrieve alpine nodes"
until [ $i -gt 30 ]; do
	node_versions+=$(curl --silent \
			-H 'Accept: application/json' \
			-H "Authorization: Bearer $DOCKERHUB_PERSONAL_TOKEN" \
									-H 'Content-Type: application/json' \
			"https://hub.docker.com/v2/repositories/library/node/tags?page=$i&page_size=100" | jq ".results[].name")
  echo -n "."
	((i=i+1))
done
echo ""
echo "$node_versions" | grep alpine > node_versions.txt

# Foreach decidim version, grap the required node and ruby version
# We consider only the last available minor version (0.24.2 will be discarded)
echo -n "Link Decidim to a (ruby, node) version"
for generator_version in $gemfiles; do
	new_major_version=$(echo "$generator_version" | cut -d'.' -f 1)
	new_minor_version=$(echo "$generator_version" | cut -d'.' -f 2)
	if [ "${major_version}" != "${new_major_version}" ] || [ "${minor_version}" != "${new_minor_version}" ]; then
		decidim_node=$(curl --silent -f -lSL "https://raw.githubusercontent.com/decidim/decidim/release/${new_major_version}.${new_minor_version}-stable/package.json" | jq '.engines.node' | grep -o -E '[0-9\.0-9\.0-9]+')
		ruby_version=$(curl --silent -f -lSL "https://raw.githubusercontent.com/decidim/decidim/release/$new_major_version.$new_minor_version-stable/.ruby-version")
		if n=$(grep -wic "$decidim_node-alpine" node_versions.txt); then
			decidim_versions+="${generator_version};${new_major_version};${new_minor_version};${decidim_node};${ruby_version}\n"
		fi
		major_version="$new_major_version"
		minor_version="$new_minor_version"
    echo -n "."
	fi
done 
echo -e $decidim_versions > versions.csv;
rm node_versions.txt;

echo -e "\ndone! Happy CI/CD :)"
echo -e "\ndecidim version;decidim major version (ex. 24);decidim minor version (ex. 3);node version;ruby version"
cat versions.csv